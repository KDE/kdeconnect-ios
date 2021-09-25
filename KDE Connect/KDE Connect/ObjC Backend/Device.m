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
#define PAIR_TIMMER_TIMEOUT  10.0

@implementation Device

@synthesize _id;
@synthesize _name;
@synthesize _pairStatus;
@synthesize _protocolVersion;
@synthesize _type;
@synthesize _deviceDelegate;
@synthesize _links;
@synthesize _plugins;
@synthesize _failedPlugins;
@synthesize _incomingCapabilities;
@synthesize _outgoingCapabilities;
@synthesize _backgroundServiceDelegate;
//@synthesize _testDevice;

@synthesize _pluginsEnableStatus;
@synthesize _SHA256HashFormatted;

// Plugin-specific persistent data are stored in the Device object. Plugin objects contain runtime
// data only and are therefore NOT stored persistently
// Remote Input
@synthesize _cursorSensitivity;
@synthesize _hapticStyle;
// Presenter
@synthesize _pointerSensitivity;

// TODO: might want to remove this before public testing
//- (Device*) initTest
//{
//    if ((self=[super init])) {
//        _id=@"test-purpose-device";
//        _name=@"TestiPhone";
//        _type=Phone;
//        _deviceDelegate=nil;
//        // [self loadSetting];
//        _links=[NSMutableArray arrayWithCapacity:1];
//        _plugins=[NSMutableDictionary dictionaryWithCapacity:1];
//        _failedPlugins=[NSMutableArray arrayWithCapacity:1];
//
//        _testDevice = YES;
//        _pairStatus = Paired;
//    }
//    return self;
//}

- (Device*) init:(NSString*)deviceId setDelegate:(id)deviceDelegate
{
    if ((self=[super init])) {
        _id=deviceId;
        _type=Phone;
        _deviceDelegate=deviceDelegate;
        [self loadSetting];
        _links=[NSMutableArray arrayWithCapacity:1];
        _plugins=[NSMutableDictionary dictionaryWithCapacity:1];
        _failedPlugins=[NSMutableArray arrayWithCapacity:1];
        _pluginsEnableStatus = [NSMutableDictionary dictionary];
        _cursorSensitivity = 3.0;
        _hapticStyle = 0;
        _pointerSensitivity = 3.0;
        [self reloadPlugins];
    }
    return self;
}

- (Device*) init:(NetworkPackage*)np baselink:(BaseLink*)link setDelegate:(id)deviceDelegate
{
    if (self=[super init]) {
        _id=[np objectForKey:@"deviceId"];
        _type=[Device Str2Devicetype:[np objectForKey:@"deviceType"]];
        _name=[np objectForKey:@"deviceName"];
        _incomingCapabilities=[np objectForKey:@"incomingCapabilities"];
        _outgoingCapabilities=[np objectForKey:@"outgoingCapabilities"];
        _links=[NSMutableArray arrayWithCapacity:1];
        _plugins=[NSMutableDictionary dictionaryWithCapacity:1];
        _failedPlugins=[NSMutableArray arrayWithCapacity:1];
        _protocolVersion=[np integerForKey:@"protocolVersion"];
        _pluginsEnableStatus = [NSMutableDictionary dictionary];
        _deviceDelegate=deviceDelegate;
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
    _type=[Device Str2Devicetype:[np objectForKey:@"deviceType"]];
    _incomingCapabilities=[np objectForKey:@"incomingCapabilities"];
    _outgoingCapabilities=[np objectForKey:@"outgoingCapabilities"];
    //[self saveSetting];
    [Link set_linkDelegate:self];
    if ([_links count]==1) {
        NSLog(@"one link available");
        if (_deviceDelegate) {
            [_deviceDelegate onDeviceReachableStatusChanged:self];
        }
        // If device is just online with its first link, ask for its battery status
        if ((_pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST] != nil) && (_pluginsEnableStatus[PACKAGE_TYPE_BATTERY_REQUEST])) {
            [[_plugins objectForKey:PACKAGE_TYPE_BATTERY] sendBatteryStatusRequest];
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
        if (_deviceDelegate) {
            [_deviceDelegate onDeviceReachableStatusChanged:self];
            // No, we don't want to remove the plugins because IF the device is coming back online later, we want to still have to ready
            //[_plugins removeAllObjects];
            //[_failedPlugins removeAllObjects];
        }
    }
    if (_deviceDelegate) {
        [_deviceDelegate onLinkDestroyed:link];
    }
}

- (BOOL) sendPackage:(NetworkPackage *)np tag:(long)tag
{
    NSLog(@"device send package");
    if (![[np _Type] isEqualToString:PACKAGE_TYPE_PAIR]) {
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
        [(Share *)[_plugins objectForKey:PACKAGE_TYPE_SHARE] sendSinglePayload];
    }
}

- (void) onPackageReceived:(NetworkPackage*)np
{
    NSLog(@"device on package received");
    if ([[np _Type] isEqualToString:PACKAGE_TYPE_PAIR]) {
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
                if (_deviceDelegate) {
                    [_deviceDelegate onDevicePairRejected:self];
                }
            }
            else if(wantsPair){
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
                if (_deviceDelegate) {
                    [_deviceDelegate onDevicePairRequest:self];
                }
            }
        }
        else{
            //NSLog(@"unpair request");
            PairStatus prevPairStatus=_pairStatus;
            _pairStatus=NotPaired;
            if (prevPairStatus==Requested) {
                //NSLog(@"canceled by other peer");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestPairingTimeout:) object:nil];
                });
            }else if (prevPairStatus==Paired){
                [self unpair];
                //[_backgroundServiceDelegate unpairFromBackgroundServiceInstance:[self _id]];
            }
        }
    }else if ([self isPaired]){
        //TODO: Instead of looping through all the Obj-C plugins here, calls Plugin handling functon elsewhere in Swift
        NSLog(@"recieved a plugin package :%@",[np _Type]);
        for (id<Plugin> plugin in [_plugins allValues]) {
            [plugin onDevicePackageReceivedWithNp:np];
        }
        //[PluginsService goThroughHostPluginsForReceivingWithNp:np];
    }else{
        NSLog(@"not paired, ignore packages, unpair the device");
        [self unpair];
        //[_backgroundServiceDelegate unpairFromBackgroundServiceInstance:[self _id]];
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
    if (_deviceDelegate) {
        [_deviceDelegate onDevicePairSuccess:self];
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
            [self performSelector:@selector(requestPairingTimeout:) withObject:nil afterDelay:PAIR_TIMMER_TIMEOUT];
        });
    }
    NetworkPackage* np=[NetworkPackage createPairPackage];
    [self sendPackage:np tag:PACKAGE_TAG_PAIR];
}

