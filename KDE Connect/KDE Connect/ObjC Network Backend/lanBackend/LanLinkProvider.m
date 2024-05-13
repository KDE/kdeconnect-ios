/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020-2021 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2022-2023 Apollo Zhu <public-apollonian@outlook.com>
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

#import "LanLinkProvider.h"
#import "NetworkPackage.h"
#import "KDE_Connect-Swift.h"

#import <Security/Security.h>
#import <Security/SecItem.h>
#import <Security/SecTrust.h>
#import <Security/CipherSuite.h>
#import <Security/SecIdentity.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@import os.log;

@interface LanLinkProvider()
{
    uint16_t _tcpPort;
    dispatch_queue_t socketQueue;
    os_log_t logger;
}
@property(nonatomic) GCDAsyncUdpSocket *udpSocket;
@property(nonatomic) GCDAsyncSocket *tcpSocket;
@property(nonatomic) NSMutableArray<GCDAsyncSocket *> *pendingSockets;
@property(nonatomic) NSMutableArray<NetworkPackage *> *pendingNPs;
@property(nonatomic) SecCertificateRef _certificate;
//@property(nonatomic) NSString * _certificateRequestPEM;
@property(nonatomic) SecIdentityRef _identity;
@property(nonatomic,assign) CertificateService* _certificateService;
@property(nonatomic, retain) MDNSDiscovery *mdnsDiscovery;
@end

@implementation LanLinkProvider

@synthesize _linkProviderDelegate;
@synthesize _certificate;
//@synthesize _certificateRequestPEM;
@synthesize _identity;
@synthesize _certificateService;

- (LanLinkProvider *)initWithDelegate:(id<LinkProviderDelegate>)linkProviderDelegate
                   certificateService:(CertificateService *)certificateService
{
    if (self = [super initWithDelegate:linkProviderDelegate])
    {
        logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                               NSStringFromClass([self class]).UTF8String);
        _tcpPort=MIN_TCP_PORT;
        [_tcpSocket setDelegate:nil];
        [_tcpSocket disconnect];
        [_udpSocket close];
        _udpSocket=nil;
        _tcpSocket=nil;
        _pendingSockets=[NSMutableArray arrayWithCapacity:1];
        _pendingNPs = [NSMutableArray arrayWithCapacity:1];
        self.connectedLinks = [NSMutableDictionary dictionaryWithCapacity:1];
        _linkProviderDelegate=linkProviderDelegate;
        socketQueue=dispatch_queue_create("com.kde.org.kdeconnect.socketqueue", NULL);
        
        // Load private key and certificate
        _certificateService = certificateService;
        _identity = NULL;
        [self loadSecIdentity];

        _mdnsDiscovery = [[MDNSDiscovery alloc] init];
    }

    return self;
}

- (os_log_type_t)debugLogLevel {
    SelfDeviceData *settings = [SelfDeviceData shared];
    if (settings.isDebuggingDiscovery || settings.isDebuggingNetworkPackage) {
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
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Certificate loading failed");
    } else {
        _identity = identityApp;
        os_log_with_type(logger, self.debugLogLevel, "Certificate loaded successfully");
    }
    CFRelease(privateKeyRef);
    // The ownership of SecIdentityRef is in CertificateService
}

/// Requires @synchronized (self)
- (void)setupSocket
{
    os_log_with_type(logger, self.debugLogLevel, "lp setup socket");
    NSError* err;
    _tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    if (![_udpSocket enableReusePort:true error:&err]) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "udp reuse port option error");
    }
    // We will still listen to UDP Broadcast for backward compatibility
    if (![_udpSocket enableBroadcast:true error:&err]) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "udp listen broadcast error");
    }
    if (![_udpSocket bindToPort:UDP_PORT error:&err]) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "udp bind error");
    }
}

