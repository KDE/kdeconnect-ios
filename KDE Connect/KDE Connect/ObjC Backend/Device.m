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
static const NSTimeInterval kPairingTimeout = 30.0;

@implementation Device {
    NSMutableDictionary<NetworkPackageType, id<Plugin>> *_plugins;
    NSMutableDictionary<NetworkPackageType, NSNumber *> *_pluginsEnableStatus;
}

@synthesize _id;
@synthesize _name;
@synthesize _pairStatus;
@synthesize _protocolVersion;
@synthesize _type;
@synthesize deviceDelegate;
@synthesize _links;
- (void)setPlugins:(NSDictionary<NetworkPackageType, NSNumber *> *)plugins
{
    _plugins = [[NSMutableDictionary alloc] initWithDictionary:plugins];
}
@synthesize _failedPlugins;
@synthesize _incomingCapabilities;
@synthesize _outgoingCapabilities;
//@synthesize _testDevice;

- (void)setPluginsEnableStatus:(NSDictionary<NetworkPackageType, NSNumber *> *)pluginsEnableStatus
{
    _pluginsEnableStatus = [[NSMutableDictionary alloc] initWithDictionary:pluginsEnableStatus];
}
@synthesize _SHA256HashFormatted;

// TODO: plugins should be saving their own preferences
// Plugin-specific persistent data are stored in the Device object. Plugin objects contain runtime
// data only and are therefore NOT stored persistently
// Remote Input
@synthesize _cursorSensitivity;
// Presenter
@synthesize _pointerSensitivity;

- (Device*) init:(NetworkPackage*)np baselink:(BaseLink*)link setDelegate:(id)deviceDelegate
{
    if (self=[super init]) {
        _id=[np objectForKey:@"deviceId"];
        _type=[Device Str2DeviceType:[np objectForKey:@"deviceType"]];
        _name=[np objectForKey:@"deviceName"];
        _incomingCapabilities=[np objectForKey:@"incomingCapabilities"];
        _outgoingCapabilities=[np objectForKey:@"outgoingCapabilities"];
        _links=[NSMutableArray arrayWithCapacity:1];
        _plugins=[NSMutableDictionary dictionaryWithCapacity:1];
        _failedPlugins=[NSMutableArray arrayWithCapacity:1];
        _protocolVersion=[np integerForKey:@"protocolVersion"];
        _pluginsEnableStatus = [NSMutableDictionary dictionary];
        self.deviceDelegate=deviceDelegate;
        _cursorSensitivity = 3.0;
        _hapticStyle = 0;
        _pointerSensitivity = 3.0;
        [self addLink:np baseLink:link];
        [self reloadPlugins];
    }
    return self;
}

- (NSInteger) compareProtocolVersion
{
    return 0;
}

#pragma mark Link-related Functions

