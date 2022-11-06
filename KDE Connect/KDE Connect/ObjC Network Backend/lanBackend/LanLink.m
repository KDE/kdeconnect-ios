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

@import os.log;

#define PAYLOAD_PORT 1739
#define PAYLOAD_SEND_DELAY 0 //ns
// NSUInteger defaultReadLength = (1024 * 32) from CocoaAsyncSocket
#define CHUNK_SIZE (1024 * 32)

@interface LanLink()
{
    uint16_t _payloadPort;
    dispatch_queue_t _socketQueue;
    os_log_t logger;
}

@property(nonatomic) GCDAsyncSocket* _socket;
@property(nonatomic) NetworkPackage* _pendingPairNP;

// Lock using _socketsForIncomingPayload
@property(nonatomic) NSMutableArray<GCDAsyncSocket *> *socketsForIncomingPayload;
@property(nonatomic) NSMutableArray<NetworkPackage *> *networkPackagesForIncomingPayload;
@property(nonatomic) NSMutableArray<NSFileHandle *> *incomingPayloads;
@property(nonatomic) NSMutableArray<NSNumber *> *incomingPayloadsBytesRemaining;

// Lock using _socketsForOutgoingPayload
@property(nonatomic) NSMutableArray<GCDAsyncSocket *> *socketsForOutgoingPayload;
@property(nonatomic) NSMutableArray<NetworkPackage *> *networkPackagesForOutgoingPayload;
@property(nonatomic) NSMutableArray<NSFileHandle *> *outgoingPayloads;

@property(nonatomic) SecIdentityRef _identity;
@property(nonatomic) GCDAsyncSocket* _fileServerSocket;
@property(nonatomic,assign) CertificateService* _certificateService;

@end

@implementation LanLink

@synthesize _deviceId;
@synthesize _linkDelegate;
@synthesize _pendingPairNP;
@synthesize _socket;
@synthesize _identity;
@synthesize _fileServerSocket;
@synthesize _certificateService;

- (LanLink*) init:(GCDAsyncSocket*)socket deviceId:(NSString*) deviceid setDelegate:(id)linkdelegate certificateService:(CertificateService*)certificateService
{
    if (self = [super init:deviceid setDelegate:linkdelegate])
    {
        logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                               NSStringFromClass([self class]).UTF8String);
        _socket=socket;
        _deviceId=deviceid;
        _linkDelegate=linkdelegate;
        _pendingPairNP=nil;
        [_socket setDelegate:self];
        [_socket performBlock:^{
            [_socket enableBackgroundingOnSocket];
        }];
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLink:lanlink for device:%{mask.hash}@ created",_deviceId);
        [_socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:PACKAGE_TAG_NORMAL];
        
        _socketsForOutgoingPayload = [NSMutableArray arrayWithCapacity:1];
        _networkPackagesForOutgoingPayload = [NSMutableArray arrayWithCapacity:1];
        _outgoingPayloads = [NSMutableArray arrayWithCapacity:1];
        
        _socketsForIncomingPayload = [NSMutableArray arrayWithCapacity:1];
        _networkPackagesForIncomingPayload = [NSMutableArray arrayWithCapacity:1];
        _incomingPayloads = [NSMutableArray arrayWithCapacity:1];
        _incomingPayloadsBytesRemaining = [NSMutableArray arrayWithCapacity:1];
        
        _payloadPort=PAYLOAD_PORT;
        _socketQueue=dispatch_queue_create("com.kde.org.kdeconnect.payload_socketQueue", NULL);
    
        _certificateService = certificateService;
        [self loadSecIdentity];
    }
    return self;
}

- (os_log_type_t)debugLogLevel {
    if ([SelfDeviceData shared].isDebuggingNetworkPackage) {
        return OS_LOG_TYPE_INFO;
    }
    return OS_LOG_TYPE_DEBUG;
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
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Certificate loading failed: %d", status);
    } else {
        _identity = identityApp;
        os_log_with_type(logger, self.debugLogLevel, "Certificate loaded successfully");
    }
    CFRelease(privateKeyRef);
    // The ownership of SecIdentityRef is in CertificateService
}

