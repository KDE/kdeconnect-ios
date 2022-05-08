/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020-2021 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//Copyright 27/4/14  YANG Qiao yangqiao0505@me.com
//kdeconnect is distributed under two licenses.
//
//* The Mozilla Public License (MPL) v2.0
//
//or
//
//* The General Public License (GPL) v2.1
//
//----------------------------------------------------------------------
//
//Software distributed under these licenses is distributed on an "AS
//IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
//implied. See the License for the specific language governing rights
//and limitations under the License.
//kdeconnect is distributed under both the GPL and the MPL. The MPL
//notice, reproduced below, covers the use of either of the licenses.
//
//----------------------------------------------------------------------

#import "LanLink.h"
#import "KDE_Connect-Swift.h"

#define PAYLOAD_PORT 1739
#define PAYLOAD_SEND_DELAY 0 //ns

@interface LanLink()
{
    uint16_t _payloadPort;
    dispatch_queue_t _socketQueue;
}

@property(nonatomic) GCDAsyncSocket* _socket;
@property(nonatomic) NetworkPackage* _pendingPairNP;
@property(nonatomic) NSMutableArray* _pendingRSockets;
@property(nonatomic) NSMutableArray* _pendingLSockets;
@property(nonatomic) NSMutableArray* _pendingPayloadNP;
@property(nonatomic) NSMutableArray* _pendingPayloads;
@property(nonatomic) SecIdentityRef _identity;
@property(nonatomic) GCDAsyncSocket* _fileServerSocket;
@property(nonatomic,assign) CertificateService* _certificateService;

@end

@implementation LanLink

@synthesize _deviceId;
@synthesize _linkDelegate;
@synthesize _pendingLSockets;
@synthesize _pendingPairNP;
@synthesize _pendingPayloadNP;
@synthesize _pendingPayloads;
@synthesize _pendingRSockets;
@synthesize _socket;
@synthesize _identity;
@synthesize _fileServerSocket;
@synthesize _certificateService;

- (LanLink*) init:(GCDAsyncSocket*)socket deviceId:(NSString*) deviceid setDelegate:(id)linkdelegate certificateService:(CertificateService*)certificateService
{
    if ([super init:deviceid setDelegate:linkdelegate])
    {
        _socket=socket;
        _deviceId=deviceid;
        _linkDelegate=linkdelegate;
        _pendingPairNP=nil;
        [_socket setDelegate:self];
        [_socket performBlock:^{
            [_socket enableBackgroundingOnSocket];
        }];
        NSLog(@"LanLink:lanlink for device:%@ created",_deviceId);
        [_socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:PACKAGE_TAG_NORMAL];
        _pendingRSockets=[NSMutableArray arrayWithCapacity:1];
        _pendingLSockets=[NSMutableArray arrayWithCapacity:1];
        _pendingPayloadNP=[NSMutableArray arrayWithCapacity:1];
        _pendingPayloads=[NSMutableArray arrayWithCapacity:1];
        _payloadPort=PAYLOAD_PORT;
        _socketQueue=dispatch_queue_create("com.kde.org.kdeconnect.payload_socketQueue", NULL);
    
        _certificateService = certificateService;
        [self loadSecIdentity];
    }
    return self;
}

- (void) loadSecIdentity
{
    SecIdentityRef identityApp = [_certificateService hostIdentity];
    assert(identityApp != nil);

    // Validate private key
    SecKeyRef privateKeyRef = NULL;
    OSStatus status = SecIdentityCopyPrivateKey(identityApp, &privateKeyRef);
    if (status != noErr) {
        // Fail to retrieve private key from the .p12 file
        NSLog(@"Certificate loading failed");
    } else {
        _identity = identityApp;
        NSLog(@"Certificate loaded successfully");
    }
    CFRelease(privateKeyRef);
    // The ownership of SecIdentityRef is in CertificateService
}

- (BOOL) sendPackage:(NetworkPackage *)np tag:(long)tag
{
    NSLog(@"llink send package");
    if (![_socket isConnected]) {
        NSLog(@"LanLink: Device:%@ disconnected",_deviceId);
        return false;
    }
    
    // If sharing file, start file sharing procedure
    if ([np _Payload] != nil && tag == PACKAGE_TAG_SHARE) {
        NSError* err;
        if (_fileServerSocket == nil) {
            _fileServerSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
            if (![_fileServerSocket isConnected]) {
                if (![_fileServerSocket acceptOnPort:_payloadPort error:&err]) {
                    NSLog(@"Error binding payload port");
                } else {
                    NSLog(@"Binding payload server ok");
                }
            }
        }
        [_pendingPayloadNP insertObject:np atIndex:0];
        [_pendingPayloads insertObject: [np _Payload] atIndex:0];
    }
    
    NSData* data=[np serialize];
    [_socket writeData:data withTimeout:-1 tag:tag];
    //TODO: return true only when send successfully
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return true;
}

