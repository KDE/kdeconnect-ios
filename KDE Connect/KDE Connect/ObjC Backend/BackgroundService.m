/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//Copyright 2/5/14  YANG Qiao yangqiao0505@me.com
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

#import "BackgroundService.h"
#import "LanLinkProvider.h"
#import "LoopbackLinkProvider.h"
#import "KDE_Connect-Swift.h"
@import os.log;

@interface BackgroundService () <NetworkChangeMonitorDelegate> {
    NSMutableDictionary<NSString *, Device *> *_devices;
    NSMutableDictionary<NSString *, NSData *> *_settings;
    os_log_t logger;
}

@property(nonatomic) NetworkChangeMonitor *networkChangeMonitor;
@property(nonatomic) NSMutableArray<BaseLinkProvider *> *_linkProviders;
@property(nonatomic) NSMutableArray<Device *> *visibleDevices;
@property(nonatomic, assign) ConnectedDevicesViewModel *_backgroundServiceDelegate;
@property(nonatomic, assign) CertificateService *_certificateService;

@end

@implementation BackgroundService

@synthesize _backgroundServiceDelegate;
@synthesize _certificateService;
- (void)setDevices:(NSDictionary<NSString *, Device *> *)devices
{
    _devices = [[NSMutableDictionary alloc] initWithDictionary:devices];
}
@synthesize _linkProviders;
- (void)setSettings:(NSDictionary<NSString *, NSData *> *)settings
{
    _settings = [[NSMutableDictionary alloc] initWithDictionary:settings];
}

//+ (id) sharedInstance
//{
//    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
//        return [[self alloc] init];
//    });
//}
//
//+ (id) allocWithZone:(struct _NSZone *)zone
//{
//    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
//        return [super allocWithZone:zone];
//    });
//}
//
//- (id)copyWithZone:(NSZone *)zone;{
//    return self;
//}

- (BackgroundService*) initWithconnectedDeviceViewModel:(ConnectedDevicesViewModel*)connectedDeviceViewModel certificateService:(CertificateService*) certificateService
{
    if ((self=[super init])) {
        logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                                        NSStringFromClass([self class]).UTF8String);
        // MARK: comment this out for production, this is for debugging, for clearing the saved devices dictionary in UserDefaults
        //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedDevices"];
        //[_certificateService deleteAllItemsFromKeychain];
        //NSLog(@"Host identity deleted from keychain with exit code %i", [KeychainOperations deleteHostCertificateFromKeychain]);
        
        _linkProviders=[NSMutableArray arrayWithCapacity:1];
        _devices=[NSMutableDictionary dictionaryWithCapacity:1];
        _visibleDevices=[NSMutableArray arrayWithCapacity:1];
        _settings=[NSMutableDictionary dictionaryWithCapacity:1];
       
       //[[SettingsStore alloc] initWithPath:KDECONNECT_REMEMBERED_DEV_FILE_PATH];
        
        _backgroundServiceDelegate = connectedDeviceViewModel;
        _certificateService = certificateService;
        
        _networkChangeMonitor = [[NetworkChangeMonitor alloc] init];
        _networkChangeMonitor.delegate = self;
        
        //[[NSUserDefaults standardUserDefaults] registerDefaults:_settings];
        //[[NSUserDefaults standardUserDefaults] synchronize];
        [self loadRememberedDevices];
        [self registerLinkProviders];
        //[PluginFactory sharedInstance];
        
//#ifdef DEBUG
//        NSString* deviceId = @"test-purpose-device";
//        Device* device=[[Device alloc] initTest];
//        [_devices setObject:device forKey:deviceId];
//#endif
        // [_visibleDevices addObject:device];
    }
    return self;
}

- (os_log_type_t)debugLogLevel {
    if ([KdeConnectSettings shared].isDebuggingDiscovery) {
        return OS_LOG_TYPE_INFO;
    }
    return OS_LOG_TYPE_DEBUG;
}

- (void) loadRememberedDevices
{
    NSMutableDictionary<NSString *, Device *> *savedDevices = [NSMutableDictionary dictionary];
   
    NSDictionary* tempDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"savedDevices"];
    if (tempDic != nil) {
        for (NSString* deviceId in [tempDic allKeys]) {
            NSData* deviceData = tempDic[deviceId];
            [_settings setObject:deviceData forKey:deviceId]; // do this here since Settings holds exclusively encoded Data, NOT Device objects, otherwise will throw "non-property list" error upon trying to save to UserDefaults
            NSError* error;
            Device* device = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[Device class], [NSString class], [NSArray class], nil] fromData:deviceData error:&error];
            os_log_with_type(logger, OS_LOG_TYPE_DEFAULT, "device with pair status %lu is decoded from UserDefaults as: %{public}@. Errors: %{public}@", [device _pairStatus], device, error);
            if ([device _pairStatus] == Paired) {
                device.deviceDelegate = self;
                //[device reloadPlugins];
                [savedDevices setObject:device forKey:deviceId];
            } else {
                os_log_with_type(logger, self.debugLogLevel, "Not loading device above since it's previous status is NOT paired.");
            }
        }
    }
    
    os_log_with_type(logger, self.debugLogLevel, "%{public}@", savedDevices);

    for (Device* device in [savedDevices allValues]) {
        //Device* device=[[Device alloc] init:deviceId setDelegate:self];
        [_devices setObject:device forKey:device._deviceInfo.id];
        //[_settings setObject:device forKey:device._deviceInfo.id];
    }
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onDevicesListUpdatedWithDevicesListsMap:[self getDevicesLists]];
    }
}

