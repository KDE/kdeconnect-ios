/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//Copyright 29/4/14  YANG Qiao yangqiao0505@me.com
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
//---------------------------------------------------------------------

#import "Device.h"
//#import "BackgroundService.h"
#import "KDE_Connect-Swift.h"
@import os.log;
static const NSTimeInterval kPairingTimeout = 30.0;

@implementation Device {
    NSMutableDictionary<NetworkPacketType, id<Plugin>> *_plugins;
    NSMutableDictionary<NetworkPacketType, NSNumber *> *_pluginsEnableStatus;
    os_log_t logger;
}

@synthesize _deviceInfo;
@synthesize _pairStatus;
@synthesize deviceDelegate;
@synthesize _links;
- (void)setPlugins:(NSDictionary<NetworkPacketType, NSNumber *> *)plugins
{
    _plugins = [[NSMutableDictionary alloc] initWithDictionary:plugins];
}
@synthesize _failedPlugins;
//@synthesize _testDevice;

- (void)setPluginsEnableStatus:(NSDictionary<NetworkPacketType, NSNumber *> *)pluginsEnableStatus
{
    _pluginsEnableStatus = [[NSMutableDictionary alloc] initWithDictionary:pluginsEnableStatus];
}

// TODO: plugins should be saving their own preferences
// Plugin-specific persistent data are stored in the Device object. Plugin objects contain runtime
// data only and are therefore NOT stored persistently
// Remote Input
@synthesize _cursorSensitivity;
// Presenter
@synthesize _pointerSensitivity;

- (instancetype)initWithLink:(BaseLink*)link
                              delegate:(id<DeviceDelegate>)deviceDelegate {
    if (self = [super init]) {
        logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                               NSStringFromClass([self class]).UTF8String);
        _pairStatus = NotPaired;
        _deviceInfo = [link _deviceInfo];
        _links = [NSMutableArray arrayWithCapacity:1];
        _plugins = [NSMutableDictionary dictionaryWithCapacity:1];
        _failedPlugins = [NSMutableArray arrayWithCapacity:1];
        _pluginsEnableStatus = [NSMutableDictionary dictionary];
        self.deviceDelegate = deviceDelegate;
        _cursorSensitivity = 3.0;
#if !TARGET_OS_OSX
        _hapticStyle = 0;
#endif
        _pointerSensitivity = 3.0;
        [self addLink:link];
    }
    return self;
}

- (os_log_type_t)debugLogLevel {
    if ([KdeConnectSettings shared].isDebuggingDiscovery) {
        return OS_LOG_TYPE_INFO;
    }
    return OS_LOG_TYPE_DEBUG;
}

- (NSInteger) compareProtocolVersion
{
    return 0;
}

#pragma mark Link-related Functions

- (bool)updateInfo:(DeviceInfo*)newDeviceInfo {
    // TODO: Notify of the change
    _deviceInfo=newDeviceInfo;
    return true;
}

- (void)addLink:(BaseLink*)link {
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "add link to %{mask.hash}@",_deviceInfo.id);
    NSUInteger count;
    @synchronized (_links) {
        [_links addObject:link];
        [link setLinkDelegate:self];
        count = [_links count];
    }
    if (count == 1) {
        os_log_with_type(logger, self.debugLogLevel, "one link available");
        if (deviceDelegate) {
            [deviceDelegate onDeviceReachableStatusChanged:self];
        }
        [self reloadPlugins];
        // FIXME: Move this to the battery plugin itself
        if (_pairStatus == Paired) {
            [self updateBatteryStatus];
        }
    }
}

// FIXME: This doesn't get called when connection is cut (e.g wifi off) from the remote device
- (void) onLinkDestroyed:(BaseLink *)link
{
    os_log_with_type(logger, self.debugLogLevel, "device on link destroyed");
    NSUInteger count;
    @synchronized (_links) {
        [_links removeObject:link];
        count = [_links count];
    }
    os_log_with_type(logger, self.debugLogLevel, "remove link ; %lu remaining", count);
    if (count == 0) {
        os_log_with_type(logger, self.debugLogLevel, "no available link");
        if (deviceDelegate) {
            [deviceDelegate onDeviceReachableStatusChanged:self];
            // No, we don't want to remove the plugins because IF the device is coming back online later, we want to still have to ready
            //[_plugins removeAllObjects];
            //[_failedPlugins removeAllObjects];
        }
    }
    if (deviceDelegate) {
        [deviceDelegate onLinkDestroyed:link];
    }
}