- (void) disconnect
{
    if ([_socket isConnected]) {
        [_socket disconnect];
    }
    if (_linkDelegate) {
        [_linkDelegate onLinkDestroyed:self];
    }
    _pendingPairNP=nil;
    NSLog(@"LanLink: Device:%@ disconnected",_deviceId);
}

#pragma mark TCP delegate
/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"Lanlink: didAcceptNewSocket");

    /* TLS Connection */
    NSArray *myCerts = [[NSArray alloc] initWithObjects:(__bridge id)_identity, /*(__bridge id)cert2UseRef,*/ nil];
    NSArray *myCipherSuite = [[NSArray alloc] initWithObjects:
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256],
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384],
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA],
                              nil];

    NSDictionary *tlsSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
         (id)[NSNumber numberWithInt:1],    (id)kCFStreamSSLIsServer,
         (__bridge CFArrayRef) myCerts, (id)kCFStreamSSLCertificates,
         (__bridge CFArrayRef) myCipherSuite, (id)GCDAsyncSocketSSLCipherSuites,
    nil];

    [newSocket startTLS: tlsSettings];
    [_pendingLSockets insertObject:newSocket atIndex:0];
    NSLog(@"Start Server TLS to send file");
}


/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Lanlink did connect to payload host, begin recieving data from %@ %d", host, port);

    /* TLS Connection */
    NSArray *myCerts = [[NSArray alloc] initWithObjects:(__bridge id)_identity, /*(__bridge id)cert2UseRef,*/ nil];
    NSArray *myCipherSuite = [[NSArray alloc] initWithObjects:
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256],
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384],
                              [[NSNumber alloc] initWithInt: TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA],
                              nil];

    NSDictionary *tlsSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
         (id)[NSNumber numberWithInt:0],    (id)kCFStreamSSLIsServer,
         (id)[NSNumber numberWithInt:1],    (id)GCDAsyncSocketManuallyEvaluateTrust,
         (__bridge CFArrayRef) myCerts, (id)kCFStreamSSLCertificates,
         (__bridge CFArrayRef) myCipherSuite, (id)GCDAsyncSocketSSLCipherSuites,
    nil];

    //NSLog(@"%@", myCerts);
    [sock startTLS: tlsSettings];
    NSLog(@"Start Client TLS to receive file");
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // If the data received has a payload tag (indicating that it is a payload, e.g file trasnferred
    // from the Share plugin, prepare a NetworkPackage with the payload in it and give it to the
    // Plugins to handle it
    NSLog(@"Package received with tag: %ld", tag);
    if (tag==PACKAGE_TAG_PAYLOAD) {
        [self attachAndProcessPayload:sock :data];
        return;
    }
    NSLog(@"llink did read data");
    //BUG even if we read with a seperator LFData , it's still possible to receive several data package together. So we split the string and retrieve the package
    [_socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:PACKAGE_TAG_NORMAL];
    NSString * jsonStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received: %@", jsonStr);
    [self readThroughLatestPackets:sock :jsonStr];
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"llink didWriteData");
    if (_linkDelegate) {
        [_linkDelegate onSendSuccess:tag];
    }// pass this to device also so device can notify Share plugin when a payload finishes sending?
//    if (tag==PACKAGE_TAG_PAYLOAD) {
//        NSLog(@"llink payload sendpk");
//    }
}