- (BOOL) sendPackage:(NetworkPackage *)np tag:(long)tag
{
    os_log_with_type(logger, self.debugLogLevel, "llink send package");
    if (![_socket isConnected]) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLink: Device:%@ disconnected", _deviceId);
        return NO;
    }
    
    // If sharing file, start file sharing procedure
    if (np.payloadPath != nil && tag == PACKAGE_TAG_SHARE) {
        NSError* err;
        if (_fileServerSocket == nil) {
            _fileServerSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
            if (![_fileServerSocket isConnected]) {
                if (![_fileServerSocket acceptOnPort:_payloadPort error:&err]) {
                    os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Error binding payload port");
                    // TODO: investigate if we should abort and not try to send anything
                } else {
                    os_log_with_type(logger, self.debugLogLevel, "Binding payload server ok");
                }
            }
        }
        [np.payloadPath startAccessingSecurityScopedResource];
        NSError *error;
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:np.payloadPath
                                                                   error:&error];
        if (error) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "Can't create file handle for %{public}@ due to %{public}@",
                             [np objectForKey:@"filename"],
                             error);
            [np.payloadPath stopAccessingSecurityScopedResource];
            return NO;
        }
        @synchronized (_socketsForOutgoingPayload) {
            [_networkPackagesForOutgoingPayload addObject:np];
            [_outgoingPayloads addObject:handle];
        }
    }
    
    NSData* data=[np serialize];
    [_socket writeData:data withTimeout:-1 tag:tag];
    // TODO: return YES only when send successfully
    os_log_with_type(logger, self.debugLogLevel, "%{public}@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return YES;
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
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLink: Device:%{mask.hash}@ disconnected",_deviceId);
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
    os_log_with_type(logger, self.debugLogLevel, "Lanlink: didAcceptNewSocket");

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
    [_socketsForOutgoingPayload insertObject:newSocket atIndex:0];
    os_log_with_type(logger, self.debugLogLevel, "Start Server TLS to send file");
}


/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "Lanlink did connect to payload host, begin receiving data from %{mask.hash}@ %d", host, port);

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
    os_log_with_type(logger, self.debugLogLevel, "Start Client TLS to receive file");
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // If the data received has a payload tag (indicating that it is a payload, e.g file transferred
    // from the Share plugin, prepare a NetworkPackage with the payload in it and give it to the
    // Plugins to handle it
    os_log_with_type(logger, self.debugLogLevel,
                     "Package received with tag: %{public}@",
                     [NetworkPackage descriptionFor: tag]);
    if (tag==PACKAGE_TAG_PAYLOAD) {
        [self writeReceivedChunk:data for:sock];
        return;
    }
    
    os_log_with_type(logger, self.debugLogLevel, "llink did read data");
    // BUG even if we read with a separator LFData, it's still possible to receive several data package together. So we split the string and retrieve the package
    [_socket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:PACKAGE_TAG_NORMAL];
    NSString * jsonStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "Received: %{public}@", jsonStr);
    [self readThroughLatestPackets:sock :jsonStr];
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    os_log_with_type(logger, self.debugLogLevel,
                     "llink didWriteData for tag %{public}@",
                     [NetworkPackage descriptionFor:tag]);
    if (tag == PACKAGE_TAG_PAYLOAD) {
        [self sendPayloadWithSocket:sock];
        return;
    }
    if (_linkDelegate) {
        [_linkDelegate onSendSuccess:tag];
    }
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
 * In this case it may preferable to nil the delegate beforehand, like this:
 *
 * asyncSocket.delegate = nil; // Don't invoke my delegate method
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * Of course, this depends on how your state machine is configured.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    @synchronized (_socketsForIncomingPayload) {
        if ([_socketsForIncomingPayload containsObject:sock]) {
            os_log_with_type(logger, OS_LOG_TYPE_INFO,
                             "llink payload receiving socket disconnected with error: %{public}@",
                             err);
            [self removeIncomingPayloadReceivingSocket:sock
                                   deleteTemporaryFile:YES];
        }
    }
    @synchronized (_socketsForOutgoingPayload) {
        if ([_socketsForOutgoingPayload containsObject:sock]) {
            os_log_with_type(logger, OS_LOG_TYPE_INFO,
                             "llink payload sending socket disconnected with error: %{public}@",
                             err);
            [self removeOutgoingPayloadSendingSocket:sock];
        }
    }
    if (_linkDelegate&&(sock==_socket)) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "llink socket did disconnect with error: %{public}@", err);
        [_linkDelegate onLinkDestroyed:self];
    }
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    // TODO: report the sending process percentage
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    os_log_with_type(logger, self.debugLogLevel, "Connection is secure");
    
    @synchronized(_socketsForOutgoingPayload){
        if ([_socketsForOutgoingPayload count] > 0) {
            // I'm the server
            [self sendPayloadWithSocket: sock];
        }
    }

    @synchronized (_socketsForIncomingPayload) {
        if ([_socketsForIncomingPayload count] > 0) {
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
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLink's didReceiveTrust received Certificate from %{mask.hash}@, trusting", [sock connectedHost]);
        completionHandler(YES);
    } else {
        completionHandler(NO);
    }
}