- (void) registerLinkProviders
{
    os_log_with_type(logger, self.debugLogLevel, "bg register linkproviders");
    //LoopbackLinkProvider* linkProvider=[[LoopbackLinkProvider alloc] initWithDelegate:self];
    LanLinkProvider* linkProvider=[[LanLinkProvider alloc] initWithDelegate:self certificateService:_certificateService];
    [_linkProviders addObject:linkProvider];
}

- (void) startDiscovery
{
    [_networkChangeMonitor startMonitoring];
    os_log_with_type(logger, self.debugLogLevel, "bg start Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onStart];
    }
}

- (void) refreshDiscovery
{
    os_log_with_type(logger, self.debugLogLevel, "bg refresh Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onRefresh];
    }
}

- (void) stopDiscovery
{
    [_networkChangeMonitor stopMonitoring];
    os_log_with_type(logger, self.debugLogLevel, "bg stop Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onStop];
    }
}

- (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *) getDevicesLists
{
    os_log_with_type(logger, self.debugLogLevel, "bg get devices lists");
    NSMutableDictionary* _visibleDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary* _connectedDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary* _rememberedDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    for (Device *device in [_devices allValues]) {
        if ((![device isReachable]) && [device isPaired]) {
            [_rememberedDevicesList setValue:device._deviceInfo.name forKey:device._deviceInfo.id];
            
        } else if([device isPaired] && [device isReachable]){
            //[device reloadPlugins];
            [_connectedDevicesList setValue:device._deviceInfo.name forKey:device._deviceInfo.id];
            //TODO: move this to a different thread maybe, and also in Swift
            //[device reloadPlugins];
        } else if ((![device isPaired]) && [device isReachable]) {
            [_visibleDevicesList setValue:device._deviceInfo.name forKey:device._deviceInfo.id];
        }
    }
    NSDictionary* list=[NSDictionary dictionaryWithObjectsAndKeys:
                        _connectedDevicesList,  @"connected",
                        _visibleDevicesList,    @"visible",
                        _rememberedDevicesList, @"remembered",nil];
    return list;
}

- (void) pairDevice:(NSString*)deviceId;
{
    os_log_with_type(logger, self.debugLogLevel, "bg pair device");
    Device* device=[_devices valueForKey:deviceId];
    if ([device isReachable]) {
        [device requestPairing];
    }
}

/// @remark This should be the ONLY method used for unpairing Devices, DO NOT call the device's own unpair() method as it DOES NOT remove the device from the Arrays like this one does. For other files already using _backgroundServiceDelegate AKA ConnectedDevicesViewModel, use unpairFromBackgroundServiceInstance() in that. That's the same thing as calling this
- (void)unpairDevice:(NSString *)deviceId {
    os_log_with_type(logger, self.debugLogLevel, "bg unpair device");
    Device* device=[_devices valueForKey:deviceId];
    if ([device isReachable]) {
        [device unpair];
    } else {
        // we'll also be calling this to unpair remembered (unReachable) devices
        [device setAsUnpaired];
        [_devices removeObjectForKey:deviceId];
    }
    [self onDeviceUnpaired:device];
}

- (void)refreshVisibleDeviceList {
    NSMutableArray<Device *> *newVisibleDevices = [[NSMutableArray alloc] init];
    
    for (Device* device in [_devices allValues]) {
        if ([device isReachable]) {
            [newVisibleDevices addObject:device];
        }
    }
    BOOL updated;
    @synchronized (_visibleDevices) {
        updated = ![newVisibleDevices isEqualToArray:_visibleDevices];
        os_log_with_type(logger, self.debugLogLevel,
                         "bg on device refresh visible device list, %{public}@",
                         updated ? @"UPDATED" : @"NO UPDATE");
        if (updated) {
            [_visibleDevices setArray:newVisibleDevices];
        }
    }
    if (_backgroundServiceDelegate && updated) {
        [_backgroundServiceDelegate onDevicesListUpdatedWithDevicesListsMap:[self getDevicesLists]];
    }
}