- (void) requestPairingTimeout:(id)sender
{
    NSLog(@"device request pairing timeout");
    if (_pairStatus==Requested) {
        _pairStatus=NotPaired;
        NSLog(@"pairing timeout");
        if (_deviceDelegate) {
            [_deviceDelegate onDevicePairTimeout:self];
        }
        [self unpair];
        //[_backgroundServiceDelegate unpairFromBackgroundServiceInstance:[self _id]];
    }
}

// If we JUST want to change the status of the Device to unpaired WITHOUT sending out an unpair packet
- (void) justChangeStatusToUnpaired {
    _pairStatus=NotPaired;
}

- (void) unpair
{
    NSLog(@"device unpair");
    _pairStatus=NotPaired;
    [_backgroundServiceDelegate currDeviceDetailsViewDisconnectedFromRemote:[self _id]];
    [_backgroundServiceDelegate removeDeviceFromArraysWithDeviceId:[self _id]];
    // How do we use same protocol from
    NetworkPackage* np=[[NetworkPackage alloc] initWithType:PACKAGE_TYPE_PAIR];
    [np setBool:false forKey:@"pair"];
    [self sendPackage:np tag:PACKAGE_TAG_UNPAIR];
}

- (void) acceptPairing
{
    NSLog(@"device accepted pair request");
    NetworkPackage* np=[NetworkPackage createPairPackage];
    [self sendPackage:np tag:PACKAGE_TAG_PAIR];
}

- (void) rejectPairing
{
    NSLog(@"device rejected pair request ");
    [self unpair];
    //[_backgroundServiceDelegate unpairFromBackgroundServiceInstance:[self _id]];
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
        if ([pluginID isEqualToString:PACKAGE_TYPE_PING]) {
            [_plugins setObject:[[Ping alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_PING];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_PING];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_SHARE]) {
            [_plugins setObject:[[Share alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_SHARE];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_SHARE];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_FINDMYPHONE_REQUEST]) {
            [_plugins setObject:[[FindMyPhone alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_FINDMYPHONE_REQUEST];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_FINDMYPHONE_REQUEST];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_BATTERY_REQUEST]) {
            [_plugins setObject:[[Battery alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_BATTERY_REQUEST];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_BATTERY_REQUEST];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_CLIPBOARD]) {
            [_plugins setObject:[[Clipboard alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_CLIPBOARD];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_CLIPBOARD];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_MOUSEPAD_REQUEST]) {
            [_plugins setObject:[[RemoteInput alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_MOUSEPAD_REQUEST];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_MOUSEPAD_REQUEST];
            
        }
    }
    
    // for the capabilities that are ONLY in the outgoing section of KDE Connect iOS
    for (NSString* pluginID in _outgoingCapabilities) {
        if ([pluginID isEqualToString:PACKAGE_TYPE_PRESENTER]) {
            [_plugins setObject:[[Presenter alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_PRESENTER];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_PRESENTER];
            
        } else if ([pluginID isEqualToString:PACKAGE_TYPE_RUNCOMMAND]) { // check DL360's id packet to  see if this is indeed the case
            [_plugins setObject:[[RunCommand alloc] initWithControlDevice:self] forKey:PACKAGE_TYPE_RUNCOMMAND];
            [_pluginsEnableStatus setValue:@TRUE forKey:PACKAGE_TYPE_RUNCOMMAND];
            
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
+ (NSString*)Devicetype2Str:(DeviceType)type
{
    switch (type) {
        case Desktop:
            return @"desktop";
        case Laptop:
            return @"laptop";
        case Phone:
            return @"phone";
        case Tablet:
            return @"tablet";
        default:
            return @"unknown";
    }
}
+ (DeviceType)Str2Devicetype:(NSString*)str
{
    if ([str isEqualToString:@"desktop"]) {
        return Desktop;
    }
    if ([str isEqualToString:@"laptop"]) {
        return Laptop;
    }
    if ([str isEqualToString:@"phone"]) {
        return Phone;
    }
    if ([str isEqualToString:@"tablet"]) {
        return Tablet;
    }
    return Unknown;
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
        
        // To be set later in LanLink's didReceiveTrust
        _SHA256HashFormatted = @"";
        
        // To be set later in backgroundServices
        _deviceDelegate = nil;
        _backgroundServiceDelegate = nil;
        
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