- (BOOL) sendPacket:(NetworkPacket *)np tag:(long)tag
{
    os_log_with_type(logger, self.debugLogLevel, "device send packet");
    @synchronized (_links) {
        for (BaseLink *link in _links) {
            if ([link sendPacket:np tag:tag]) {
                return true;
            }
        }
    }
    return false;
}

- (void)onPacket:(NetworkPacket *)np sentWithPacketTag:(long)tag {
    os_log_with_type(logger, self.debugLogLevel, "device on send success");
    if (tag==PACKET_TAG_PAIR) {
        if (_pairStatus==RequestedByPeer) {
            [self setAsPaired];
        }
    } else if (tag == PACKET_TAG_PAYLOAD){
        os_log_with_type(logger, self.debugLogLevel, "Last payload sent successfully, sending next one");
        for (id<Plugin> plugin in [_plugins allValues]) {
            if ([plugin respondsToSelector:@selector(onPacket:sentWithPacketTag:)]) {
                [plugin onPacket:np sentWithPacketTag:tag];
            }
        }
    }
}

- (void)onPacket:(NetworkPacket *)np sendWithPacketTag:(long)tag
  failedWithError:(NSError *)error {
    switch (tag) {
        case PACKET_TAG_PAYLOAD:
            for (id<Plugin> plugin in [_plugins allValues]) {
                if ([plugin respondsToSelector:@selector(onPacket:sendWithPacketTag:failedWithError:)]) {
                    [plugin onPacket:np sendWithPacketTag:tag
                      failedWithError:error];
                }
            }
            break;
        default:
            break;
    }
}

- (void)onSendingPayload:(KDEFileTransferItem *)payload {
    for (id<Plugin> plugin in [_plugins allValues]) {
        if ([plugin respondsToSelector:@selector(onSendingPayload:)]) {
            [plugin onSendingPayload:payload];
        }
    }
}

- (void)willReceivePayload:(KDEFileTransferItem *)payload
  totalNumOfFilesToReceive:(long)numberOfFiles {
    for (id<Plugin> plugin in [_plugins allValues]) {
        if ([plugin respondsToSelector:@selector(willReceivePayload:totalNumOfFilesToReceive:)]) {
            [plugin willReceivePayload:payload totalNumOfFilesToReceive:numberOfFiles];
        }
    }
}

- (void)onReceivingPayload:(KDEFileTransferItem *)payload {
    for (id<Plugin> plugin in [_plugins allValues]) {
        if ([plugin respondsToSelector:@selector(onReceivingPayload:)]) {
            [plugin onReceivingPayload:payload];
        }
    }
}

- (void)onReceivingPayload:(KDEFileTransferItem *)payload
           failedWithError:(NSError *)error {
    for (id<Plugin> plugin in [_plugins allValues]) {
        if ([plugin respondsToSelector:@selector(onReceivingPayload:failedWithError:)]) {
            [plugin onReceivingPayload:payload failedWithError:error];
        }
    }
}