/**
 * Called if a read operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the read's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the read will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been read so far for the read operation.
 *
 * Note that this method may be called multiple times for a single read if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    return 0;
}

/**
 * Called if a write operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the write's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the write will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been written so far for the write operation.
 *
 * Note that this method may be called multiple times for a single write if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    return 0;
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * then an invocation of this delegate method will be enqueued on the _socketQueue
 * before the disconnect method returns.
 *
 * Note: If the GCDAsyncSocket instance is deallocated while it is still connected,
 * and the delegate is not also deallocated, then this method will be invoked,
 * but the sock parameter will be nil. (It must necessarily be nil since it is no longer available.)
 * This is a generally rare, but is possible if one writes code like this:
 *
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * In this case it may preferrable to nil the delegate beforehand, like this:
 *
 * asyncSocket.delegate = nil; // Don't invoke my delegate method
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * Of course, this depends on how your state machine is configured.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ([_pendingRSockets containsObject:sock]) {
        NSLog(@"llink payload socket disconnected with error: %@", err);
        @synchronized(_pendingRSockets){
            NSUInteger index=[_pendingRSockets indexOfObject:sock];
            [_pendingRSockets removeObjectAtIndex:index];
            [_pendingPayloadNP removeObjectAtIndex:index];
        }
    }
    if (_linkDelegate&&(sock==_socket)) {
        NSLog(@"llink socket did disconnect with error: %@", err);
        [_linkDelegate onLinkDestroyed:self];
    }
    
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"Connection is secure");
    
    @synchronized(_pendingLSockets){
        if ([_pendingLSockets count] > 0) {
            // I'm the server
            [self sendPayloadWithSocket: sock];
        }
    }

    @synchronized (_pendingRSockets) {
        if ([_pendingRSockets count] > 0) {
            // I'm the client
            [self receivePayloadWithSocket: sock];
        }
    }
}

// This gets called when a saved device comes back online, AND when initially pairing
// So we need to deal with 2 possibilities here:

// TODO: when shouldTrustPeer gets called, there are 2 possibilities:
// 1. If device is new/never been paired before, just trust it
// 2. If device's been paired before, check for the already stored certificate to check whether
// its signature matches that of the device trying to connect

// Remember, this is LanLink, so _deviceId is the id of the REMOTE device, we can use this to perform look-ups!!!!!

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    if ([_certificateService verifyCertificateEqualityFromRemoteDeviceWithDeviceIDWithTrust:trust deviceId:_deviceId]) {
        NSLog(@"LanLink's didReceiveTrust received Certificate from %@, trusting", [sock connectedHost]);
        completionHandler(YES);
    } else {
        completionHandler(NO);
    }
}

- (void)sendPayloadWithSocket:(GCDAsyncSocket *)sock
{
    //NSMutableArray* payloadArray;
    NSUInteger index=[_pendingLSockets indexOfObject:sock];
    // payloadArray=[_pendingPayloads objectAtIndex:index];
    dispatch_time_t t = dispatch_time(DISPATCH_TIME_NOW,0);
    NSData* chunk=[_pendingPayloads objectAtIndex:index];
    /*if (!payloadArray|!chunk) {
        @synchronized(_pendingLSockets){
            NSUInteger index=[_pendingLSockets indexOfObject:sock];
            payloadArray=[_pendingPayloads objectAtIndex:index];
            [_pendingLSockets removeObject:sock];
            [_pendingPayloads removeObjectAtIndex:index];
        }
        return;
    }*/
    //TO-DO send the data chunk one by one in order to get the proccess percentage
    t=dispatch_time(t, PAYLOAD_SEND_DELAY*NSEC_PER_MSEC);
    dispatch_after(t,_socketQueue, ^(void){
        //[newSocket writeData:chunk withTimeout:-1 tag:PACKAGE_TAG_PAYLOAD];
        [sock writeData:chunk withTimeout:-1 tag:PACKAGE_TAG_PAYLOAD];
        [sock disconnectAfterWriting];
    });
}

- (void)receivePayloadWithSocket:(GCDAsyncSocket *)sock
{
    @synchronized(_pendingRSockets){
        NSUInteger index=[_pendingRSockets indexOfObject:sock];
        NSLog(@"Reading from socket %@ %ld bytes", _pendingRSockets, [[_pendingPayloadNP objectAtIndex:index] _PayloadSize]);
        [sock readDataToLength: [[_pendingPayloadNP objectAtIndex:index] _PayloadSize] withTimeout:-1 tag:PACKAGE_TAG_PAYLOAD];
    }
}

- (void)dealloc {
    NSLog(@"Lan Link destroyed");
}

- (void)attachAndProcessPayload:(GCDAsyncSocket *)sock : (NSData *)data {
    NetworkPackage* np;
    @synchronized(_pendingRSockets){
        NSUInteger index=[_pendingRSockets indexOfObject:sock];
        np=[_pendingPayloadNP objectAtIndex:index];
        [np set_Payload:data];
        np.type = NetworkPackageTypeShare;
        //NSLog()
    }
    
    @synchronized(_pendingPayloadNP){
        [_pendingPayloadNP removeObject:np];
        [_pendingRSockets removeObject:sock];
    }
    [_linkDelegate onPackageReceived:np];
}

- (void)readThroughLatestPackets:(GCDAsyncSocket *)sock : (NSString *) jsonStr {
    NSArray* packageArray=[jsonStr componentsSeparatedByString:@"\n"];
    for (NSString* dataStr in packageArray) {
        if ([dataStr length] > 0) {
            NetworkPackage* np=[NetworkPackage unserialize:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
            if (_linkDelegate && np) {
                NSLog(@"llink did read data:\n%@",dataStr);
                if ([np.type isEqualToString:NetworkPackageTypePair]) {
                    _pendingPairNP=np;
                }
                // If contains transferinfo, connect to remote using a new socket to transfer payload
                // Note: Ubuntu 20.04 sends `payloadSize` and (empty) `payloadTransferInfo` for all packages.
                if ([np _PayloadTransferInfo] != nil && [[np _PayloadTransferInfo] objectForKey:@"port"] != nil) {
                    // Received request from remote to start new TLS connection/socket to receive file
                    GCDAsyncSocket* socket=[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
                    @synchronized(_pendingRSockets){
                        [_pendingRSockets addObject:socket];
                        [_pendingPayloadNP addObject:np];
                    }
                    NSLog(@"Pending payload: size: %ld", [np _PayloadSize]);
                    NSError* error=nil;
                    uint16_t tcpPort=[[[np _PayloadTransferInfo] valueForKey:@"port"] unsignedIntValue];
                    // Create new connection here
                    if (![socket connectToHost:[sock connectedHost] onPort:tcpPort error:&error]){
                        NSLog(@"Lanlink connect to payload host failed");
                    }
                    return;
                }
                [_linkDelegate onPackageReceived:np];
            }
        }
    }
}

@end