- (void) addLink:(NetworkPackage*)np baseLink:(BaseLink*)Link
{
    NSLog(@"add link to %@",_id);
    if (_protocolVersion!=[np integerForKey:@"protocolVersion"]) {
        NSLog(@"using different protocol version");
    }
    [_links addObject:Link];
    _id=[np objectForKey:@"deviceId"];
    _name=[np objectForKey:@"deviceName"];
    _type=[Device Str2DeviceType:[np objectForKey:@"deviceType"]];
    _incomingCapabilities=[np objectForKey:@"incomingCapabilities"];
    _outgoingCapabilities=[np objectForKey:@"outgoingCapabilities"];
    //[self saveSetting];
    [Link set_linkDelegate:self];
    if ([_links count]==1) {
        NSLog(@"one link available");
        if (deviceDelegate) {
            [deviceDelegate onDeviceReachableStatusChanged:self];
        }
        // If device is just online with its first link, ask for its battery status
        if ((_pluginsEnableStatus[NetworkPackageTypeBatteryRequest] != nil)
            && (_pluginsEnableStatus[NetworkPackageTypeBatteryRequest])
            && ([[_plugins objectForKey:NetworkPackageTypeBatteryRequest] respondsToSelector:@selector(sendBatteryStatusRequest)])) {
            [[_plugins objectForKey:NetworkPackageTypeBatteryRequest] performSelector:@selector(sendBatteryStatusRequest)];
        }
    }
}
// FIXME: This ain't it, doesn't get called when connection is cut (e.g wifi off) from the remote device
- (void) onLinkDestroyed:(BaseLink *)link
{
    NSLog(@"device on link destroyed");
    [_links removeObject:link];
    NSLog(@"remove link ; %lu remaining", (unsigned long)[_links count]);
    if ([_links count]==0) {
        NSLog(@"no available link");
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

- (BOOL) sendPackage:(NetworkPackage *)np tag:(long)tag
{
    NSLog(@"device send package");
    // TODO: 2 branch has identical code
    if (![np.type isEqualToString:NetworkPackageTypePair]) {
        for (BaseLink* link in _links) {
            if ([link sendPackage:np tag:tag]) {
                return true;
            }
        }
    }
    else{
        for (BaseLink* link in _links) {
            if ([link sendPackage:np tag:tag]) {
                return true;
            }
        }
    }
    return false;
}

- (void) onSendSuccess:(long)tag
{
    NSLog(@"device on send success");
    if (tag==PACKAGE_TAG_PAIR) {
        if (_pairStatus==RequestedByPeer) {
            [self setAsPaired];
        }
    } else if (tag == PACKAGE_TAG_PAYLOAD){
        /* for (Plugin* plugin in [_plugins allValues]) {
//            [plugin sentPercentage:100 tag:tag];
        } */
        NSLog(@"Last payload sent successfully, sending next one");
        [(Share *)[_plugins objectForKey:NetworkPackageTypeShare] sendSinglePayload];
    }
}

- (void)onPackageReceived:(NetworkPackage *)np {
    NSLog(@"device on package received");
    if ([np.type isEqualToString:NetworkPackageTypePair]) {
        NSLog(@"Pair package received");
        BOOL wantsPair=[np boolForKey:@"pair"];
        if (wantsPair==[self isPaired]) {
            NSLog(@"already done, paired:%d",wantsPair);
            if (_pairStatus==Requested) {
                NSLog(@"canceled by other peer");
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
            NSLog(@"pair request");
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
        NSLog(@"received a plugin package: %@", np.type);
        for (id<Plugin> plugin in [_plugins allValues]) {
            [plugin onDevicePackageReceivedWithNp:np];
        }
        //[PluginsService goThroughHostPluginsForReceivingWithNp:np];
    } else {
        NSLog(@"not paired, ignore packages, unpair the device");
        // remembered devices should have became paired, okay to call unpair.
        [self unpair];
    }
}

- (BOOL) isReachable
{
    return [_links count]!=0; // || _testDevice
}

- (void) loadSetting
{
}

- (void) saveSetting
{
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
    [self saveSetting];
    if (deviceDelegate) {
        [deviceDelegate onDevicePairSuccess:self];
    }
    // for (BaseLink* link in _links) {
    // }
}

- (void) requestPairing
{
    if (![self isReachable]) {
        NSLog(@"device failed:not reachable");
        return;
    }
    if (_pairStatus==Paired) {
        NSLog(@"device failed:already paired");
        return;
    }
    if (_pairStatus==Requested) {
        NSLog(@"device failed:already requested");
        return;
    }
    if (_pairStatus==RequestedByPeer) {
        NSLog(@"device accept pair request");
    }
    else{
        NSLog(@"device request pairing");
        _pairStatus=Requested;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(requestPairingTimeout:) withObject:nil afterDelay:kPairingTimeout];
        });
    }
    NetworkPackage* np=[NetworkPackage createPairPackage];
    [self sendPackage:np tag:PACKAGE_TAG_PAIR];
}

- (void)requestPairingTimeout:(id)sender {
    NSLog(@"device request pairing timeout");
    if (_pairStatus==Requested) {
        _pairStatus=NotPaired;
        NSLog(@"pairing timeout");
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
    NSLog(@"device unpair");
    _pairStatus=NotPaired;

    NetworkPackage* np=[[NetworkPackage alloc] initWithType:NetworkPackageTypePair];
    [np setBool:false forKey:@"pair"];
    [self sendPackage:np tag:PACKAGE_TAG_UNPAIR];
}

- (void) acceptPairing
{
    NSLog(@"device accepted pair request");
    NetworkPackage* np=[NetworkPackage createPairPackage];
    [self sendPackage:np tag:PACKAGE_TAG_PAIR];
}

#pragma mark Plugins-related Functions
- (void) reloadPlugins
{
//    if (![self isReachable]) {
//        return;
//    }
    
    NSLog(@"device reload plugins");
    [_plugins removeAllObjects];
    [_failedPlugins removeAllObjects];
    [_pluginsEnableStatus removeAllObjects];
    
    for (NSString* pluginID in _incomingCapabilities) {
        if ([pluginID isEqualToString:NetworkPackageTypePing]) {
            [_plugins setObject:[[Ping alloc] initWithControlDevice:self] forKey:NetworkPackageTypePing];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypePing];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypeShare]) {
            [_plugins setObject:[[Share alloc] initWithControlDevice:self] forKey:NetworkPackageTypeShare];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeShare];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypeFindMyPhoneRequest]) {
            [_plugins setObject:[[FindMyPhone alloc] initWithControlDevice:self] forKey:NetworkPackageTypeFindMyPhoneRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeFindMyPhoneRequest];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypeBatteryRequest]) {
            [_plugins setObject:[[Battery alloc] initWithControlDevice:self] forKey:NetworkPackageTypeBatteryRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeBatteryRequest];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypeClipboard]) {
            [_plugins setObject:[[Clipboard alloc] initWithControlDevice:self] forKey:NetworkPackageTypeClipboard];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeClipboard];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypeMousePadRequest]) {
            [_plugins setObject:[[RemoteInput alloc] initWithControlDevice:self] forKey:NetworkPackageTypeMousePadRequest];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeMousePadRequest];
            
        } else if ([pluginID isEqualToString:NetworkPackageTypePresenter]) {
            [_plugins setObject:[[Presenter alloc] initWithControlDevice:self] forKey:NetworkPackageTypePresenter];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypePresenter];
        }
    }
    
    // for the capabilities that are ONLY in the outgoing section of KDE Connect iOS
    for (NSString* pluginID in _outgoingCapabilities) {
        if ([pluginID isEqualToString:NetworkPackageTypeRunCommand]) {
            [_plugins setObject:[[RunCommand alloc] initWithControlDevice:self] forKey:NetworkPackageTypeRunCommand];
            [_pluginsEnableStatus setValue:@TRUE forKey:NetworkPackageTypeRunCommand];
            
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

#pragma mark enum tools
+ (NSString*)DeviceType2Str:(DeviceType)type
{
    switch (type) {
        case DeviceTypeDesktop:
            return @"desktop";
        case DeviceTypeLaptop:
            return @"laptop";
        case DeviceTypePhone:
            return @"phone";
        case DeviceTypeTablet:
            return @"tablet";
        case DeviceTypeTv:
            return @"tv";
        case DeviceTypeUnknown:
            return @"unknown";
    }
}
+ (DeviceType)Str2DeviceType:(NSString*)str
{
    if ([str isEqualToString:@"desktop"]) {
        return DeviceTypeDesktop;
    }
    if ([str isEqualToString:@"laptop"]) {
        return DeviceTypeLaptop;
    }
    if ([str isEqualToString:@"phone"]) {
        return DeviceTypePhone;
    }
    if ([str isEqualToString:@"tablet"]) {
        return DeviceTypeTablet;
    }
    if ([str isEqualToString:@"tv"]) {
        return DeviceTypeTv;
    }
    return DeviceTypeUnknown;
}

#pragma mark En/Decoding Methods
- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:_id forKey:@"_id"];
    [coder encodeObject:_name forKey:@"_name"];
    [coder encodeInteger:_type forKey:@"_type"];
    [coder encodeInteger:_protocolVersion forKey:@"_protocolVersion"];
    [coder encodeInteger:_pairStatus forKey:@"_pairStatus"];
    [coder encodeObject:_incomingCapabilities forKey:@"_incomingCapabilities"];
    [coder encodeObject:_outgoingCapabilities forKey:@"_outgoingCapabilities"];
    [coder encodeObject:_pluginsEnableStatus forKey:@"_pluginsEnableStatus"];
    [coder encodeFloat:_cursorSensitivity forKey:@"_cursorSensitivity"];
    [coder encodeInteger:_hapticStyle forKey:@"_hapticStyle"];
    [coder encodeFloat:_pointerSensitivity forKey:@"_pointerSensitivity"];
    [coder encodeObject:_SHA256HashFormatted forKey:@"_SHA256HashFormatted"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        _id = [coder decodeObjectForKey:@"_id"];
        _name = [coder decodeObjectForKey:@"_name"];
        _type = [coder decodeIntegerForKey:@"_type"];
        _protocolVersion = [coder decodeIntegerForKey:@"_protocolVersion"];
        _pairStatus = [coder decodeIntegerForKey:@"_pairStatus"];
        _incomingCapabilities = [coder decodeArrayOfObjectsOfClass:[NSString class] forKey:@"_incomingCapabilities"];
        _outgoingCapabilities = [coder decodeArrayOfObjectsOfClass:[NSString class] forKey:@"_outgoingCapabilities"];
        _pluginsEnableStatus = (NSMutableDictionary*)[(NSDictionary*)[coder decodeDictionaryWithKeysOfClass:[NSString class] objectsOfClass:[NSNumber class] forKey:@"_pluginsEnableStatus"] mutableCopy];
        _cursorSensitivity = [coder decodeFloatForKey:@"_cursorSensitivity"];
        _hapticStyle = [coder decodeIntegerForKey:@"_hapticStyle"];
        _pointerSensitivity = [coder decodeFloatForKey:@"_pointerSensitivity"];
        _SHA256HashFormatted = [coder decodeObjectForKey:@"_SHA256HashFormatted"];
        
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