- (void)onPacketReceived:(NetworkPacket *)np {
    os_log_with_type(logger, self.debugLogLevel, "device on packet received");
    if ([np.type isEqualToString:NetworkPacketTypePair]) {
        os_log_with_type(logger, self.debugLogLevel, "Pair packet received");
        BOOL wantsPair=[np boolForKey:@"pair"];
        if (wantsPair==[self isPaired]) {
            os_log_with_type(logger, self.debugLogLevel, "already done, paired:%d",wantsPair);
            if (_pairStatus==Requested) {
                os_log_with_type(logger, self.debugLogLevel, "canceled by other peer");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPairingTimeout:) object:nil];
                });
                _pairStatus=NotPaired;
                if (deviceDelegate) {
                    [deviceDelegate onDevicePairRejected:self];
                }
            } else if (wantsPair) {
                [self acceptPairing];
            }
            return;
        }
        if (wantsPair) {
            os_log_with_type(logger, self.debugLogLevel, "pair request");
            if ((_pairStatus)==Requested) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPairingTimeout:) object:nil];
                });
                [self setAsPaired];
            }
            else{
                _pairStatus=RequestedByPeer;
                if (deviceDelegate) {
                    [deviceDelegate onDevicePairRequest:self];
                }
            }
        } else {
            //NSLog(@"unpair request");
            if (_pairStatus==Requested) {
                //NSLog(@"canceled by other peer");
                _pairStatus=NotPaired;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPairingTimeout:) object:nil];
                });
            } else if (_pairStatus==Paired) {
                // okay to call unpair directly because other is reachable
                [self unpair];
                if (deviceDelegate) {
                    [deviceDelegate onDeviceUnpaired:self];
                }
            }
        }
    } else if ([self isPaired]) {
        // TODO: Instead of looping through all the Obj-C plugins here, calls Plugin handling function elsewhere in Swift
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "received a plugin packet: %{public}@", np.type);
        for (id<Plugin> plugin in [_plugins allValues]) {
            [plugin onDevicePacketReceivedWithNp:np];
        }
        //[PluginsService goThroughHostPluginsForReceivingWithNp:np];
    } else {
        // old iOS implementations send battery request while the devices are unpaired
        os_log_with_type(logger, OS_LOG_TYPE_DEFAULT,
                         "not paired, ignore packet of %{public}@, unpair the device",
                         np.type);
        // remembered devices should have became paired, okay to call unpair.
        [self unpair];
    }
}

- (BOOL) isReachable
{
    // synchronize not very helpful
    return [_links count] != 0;
}

#pragma mark Pairing-related Functions
- (BOOL) isPaired
{
    return _pairStatus==Paired; // || _testDevice
}

- (BOOL) isPaireRequested
{
    return _pairStatus==Requested;
}

- (void) setAsPaired
{
    _pairStatus=Paired;
    //NSLog(@"paired with %@",_name);
    // Request and update battery status for a newly paired device
    if (deviceDelegate) {
        [deviceDelegate onDevicePairSuccess:self];
    }
    [self updateBatteryStatus];
}

- (void) requestPairing
{
    if (![self isReachable]) {
        os_log_with_type(logger, OS_LOG_TYPE_ERROR, "device failed:not reachable");
        return;
    }
    if (_pairStatus==Paired) {
        os_log_with_type(logger, OS_LOG_TYPE_DEFAULT, "device failed:already paired");
        return;
    }
    if (_pairStatus==Requested) {
        os_log_with_type(logger, OS_LOG_TYPE_DEFAULT, "device failed:already requested");
        return;
    }
    if (_pairStatus==RequestedByPeer) {
        os_log_with_type(logger, self.debugLogLevel, "device accept pair request");
    }
    else{
        os_log_with_type(logger, self.debugLogLevel, "device request pairing");
        _pairStatus=Requested;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(requestPairingTimeout:) withObject:nil afterDelay:kPairingTimeout];
        });
    }
    NetworkPacket* np=[NetworkPacket createPairPacket];
    [self sendPacket:np tag:PACKET_TAG_PAIR];
}

- (void)requestPairingTimeout:(id)sender {
    os_log_with_type(logger, OS_LOG_TYPE_ERROR, "device request pairing timeout");
    if (_pairStatus==Requested) {
        _pairStatus=NotPaired;
        os_log_with_type(logger, self.debugLogLevel, "pairing timeout");
        if (deviceDelegate) {
            [deviceDelegate onDevicePairTimeout:self];
        }
        // okay to call unpair directly because only invocation of this method
        // is scheduled when we initiate a pairing (and cancelled otherwise)
        // thus can't be a remembered or paired device.
        [self unpair];
    }
}

/// Change the status of the Device to unpaired WITHOUT sending out an unpair packet.
- (void)setAsUnpaired {
    _pairStatus=NotPaired;
}