- (void)onStart {
    @synchronized (self) {
        os_log_with_type(logger, self.debugLogLevel, "lp onstart");
        [self setupSocket];
        NSError *err;
        if (![_udpSocket beginReceiving:&err]) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "UDP socket start error: %{public}@",
                             err);
            return;
        }
        os_log_with_type(logger, self.debugLogLevel,
                         "UDP socket start");
        if (![_tcpSocket isConnected]) {
            _tcpPort = [LanLinkProvider openServerSocket:_tcpSocket
                                    onFreePortStartingAt:MIN_TCP_PORT
                                                   error:&err];
            if (err) {
                os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                                 "TCP socket start error: %{public}@",
                                 err);
                [self onStop];
                return;
            }
        }
        
        os_log_with_type(logger, self.debugLogLevel,
                         "setup tcp socket on port %hu",
                         _tcpPort);

        [_mdnsDiscovery startDiscovering];
        [_mdnsDiscovery startAnnouncingWithTcpPort: _tcpPort];

        // UDP Broadcast is not disabled
        bool includeBroadcast = ![[NSUserDefaults standardUserDefaults] boolForKey:@"disableUdpBroadcastDiscovery"];
        [self sendUdpIdentityPacket:[ConnectedDevicesViewModel getDirectIPList] includeBroadcast:includeBroadcast];
    }
}

- (void)sendUdpIdentityPacket:(NSArray<NSString *> *)ipAddresses includeBroadcast:(bool)includeBroadcast
{
    if (!_udpSocket) {
        os_log_with_type(logger, OS_LOG_TYPE_ERROR,
                         "Trying to send identity packet when udp socket doesn't exist");
        return;
    }
    if ([_udpSocket isClosed]) {
        os_log_with_type(logger, OS_LOG_TYPE_ERROR,
                         "Trying to send identity packet when udp socket is closed");
        return;
    }

    os_log_with_type(logger, OS_LOG_TYPE_INFO, "sendUdpIdentityPacket");

    NetworkPackage *np = [NetworkPackage createIdentityPackageWithTCPPort:_tcpPort];
    NSData *data = [np serialize];

    if (includeBroadcast) {
        [_udpSocket sendData:data toHost:@"255.255.255.255" port:PORT withTimeout:-1 tag:UDPBROADCAST_TAG];
    }

    for (NSString *address in ipAddresses) {
        [_udpSocket sendData:data toHost:address port:PORT withTimeout:-1 tag:UDPBROADCAST_TAG];
    }
}

- (void)onStop {
    @synchronized (self) {
        os_log_with_type(logger, self.debugLogLevel, "lp onstop");

        [_mdnsDiscovery stopAnnouncing];
        [_mdnsDiscovery stopDiscovering];

        [_udpSocket setDelegate:nil];
        [_tcpSocket setDelegate:nil];
        [_udpSocket close];
        [_tcpSocket disconnect];
        
        for (GCDAsyncSocket *socket in _pendingSockets) {
            [socket disconnect];
        }
        for (BaseLink *link in [self.connectedLinks allValues]) {
            [link disconnect];
        }
        
        [_pendingNPs removeAllObjects];
        [_pendingSockets removeAllObjects];
        [self.connectedLinks removeAllObjects];
        _udpSocket = nil;
        _tcpSocket = nil;
    }
}

- (void) onRefresh
{
    os_log_with_type(logger, self.debugLogLevel, "lp on refresh");
    // Checking isConnected requires something to be actually connected,
    // while isDisconnected only check if server socket has started...
    if (!_tcpSocket || [_tcpSocket isDisconnected]) {
        [self onNetworkChange];
        return;
    }

    [_mdnsDiscovery stopDiscovering];
    [_mdnsDiscovery startDiscovering];
    [self sendUdpIdentityPacket:[ConnectedDevicesViewModel getDirectIPList] includeBroadcast:true];
}

- (void)onNetworkChange
{
    os_log_with_type(logger, self.debugLogLevel, "lp on networkchange");
    [self onStop];
    [self onStart];
}


- (void) onLinkDestroyed:(BaseLink*)link
{
    os_log_with_type(logger, self.debugLogLevel, "lp on linkdestroyed");
    if (link == self.connectedLinks[[link _deviceId]]) {
        [self.connectedLinks removeObjectForKey:[link _deviceId]];
    }
}

#pragma mark UDP Socket Delegate
/**
 * Called when the socket has received the requested datagram.
 **/