#pragma mark - Sending Payloads for Share Plugin

- (void)sendPayloadWithSocket:(GCDAsyncSocket *)sock {
    NSFileHandle *handle;
    @synchronized (_socketsForOutgoingPayload) {
        NSUInteger index=[_socketsForOutgoingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "Can't find index of file handle to read from for %{public}@",
                             sock);
            return;
        }
        handle = _outgoingPayloads[index];
    }
    NSError *error;
    NSData *chunk = [handle readDataUpToLength:CHUNK_SIZE error:&error];
    if (error) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                         "Failed to read chunk due to %{public}@",
                         error);
        [self removeOutgoingPayloadSendingSocket:sock];
        return;
    }
    if ([chunk length] == 0) {
        [self removeOutgoingPayloadSendingSocket:sock];
        if (_linkDelegate) {
            [_linkDelegate onSendSuccess:PACKAGE_TAG_PAYLOAD];
        }
        return;
    }
    dispatch_time_t t = dispatch_time(DISPATCH_TIME_NOW, 0);
    t=dispatch_time(t, PAYLOAD_SEND_DELAY*NSEC_PER_MSEC);
    dispatch_after(t,_socketQueue, ^(void){
        [sock writeData:chunk withTimeout:-1 tag:PACKAGE_TAG_PAYLOAD];
    });
}

- (void)removeOutgoingPayloadSendingSocket:(GCDAsyncSocket *)sock {
    @synchronized (_socketsForOutgoingPayload) {
        NSUInteger index = [_socketsForOutgoingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_INFO,
                             "Already cleaned up for %{public}@ for outgoing payload",
                             sock);
            return;
        }
        [_socketsForOutgoingPayload removeObjectAtIndex:index];
        [_outgoingPayloads removeObjectAtIndex:index];
        NetworkPackage *np = _networkPackagesForOutgoingPayload[index];
        [np.payloadPath stopAccessingSecurityScopedResource];
        [_networkPackagesForOutgoingPayload removeObjectAtIndex:index];
    }
}

#pragma mark - Receiving Payloads for Share Plugin

- (void)createSocketForReceivingPayloadOfNP:(NetworkPackage *)np incomingFromHost:(NSString *)host {
    // Create file handle for writing data chunk by chunk to temporary file
    NSString *randomID = [[NSProcessInfo processInfo] globallyUniqueString];
    // TODO: Replace NSTemporaryDirectory with NSItemReplacementDirectory
    // when we allow user to specify where they want to save files to
    NSArray<NSString *> *pathComponents = @[NSTemporaryDirectory(), randomID];
    NSString *tempPath = [NSString pathWithComponents:pathComponents];
    BOOL exists = [[NSFileManager defaultManager]
                   createFileAtPath:tempPath contents:nil attributes:nil];
    if (!exists) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                         "Failed to create temporary file for receiving shared file at %@",
                         tempPath);
        return;
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
    np.payloadPath = [NSURL fileURLWithPath:tempPath];
    
    // Received request from remote to start new TLS connection/socket to receive file
    GCDAsyncSocket* socket=[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    @synchronized(_socketsForIncomingPayload){
        [_socketsForIncomingPayload addObject:socket];
        [_networkPackagesForIncomingPayload addObject:np];
        [_incomingPayloads addObject:handle];
        [_incomingPayloadsBytesRemaining addObject:[NSNumber numberWithLong:np._PayloadSize]];
    }
    os_log_with_type(logger, self.debugLogLevel, "Pending payload: size: %ld", [np _PayloadSize]);
    NSError *error = nil;
    uint16_t tcpPort = [[[np _PayloadTransferInfo] valueForKey:@"port"] unsignedIntValue];
    // Create new connection here
    if (![socket connectToHost:host onPort:tcpPort error:&error]){
        os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                         "Lanlink connect to payload host failed due to %{public}@",
                         error);
        [self removeIncomingPayloadReceivingSocket:socket
                               deleteTemporaryFile:YES];
    }
}