- (void)unpair {
    os_log_with_type(logger, self.debugLogLevel, "device unpair");
    _pairStatus=NotPaired;

    NetworkPacket* np=[[NetworkPacket alloc] initWithType:NetworkPacketTypePair];
    [np setBool:false forKey:@"pair"];
    [self sendPacket:np tag:PACKET_TAG_UNPAIR];
}

- (void) acceptPairing
{
    os_log_with_type(logger, self.debugLogLevel, "device accepted pair request");
    NetworkPacket* np=[NetworkPacket createPairPacket];
    [self sendPacket:np tag:PACKET_TAG_PAIR];
}

#pragma mark Plugins-related Functions

- (void)updateBatteryStatus {
    if ((_pluginsEnableStatus[NetworkPacketTypeBatteryRequest] != nil)
        && (_pluginsEnableStatus[NetworkPacketTypeBatteryRequest])) {
        id<Plugin> plugin = [_plugins objectForKey:NetworkPacketTypeBatteryRequest];
        if ([plugin respondsToSelector:@selector(sendBatteryStatusRequest)]) {
            [plugin performSelector:@selector(sendBatteryStatusRequest)];
        }
        // For backward compatibility reasons, we should update the other device
        if ([plugin respondsToSelector:@selector(sendBatteryStatusOut)]) {
            [plugin performSelector:@selector(sendBatteryStatusOut)];
        }
    }
}

- (void) reloadPlugins
{
//    if (![self isReachable]) {
//        return;
//    }
    
    os_log_with_type(logger, self.debugLogLevel, "device reload plugins");
    [_plugins removeAllObjects];
    [_failedPlugins removeAllObjects];
    [_pluginsEnableStatus removeAllObjects];
    
    for (NSString* pluginID in _deviceInfo.incomingCapabilities) {
        if ([pluginID isEqualToString:NetworkPacketTypePing]) {
            [_plugins setObject:[[Ping alloc] initWithControlDevice:self] forKey:NetworkPacketTypePing];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypePing];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypeShare]) {
            [_plugins setObject:[[Share alloc] initWithControlDevice:self] forKey:NetworkPacketTypeShare];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeShare];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypeFindMyPhoneRequest]) {
            [_plugins setObject:[[FindMyPhone alloc] initWithControlDevice:self] forKey:NetworkPacketTypeFindMyPhoneRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeFindMyPhoneRequest];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypeBatteryRequest]) {
            [_plugins setObject:[[Battery alloc] initWithControlDevice:self] forKey:NetworkPacketTypeBatteryRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeBatteryRequest];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypeClipboard]) {
            [_plugins setObject:[[Clipboard alloc] initWithControlDevice:self] forKey:NetworkPacketTypeClipboard];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeClipboard];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypeMousePadRequest]) {
            [_plugins setObject:[[RemoteInput alloc] initWithControlDevice:self] forKey:NetworkPacketTypeMousePadRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeMousePadRequest];
            
        } else if ([pluginID isEqualToString:NetworkPacketTypePresenter]) {
            [_plugins setObject:[[Presenter alloc] initWithControlDevice:self] forKey:NetworkPacketTypePresenter];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypePresenter];
        }
    }
    
    // for the capabilities that are ONLY in the outgoing section of KDE Connect iOS
    for (NSString* pluginID in _deviceInfo.outgoingCapabilities) {
        if ([pluginID isEqualToString:NetworkPacketTypeRunCommand]) {
            [_plugins setObject:[[RunCommand alloc] initWithControlDevice:self] forKey:NetworkPacketTypeRunCommand];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPacketTypeRunCommand];
            
        }
    }
    
    