//a new device is introducing itself to me
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    
    // Unserialize received data
    os_log_with_type(logger, self.debugLogLevel,
                     "lp receive udp package: %{public}@",
                     [[NSString alloc] initWithData:data
                                           encoding:NSUTF8StringEncoding]);
	NetworkPackage* np = [NetworkPackage unserialize:data];
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "linkprovider:received a udp package from %{mask.hash}@",[np objectForKey:@"deviceName"]);
    //not id package
    
    if (![np.type isEqualToString:NetworkPackageTypeIdentity]) {
        os_log_with_type(logger, self.debugLogLevel, "LanLinkProvider:expecting an id package");
        return;
    }
    
    NSString *host;
    uint16_t port;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];

    //my own package, don't care
    NetworkPackage *np2 = [NetworkPackage createIdentityPackageWithTCPPort:_tcpPort];
    NSString* myId=[[np2 _Body] valueForKey:@"deviceId"];
    if ([[np objectForKey:@"deviceId"] isEqualToString:myId]){
        os_log_with_type(logger, self.debugLogLevel, "Ignore my own id package from %{mask.hash}@:%hu", host, port);
        return;
    }
    
    //deal with id package, might be ipV6 filtering, need to figure out
    if ([host hasPrefix:@"::ffff:"]) {
        os_log_with_type(logger, self.debugLogLevel, "Ignore packet");
        return;
    }
    
    // Because we can't tell when another device disconnects from network,
    // we'll always have to re-attempt connecting to that device whenever
    // we receive an identity packet, even if it appears connected currently.
    if ([ConnectedDevicesViewModel isDeviceCurrentlyPairedAndConnected:[np objectForKey:@"deviceId"]]) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO,
                         "Received identity packet from %{mask.hash}@, which is already connected (aka paired & reachable), reconnecting",
                         [np objectForKey:@"deviceName"]);
    }
    
    // Get ready to establish TCP connection to incoming host
    os_log_with_type(logger, self.debugLogLevel, "LanLinkProvider:id package received, creating link and a TCP connection socket");
    GCDAsyncSocket* socket=[[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    uint16_t tcpPort=[np integerForKey:@"tcpPort"];
    
    NSError* error=nil;
    if (![socket connectToHost:host onPort:tcpPort error:&error]) {
        // If TCP connection failed, make new packet with _tcpPort, then broadcast again
        
        os_log_with_type(logger, self.debugLogLevel, "LanLinkProvider:tcp connection error");
        os_log_with_type(logger, self.debugLogLevel, "try reverse connection");
        
        NSMutableArray* ips = [[NSMutableArray alloc] init];
        [ips addObject:host];
        [self sendUdpIdentityPacket:ips includeBroadcast:false];

        return;
    }
    os_log_with_type(logger, self.debugLogLevel, "connecting");
    
    // Now that TCP is successful, I know the incoming host, now it's time for the incoming host
    // to know me, I send ID Packet to incoming Host via the just established TCP
    //if (([np _Payload] == nil) && ([np PayloadTransferInfo] == nil) && ([np _PayloadSize]) == 0) {
    // TODO: It seems like only identity packets ever show up here, why? Where is the id packet being sent when a new transfer connection is opened then????? This seems to be the ONLY place where ID packets are sent in TCP?
    NetworkPackage *inp = [NetworkPackage createIdentityPackageWithTCPPort:_tcpPort];
    NSData *inpData = [inp serialize];
    [socket writeData:inpData withTimeout:0 tag:PACKAGE_TAG_IDENTITY];
    //}
    
    //add to pending connection list
    @synchronized(_pendingNPs)
    {
        [_pendingSockets insertObject:socket atIndex:0];
        [_pendingNPs insertObject:np atIndex:0];
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    os_log_with_type(logger, OS_LOG_TYPE_FAULT, "udp socket closed due to %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    os_log_with_type(logger, OS_LOG_TYPE_FAULT, "udp socket did not send data due to %@", error);
}

#pragma mark TCP Socket Delegate
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

// Just
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    os_log_with_type(logger, self.debugLogLevel, "TCP server: didAcceptNewSocket");
    [newSocket performBlock:^{
        [newSocket enableBackgroundingOnSocket];
    }];
    [_pendingSockets addObject:newSocket];
    long index=[_pendingSockets indexOfObject:newSocket];
    //retrieve id package
    [newSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:index];
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/

// We try to establish TLS with a remote device after receiving their identity packet
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "tcp socket didConnectToHost %{mask.hash}@", host);

    //create LanLink and inform the background
    NSUInteger index=[_pendingSockets indexOfObject:sock];
    NetworkPackage* np=[_pendingNPs objectAtIndex:index];
    NSString* deviceId=[np objectForKey:@"deviceId"];
    BaseLink *link = self.connectedLinks[deviceId];
    
    // If reusing old link, certificate checking is LanLinkProvider's responsibility
    if (link) {
        // Last timing to enableBackgroundingOnSocket before stream opens
        [sock performBlock:^{
            [sock enableBackgroundingOnSocket];
        }];
        sock.userData = deviceId;
    } else {
        [sock setDelegate:nil];
    }

    NSArray *myCerts = [[NSArray alloc] initWithObjects: (__bridge id)_identity, nil];
    NSDictionary *tlsSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
        (id)[NSNumber numberWithBool:YES],                  (id)kCFStreamSSLIsServer,
        (id)[NSNumber numberWithBool:YES],                  (id)GCDAsyncSocketManuallyEvaluateTrust,
        (id)[NSNumber numberWithInt:kAlwaysAuthenticate],   (id)GCDAsyncSocketSSLClientSideAuthenticate,
        (id)myCerts,                                        (id)kCFStreamSSLCertificates,
    nil];

    os_log_with_type(logger, self.debugLogLevel, "Start Server TLS");
    [sock startTLS:tlsSettings];
    
    if (link) {
        // reuse existing link once socket secures
        [_linkProviderDelegate onDeviceIdentityUpdatePackageReceived:np];
    } else {
        link = [[LanLink alloc] init:sock
                            deviceId:deviceId
                         setDelegate:nil
                  certificateService:_certificateService];
        self.connectedLinks[deviceId] = link;
        [_linkProviderDelegate onConnectionReceived:np link:link];
    }
    [_pendingSockets removeObject:sock];
    [_pendingNPs removeObject:np];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    os_log_with_type(logger, self.debugLogLevel, "lp tcp socket didReadData");
    //os_log_with_type(logger, self.debugLogLevel, "%{public}@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSString * jsonStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray* packageArray=[jsonStr componentsSeparatedByString:@"\n"];
    for (NSString* dataStr in packageArray) {
        if ([dataStr length] > 0) {
            NetworkPackage* np=[NetworkPackage unserialize:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
            if (![np.type isEqualToString:NetworkPackageTypeIdentity]) {
                os_log_with_type(logger, OS_LOG_TYPE_INFO, "lp expecting an id package instead of %{public}@", np.type);
                return;
            }
            NSString* deviceId=[np objectForKey:@"deviceId"];
            
            /* Test with cert file */
            NSArray *myCerts = [[NSArray alloc] initWithObjects:(__bridge id)_identity, /*(__bridge id)cert2UseRef,*/ nil];
            
            /*NSLog(@"%@", _certificate);*/
            /* TLS */
            NSDictionary *tlsSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         //(id)kCFStreamSocketSecurityLevelNegotiatedSSL, (id)kCFStreamSSLLevel,
                                         //(id)kCFBooleanFalse,       (id)kCFStreamSSLAllowsExpiredCertificates,  /* Disallowed expired certificate   */
                                         //(id)kCFBooleanFalse,       (id)kCFStreamSSLAllowsExpiredRoots,         /* Disallowed expired Roots CA      */
                                         //(id)kCFBooleanTrue,        (id)kCFStreamSSLAllowsAnyRoot,              /* Allow any root CA                */
                                         //(id)kCFBooleanFalse,       (id)kCFStreamSSLValidatesCertificateChain,  /* Do not validate all              */
                                         (id)deviceId,              (id)kCFStreamSSLPeerName,                   /* Set peer name to the one we received */
                                         // (id)[[SecKeyWrapper sharedWrapper] getPrivateKeyRef], (id),
                                         //(id)kCFBooleanTrue,        (id)GCDAsyncSocketManuallyEvaluateTrust,
                                         (__bridge CFArrayRef) myCerts, (id)kCFStreamSSLCertificates,
                                         (id)[NSNumber numberWithInt:0],       (id)kCFStreamSSLIsServer,
                                         (id)[NSNumber numberWithInt:1], (id)GCDAsyncSocketManuallyEvaluateTrust,
                                         nil];
            
            [sock startTLS: tlsSettings];
            os_log_with_type(logger, self.debugLogLevel, "Start Client TLS");
            
            [sock setDelegate:nil];
            [_pendingSockets removeObject:sock];
            
            BaseLink *link = self.connectedLinks[deviceId];
            if (link) {
                // reuse existing link once socket secures
                [_linkProviderDelegate onDeviceIdentityUpdatePackageReceived:np];
                return;
            }
            // create LanLink and inform the background
            link = [[LanLink alloc] init:sock
                              deviceId:deviceId
                           setDelegate:nil
                    certificateService:_certificateService];
            self.connectedLinks[deviceId] = link;
            if (_linkProviderDelegate) {
                [_linkProviderDelegate onConnectionReceived:np link:link];
            }
        }
    }
    
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
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
 * then an invocation of this delegate method will be enqueued on the delegateQueue
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
    if (sock == nil) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO,
                         "deallocated socket disconnected with error: %{public}@",
                         err);
        return;
    }
    
    if (sock==_tcpSocket) {
        os_log_with_type(logger, (err) ? OS_LOG_TYPE_ERROR : OS_LOG_TYPE_INFO,
                         "tcp server disconnected with error: %{public}@",
                         err);
        _tcpSocket.delegate = nil;
        _tcpSocket=nil;
    }
    else
    {
        os_log_with_type(logger, (err) ? OS_LOG_TYPE_ERROR : OS_LOG_TYPE_INFO,
                         "tcp socket disconnected with error: %{public}@",
                         err);
        [_pendingSockets removeObject:sock];
    }
}