- (void)receivePayloadWithSocket:(GCDAsyncSocket *)sock {
    long length = CHUNK_SIZE;
    @synchronized (_socketsForIncomingPayload) {
        NSUInteger index = [_socketsForIncomingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "Can't find index of remaining bytes to receive from %{public}@",
                             sock);
            return;
        }
        long remainingSize = [_incomingPayloadsBytesRemaining[index] longValue];
        if (remainingSize < CHUNK_SIZE) {
            length = remainingSize;
        }
    }
    os_log_with_type(logger, self.debugLogLevel,
                     "Reading from socket %{public}@ %ld bytes",
                     _socketsForIncomingPayload, length);
    [sock readDataToLength:length withTimeout:-1 tag:PACKAGE_TAG_PAYLOAD];
}

- (void)writeReceivedChunk:(NSData *)data for:(GCDAsyncSocket *)sock {
    NSFileHandle *handle;
    long remaining;
    @synchronized (_socketsForIncomingPayload) {
        NSUInteger index = [_socketsForIncomingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "Can't find index of file handle to write to for %{public}@",
                             sock);
            return;
        }
        handle = _incomingPayloads[index];
        remaining = [_incomingPayloadsBytesRemaining[index] longValue];
        remaining -= data.length;
        _incomingPayloadsBytesRemaining[index] = [NSNumber numberWithLong: remaining];
    }
    NSError *error;
    [handle writeData:data error:&error];
    if (error) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                         "Failed to write chunk to temporary file due to %{public}@",
                         error);
        [self removeIncomingPayloadReceivingSocket:sock
                               deleteTemporaryFile:YES];
        return;
    }
    if (remaining == 0 || data.length == 0) {
        [self attachAndProcessPayload:sock];
        return;
    }
    [self receivePayloadWithSocket:sock];
}

- (void)attachAndProcessPayload:(GCDAsyncSocket *)sock {
    NetworkPackage* np;
    @synchronized (_socketsForIncomingPayload) {
        NSUInteger index = [_socketsForIncomingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "Finished writing file but %{public}@ is already cleaned up",
                             sock);
            return;
        }
        np = _networkPackagesForIncomingPayload[index];
        np.type = NetworkPackageTypeShare;
        // Ensure that temporary file can't be deleted by removing sock
        [self removeIncomingPayloadReceivingSocket:sock
                               deleteTemporaryFile:NO];
    }
    [_linkDelegate onPackageReceived:np];
}

- (void)removeIncomingPayloadReceivingSocket:(GCDAsyncSocket *)sock
                         deleteTemporaryFile:(BOOL)deleteTemporaryFile {
    NSURL *url;
    @synchronized(_socketsForIncomingPayload){
        NSUInteger index=[_socketsForIncomingPayload indexOfObject:sock];
        if (index == NSNotFound) {
            os_log_with_type(logger, OS_LOG_TYPE_INFO,
                             "Already cleaned up for %{public}@ for incoming payload",
                             sock);
            return;
        }
        [_socketsForIncomingPayload removeObject:sock];
        [_incomingPayloads removeObjectAtIndex:index];
        [_incomingPayloadsBytesRemaining removeObjectAtIndex:index];
        NetworkPackage *np = _networkPackagesForIncomingPayload[index];
        url = np.payloadPath;
        [_networkPackagesForIncomingPayload removeObjectAtIndex:index];
    }
    if (deleteTemporaryFile) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        if (error) {
            os_log_with_type(logger, OS_LOG_TYPE_ERROR,
                             "Failed to remove temporary file %{public}@ due to %{public}@",
                             url, error);
        }
    }
}

#pragma mark - Others

- (void)dealloc {
    os_log_with_type(logger, self.debugLogLevel, "Lan Link destroyed");
}

- (void)readThroughLatestPackets:(GCDAsyncSocket *)sock : (NSString *) jsonStr {
    NSArray* packageArray=[jsonStr componentsSeparatedByString:@"\n"];
    for (NSString* dataStr in packageArray) {
        if ([dataStr length] > 0) {
            NetworkPackage* np=[NetworkPackage unserialize:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
            if (_linkDelegate && np) {
                os_log_with_type(logger, self.debugLogLevel, "llink did read data:\n%{public}@",dataStr);
                if ([np.type isEqualToString:NetworkPackageTypePair]) {
                    _pendingPairNP=np;
                }
                // If contains transferinfo, connect to remote using a new socket to transfer payload
                // Note: Ubuntu 20.04 sends `payloadSize` and (empty) `payloadTransferInfo` for all packages.
                if ([np _PayloadTransferInfo] != nil && [[np _PayloadTransferInfo] objectForKey:@"port"] != nil) {
                    [self createSocketForReceivingPayloadOfNP:np
                                             incomingFromHost:[sock connectedHost]];
                } else {
                    [_linkDelegate onPackageReceived:np];
                }
            }
        }
    }
}

@end