#pragma mark reactions
- (void) onDeviceReachableStatusChanged:(Device*)device
{   // Gets called by Device when links == 0 aka device becomes unreachable/offline/becomes "remembered device"
    os_log_with_type(logger, self.debugLogLevel, "bg on device reachable status changed");
    if (![device isReachable]) {
        os_log_with_type(logger, self.debugLogLevel, "bg device not reachable");
        os_log_with_type(logger, OS_LOG_TYPE_INFO, "%{mask.hash}@", device._deviceInfo.id);
        //[_backgroundServiceDelegate currDeviceDetailsViewDisconnectedFromRemote:device._deviceInfo.id];
    }
    if (![device isPaired] && ![device isReachable]) {
        [_devices removeObjectForKey:device._deviceInfo.id];
        os_log_with_type(logger, self.debugLogLevel, "bg destroy device");
    }
    //[self refreshDiscovery];
    [self refreshVisibleDeviceList]; // might want to reverse this after figuring out why refreshDiscovery is causing Plugins to disappear
}

- (void) onNetworkChange
{
    os_log_with_type(logger, self.debugLogLevel, "bg on network change");
    for (BaseLinkProvider* lp in _linkProviders){
        [lp onNetworkChange];
    }
}

- (void) onConnectionReceived:(BaseLink *)link
{
    os_log_with_type(logger, self.debugLogLevel, "bg on connection received");
    NSString* deviceId=[link _deviceInfo].id;
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "Device discovered: %{mask.hash}@",deviceId);
    if ([_devices valueForKey:deviceId]) {
        os_log_with_type(logger, self.debugLogLevel, "known device");
        Device* device=[_devices objectForKey:deviceId];
        [device addLink:link];
        [device updateInfo:[link _deviceInfo]];
        [_backgroundServiceDelegate onDevicesListUpdatedWithDevicesListsMap:[self getDevicesLists]];
    }
    else{
        os_log_with_type(logger, OS_LOG_TYPE_INFO,
                         "new device from network packet: %{public}@",
                         deviceId);
        Device *device=[[Device alloc] initWithLink:link delegate:self];
        [_devices setObject:device forKey:deviceId];
        [self refreshVisibleDeviceList];
    }
}

- (void)onDeviceIdentityUpdatePacketReceived:(NetworkPacket *)np {
    NSString *deviceID = [np objectForKey:@"deviceId"];
    os_log_with_type(logger, self.debugLogLevel,
                     "on identity update for %{mask.hash}@ received",
                     deviceID);
    Device *device = [_devices objectForKey:deviceID];
    if (device) {
        [device updateInfo:[DeviceInfo fromNetworkPacket:np]];
        [_backgroundServiceDelegate onDevicesListUpdatedWithDevicesListsMap:[self getDevicesLists]];
    } else {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT,
                         "missing device %{mask.hash}@ to update for",
                         deviceID);
    }
}

- (void) onLinkDestroyed:(BaseLink *)link
{
    os_log_with_type(logger, self.debugLogLevel, "bg on link destroyed");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onLinkDestroyed:link];
    }
}

- (void) onDevicePairRequest:(Device *)device
{
    os_log_with_type(logger, self.debugLogLevel, "bg on device pair request");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairRequest:device._deviceInfo.id];
    }
}

- (void) onDevicePairTimeout:(Device*)device
{
    os_log_with_type(logger, self.debugLogLevel, "bg on device pair timeout");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairTimeout:device._deviceInfo.id];
    }
    [_settings removeObjectForKey:device._deviceInfo.id];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
}

- (void) onDevicePairSuccess:(Device*)device
{
    //NSLog(@"%lu", [device _type]);
    os_log_with_type(logger, self.debugLogLevel, "bg on device pair success");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairSuccess:device._deviceInfo.id];
    }
    //[device setAsPaired]; is already called in the caller of this method
    NSError* error;
    NSData* deviceData = [NSKeyedArchiver archivedDataWithRootObject:device requiringSecureCoding:YES error:&error];
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "device object with pair status %lu encoded into UserDefaults as: %{public}@ with error: %{public}@", [device _pairStatus], deviceData, error);
    [_settings setValue:deviceData forKey:device._deviceInfo.id]; //[device _name]
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
}

- (void) onDevicePairRejected:(Device*)device
{
    os_log_with_type(logger, self.debugLogLevel, "bg on device pair rejected");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairRejected:device._deviceInfo.id];
    }
    [_settings removeObjectForKey:device._deviceInfo.id];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
}

- (void)onDeviceUnpaired:(Device *)device {
    NSString *deviceId = device._deviceInfo.id;
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "bg on device unpair %{mask.hash}@", deviceId);
    [_settings removeObjectForKey:deviceId];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
    device._SHA256HashFormatted = nil;
    BOOL status = [_certificateService deleteRemoteDeviceSavedCertWithDeviceId:deviceId];
    os_log_with_type(logger, OS_LOG_TYPE_INFO, "Device remove, stored cert also removed with status %d", status);
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onDevicesListUpdatedWithDevicesListsMap:[self getDevicesLists]];
    }
}

- (void) reloadAllPlugins
{
    for (Device* device in _devices) { //_visibleDevices
        [device reloadPlugins];
    }
}

@end