- (BOOL)socketShouldManuallyEvaluateTrust:(GCDAsyncSocket *)sock
{
    os_log_with_type(logger, self.debugLogLevel, "Should Evaluate Certificate LanLinkProvider");
    return YES;
}

// This doesn't actually get called anywhere, not sure what it does
- (BOOL)socket:(GCDAsyncSocket *)sock shouldTrustPeer:(SecTrustRef)trust
{
    if ([_certificateService verifyCertificateEqualityFromRemoteDeviceWithTrust:trust]) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLinkProvider's shouldTrustPeer received Certificate from %{mask.hash}@, trusting", [sock connectedHost]);
        return YES;
    } else {
        return NO;
    }
}

// After securing, create a LanLink for further communications
- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    os_log_with_type(logger, self.debugLogLevel, "Connection is secure LanLinkProvider");
    [sock setDelegate:nil];
    NSUInteger pendingSocketIndex = [_pendingSockets indexOfObject:sock];
    [_pendingSockets removeObject:sock];
    
    NetworkPackage* pendingNP = [_pendingNPs objectAtIndex:pendingSocketIndex];
    NSString *deviceID = [pendingNP objectForKey:@"deviceId"];
    // if existing LanLink exists, DON'T create a new one
    LanLink *link = (LanLink *)self.connectedLinks[deviceID];
    if (link) {
        [link setSocket:sock];
    } else {
        // create LanLink and inform the background
        link = [[LanLink alloc] init:sock
                            deviceId:deviceID
                         setDelegate:nil
                  certificateService:_certificateService];
        self.connectedLinks[deviceID] = link;
    }
}