//    //NSLog(@"device reload plugins");
//    [_failedPlugins removeAllObjects];
//    PluginFactory* pluginFactory=[PluginFactory sharedInstance];
//    NSArray* pluginNames=[pluginFactory getAvailablePlugins];
//    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
//    pluginNames=[pluginNames sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
//    SettingsStore* _devSettings=[[SettingsStore alloc] initWithPath:_id];
//    for (NSString* pluginName in pluginNames) {
//        if ([_devSettings objectForKey:pluginName]!=nil && ![_devSettings boolForKey:pluginName]) {
//            [[_plugins objectForKey:pluginName] stop];
//            [_plugins removeObjectForKey:pluginName];
//            [_failedPlugins addObject:pluginName];
//            continue;
//        }
//        [_plugins removeObjectForKey:pluginName];
//        Plugin* plugin=[pluginFactory instantiatePluginForDevice:self pluginName:pluginName];
//        if (plugin)
//            [_plugins setValue:plugin forKey:pluginName];
//        else
//            [_failedPlugins addObject:pluginName];
//    }
}

//- (NSArray*) getPluginViews:(UIViewController*)vc
//{
//    NSMutableArray* views=[NSMutableArray arrayWithCapacity:1];
//    for (Plugin* plugin in [_plugins allValues]) {
//        UIView* view=[plugin getView:vc];
//        if (view) {
//            [views addObject:view];
//        }
//    }
//    return views;
//}

#pragma mark En/Decoding Methods
- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:_deviceInfo.id forKey:@"_id"];
    [coder encodeObject:_deviceInfo.name forKey:@"_name"];
    [coder encodeInteger:_deviceInfo.type forKey:@"_type"];
    [coder encodeInteger:_deviceInfo.protocolVersion forKey:@"_protocolVersion"];
    [coder encodeObject:_deviceInfo.incomingCapabilities forKey:@"_incomingCapabilities"];
    [coder encodeObject:_deviceInfo.outgoingCapabilities forKey:@"_outgoingCapabilities"];
    [coder encodeInteger:_pairStatus forKey:@"_pairStatus"];
    [coder encodeObject:_pluginsEnableStatus forKey:@"_pluginsEnableStatus"];
    [coder encodeFloat:_cursorSensitivity forKey:@"_cursorSensitivity"];
#if !TARGET_OS_OSX
    [coder encodeInteger:_hapticStyle forKey:@"_hapticStyle"];
#endif
    [coder encodeFloat:_pointerSensitivity forKey:@"_pointerSensitivity"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        NSString* id = [coder decodeObjectForKey:@"_id"];
        NSString* name = [coder decodeObjectForKey:@"_name"];
        NSInteger type = [coder decodeIntegerForKey:@"_type"];
        NSInteger protocolVersion = [coder decodeIntegerForKey:@"_protocolVersion"];
        NSArray<NSString*>* incomingCapabilities = [coder decodeArrayOfObjectsOfClass:[NSString class] forKey:@"_incomingCapabilities"];
        NSArray<NSString*>* outgoingCapabilities = [coder decodeArrayOfObjectsOfClass:[NSString class] forKey:@"_outgoingCapabilities"];
        SecCertificateRef cert = [[CertificateService shared] extractSavedCertOfRemoteDeviceWithDeviceId:id];
        _deviceInfo = [[DeviceInfo alloc] initWithId:id
                                                name:name
                                                type:type
                                                cert:cert
                                    protocolVersion:protocolVersion
                                incomingCapabilities:incomingCapabilities
                                outgoingCapabilities:outgoingCapabilities
        ];
        _pairStatus = [coder decodeIntegerForKey:@"_pairStatus"];
        _pluginsEnableStatus = (NSMutableDictionary*)[(NSDictionary*)[coder decodeDictionaryWithKeysOfClass:[NSString class] objectsOfClass:[NSNumber class] forKey:@"_pluginsEnableStatus"] mutableCopy];
        _cursorSensitivity = [coder decodeFloatForKey:@"_cursorSensitivity"];
#if !TARGET_OS_OSX
        _hapticStyle = [coder decodeIntegerForKey:@"_hapticStyle"];
#endif
        _pointerSensitivity = [coder decodeFloatForKey:@"_pointerSensitivity"];
        
        // To be set later in backgroundServices
        deviceDelegate = nil;
        
        // To be populated later
        _plugins = [NSMutableDictionary dictionary];
        _failedPlugins = [NSMutableArray array];
        _links = [NSMutableArray array];
        [self reloadPlugins];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