// This gets called when we start server TLS reusing an old link, and
// it's now our term to evaluate client's certificate.
- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    NSString *deviceID = (NSString *)sock.userData;
    if ([_certificateService verifyCertificateEqualityWithTrust:trust
                                   fromRemoteDeviceWithDeviceID:deviceID]) {
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "LanLinkProvider's didReceiveTrust received Certificate from %{mask.hash}@, trusting", [sock connectedHost]);
        completionHandler(YES);// give YES if we want to trust, NO if we don't
    } else {
        completionHandler(NO);
    }
}

+ (uint16_t)openServerSocket:(GCDAsyncSocket *)socket
        onFreePortStartingAt:(uint16_t)minPort
                       error:(NSError **)errPtr {
    uint16_t port = minPort;
    NSError *err;
    os_log_t logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                                    NSStringFromClass([self class]).UTF8String);
    
    while (![socket acceptOnPort:port error:&err]) {
        os_log_with_type(logger, OS_LOG_TYPE_ERROR,
                         "tcp socket start on port %hu errored: %{public}@",
                         port, err);
        port++;
        if (port > MAX_TCP_PORT) {
            os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                             "tcp socket has no available port to use");
            if (errPtr) {
                *errPtr = err;
            }
            return 0;
        }
    }
    
    return port;
}

@end
