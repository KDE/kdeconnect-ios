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
//#import "SettingsStore.h"
//#import "PluginFactory.h"
//#import "KeychainItemWrapper.h"

@interface BackgroundService()
@property(nonatomic)NSMutableArray* _linkProviders;
//@property(nonatomic)NSMutableDictionary* _devices;
@property(nonatomic)NSMutableArray* _visibleDevices;
//@property(nonatomic)NSMutableDictionary* _settings;
@property(nonatomic)NSMutableDictionary* _savedDevices;

//@property(nonatomic)SettingsStore* _settings; // seems like all this is doing is acting as a
//persistent version of _devices
@end

@implementation BackgroundService

@synthesize _backgroundServiceDelegate;
@synthesize _devices;
@synthesize _linkProviders;
@synthesize _visibleDevices;
@synthesize _settings;
@synthesize _savedDevices;

+ (id) sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

+ (id) allocWithZone:(struct _NSZone *)zone
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [super allocWithZone:zone];
    });
}

- (id)copyWithZone:(NSZone *)zone;{
    return self;
}

- (id) init
{
    if ((self=[super init])) {
        // MARK: comment this out for production, this is for debugging, for clearing the saved devices dictionary in UserDefaults
        //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedDevices"];
        
        _linkProviders=[NSMutableArray arrayWithCapacity:1];
        _devices=[NSMutableDictionary dictionaryWithCapacity:1];
        _visibleDevices=[NSMutableArray arrayWithCapacity:1];
        _settings=[NSMutableDictionary dictionaryWithCapacity:1];
        _savedDevices = [NSMutableDictionary dictionary];
       //[[SettingsStore alloc] initWithPath:KDECONNECT_REMEMBERED_DEV_FILE_PATH];
        
        NSDictionary* tempDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"savedDevices"];
        if (tempDic != nil) {
            for (NSString* deviceId in [tempDic allKeys]) {
                NSData* deviceData = tempDic[deviceId];
                NSError* error;
                Device* device = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[Device class], [NSString class], [NSArray class], nil] fromData:deviceData error:&error];
                NSLog(@"device with pair status %lu is decoded from UserDefaults as: %@ with error %@", [device _pairStatus], device, error);
                if ([device _pairStatus] == Paired) {
                    [device set_deviceDelegate:self];
                    [device set_backgroundServiceDelegate:_backgroundServiceDelegate];
                    //[device reloadPlugins];
                    [_savedDevices setObject:device forKey:deviceId];
                } else {
                    NSLog(@"Not loading device above since it's previous status is NOT paired.");
                }
            }
        }
        
        NSLog(@"%@", _savedDevices);
        //[[NSUserDefaults standardUserDefaults] registerDefaults:_settings];
        //[[NSUserDefaults standardUserDefaults] synchronize];
        [self registerLinkProviders];
        [self loadRemenberedDevices];
        //[PluginFactory sharedInstance];
        
//#ifdef DEBUG
//        NSString* deviceId = @"test-purpose-device";
//        Device* device=[[Device alloc] initTest];
//        [_devices setObject:device forKey:deviceId];
//#endif
        // [_visibleDevices addObject:device];
        
        // [self refreshVisibleDeviceList];
    }
    return self;
}

- (void) loadRemenberedDevices
{
    for (Device* device in [_savedDevices allValues]) {
        //Device* device=[[Device alloc] init:deviceId setDelegate:self];
        [_devices setObject:device forKey:[device _id]];
        [_settings setObject:device forKey:[device _id]];
    }
}
- (void) registerLinkProviders
{
    NSLog(@"bg register linkproviders");
    // TO-DO: read setting for linkProvider registeration
    LanLinkProvider* linkProvider=[[LanLinkProvider alloc] initWithDelegate:self];
    [_linkProviders addObject:linkProvider];
}

- (void) startDiscovery
{
    NSLog(@"bg start Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onStart];
    }
}

- (void) refreshDiscovery
{
    NSLog(@"bg refresh Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onRefresh];
    }
}

- (void) stopDiscovery
{
    NSLog(@"bg stop Discovery");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onStop];
    }
}

- (NSDictionary*) getDevicesLists
{
    NSLog(@"bg get devices lists");
    NSMutableDictionary* _visibleDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary* _connectedDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary* _rememberedDevicesList=[NSMutableDictionary dictionaryWithCapacity:1];
    for (Device* device in [_devices allValues]) {
        if ((![device isReachable]) && [device isPaired]) {
            [_rememberedDevicesList setValue:[device _name] forKey:[device _id]];
            
        } else if([device isPaired] && [device isReachable]){
            //[device reloadPlugins];
            [_connectedDevicesList setValue:[device _name] forKey:[device _id]];
            //TODO: move this to a different thread maybe, and also in Swift
            //[device reloadPlugins];
        } else if ((![device isPaired]) && [device isReachable]) {
            [_visibleDevicesList setValue:[device _name] forKey:[device _id]];
        }// else {
            //[_backgroundServiceDelegate removeDeviceFromArrays:[device _id]];
        //}
    }
    NSDictionary* list=[NSDictionary dictionaryWithObjectsAndKeys:
                        _connectedDevicesList,  @"connected",
                        _visibleDevicesList,    @"visible",
                        _rememberedDevicesList, @"remembered",nil];
    return list;
}

- (void) pairDevice:(NSString*)deviceId;
{
    NSLog(@"bg pair device");
    Device* device=[_devices valueForKey:deviceId];
    if ([device isReachable]) {
        [device requestPairing];
    }
}

// MARK: This should be the ONLY method used for unpairing Devices, DO NOT call the device's own unpair() method as it DOES NOT remove the device from the Arrays like this one does. For other files aready using _backgroundServiceDelegate AKA ConnectedDevicesViewModel, use unpairFromBackgroundServiceInstance() in that. That's the same thing as calling this
- (void) unpairDevice:(NSString*)deviceId
{
    NSLog(@"bg unpair device");
    Device* device=[_devices valueForKey:deviceId];
    if ([device isReachable]) {
        [device unpair];
    } else { // we'll also be calling this to unpair remembered (unReachable) devices
        [device justChangeStatusToUnpaired];
    }
    [_devices removeObjectForKey:deviceId];
    [_settings removeObjectForKey:deviceId];
//    NSData* dataToBeSaved = [NSKeyedArchiver archivedDataWithRootObject:_settings requiringSecureCoding:false error:nil];
//    [[NSUserDefaults standardUserDefaults] setValue:dataToBeSaved forKey:@"savedDevices"];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate refreshDiscoveryAndListInsideView];
    }
}

//- (NSArray*) getDevicePluginViews:(NSString*)deviceId viewController:(UIViewController*)vc
//{
//    //NSLog(@"bg get device plugin view");
//    Device* device=[_devices valueForKey:deviceId];
//    if (device) {
//        return [device getPluginViews:vc];
//    }
//    return nil;
//}

- (void) refreshVisibleDeviceList
{
    NSLog(@"bg on device refresh visible device list");
    BOOL updated=false;
    for (Device* device  in [_devices allValues]) {
        if ([device isReachable]) {
            if (![_visibleDevices containsObject:device]) {
                updated=true;
                [_visibleDevices addObject:device];
            }
        }
        else{
            if ([_visibleDevices containsObject:device]) {
                updated=true;
                [_visibleDevices removeObject:device];
            }
        }
    }
    // TODO: Is it fine to take this out????
    if (_backgroundServiceDelegate && updated) {
        [_backgroundServiceDelegate onDeviceListRefreshed]; // DONT put refreshDiscoveryAndListInsideView here!!!!! Otherwise will cause refresh loop
    }
}

#pragma mark reactions
- (void) onDeviceReachableStatusChanged:(Device*)device
{   // TODO: Is this what gets called when paired device goes offline/becomes "remembered device"
    // FIXME: NOOOOOOOOOO ITS NOT, must be somewhere else, but this is called by Device when links == 0 aka unreachable????
    NSLog(@"bg on device reachable status changed");
    if (![device isReachable]) {
        NSLog(@"bg device not reachable");
        NSLog(@"%@", [device _id]);
        //[_backgroundServiceDelegate currDeviceDetailsViewDisconnectedFromRemote:[device _id]];
    }
    if (![device isPaired] && ![device isReachable]) {
        [_devices removeObjectForKey:[device _id]];
        NSLog(@"bg destroy device");
    }
    //[self refreshDiscovery];
    [self refreshVisibleDeviceList]; // might want to reverse this after figuring out why refreshDiscovery is causing Plugins to dissapear
}

- (void) onNetworkChange
{
    NSLog(@"bg on network change");
    for (LanLinkProvider* lp in _linkProviders){
        [lp onNetworkChange];
    }
    [self refreshVisibleDeviceList];
}

- (void) onConnectionReceived:(NetworkPackage *)np link:(BaseLink *)link
{
    NSLog(@"bg on connection received");
    NSString* deviceId=[np objectForKey:@"deviceId"];
    NSLog(@"Device discovered: %@",deviceId);
    if ([_devices valueForKey:deviceId]) {
        NSLog(@"known device");
        Device* device=[_devices objectForKey:deviceId];
        [device addLink:np baseLink:link];
    }
    else{
        NSLog(@"new device from network package: %@", np);
        Device* device=[[Device alloc] init:np baselink:link setDelegate:self];
        [_devices setObject:device forKey:deviceId];
        [self refreshVisibleDeviceList];
    }
}

- (void) onLinkDestroyed:(BaseLink *)link
{
    NSLog(@"bg on link destroyed");
    for (BaseLinkProvider* lp in _linkProviders) {
        [lp onLinkDestroyed:link];
    }
}

- (void) onDevicePairRequest:(Device *)device
{
    NSLog(@"bg on device pair request");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairRequest:[device _id]];
    }
}

- (void) onDevicePairTimeout:(Device*)device
{
    NSLog(@"bg on device pair timeout");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairTimeout:[device _id]];
    }
    [_settings removeObjectForKey:[device _id]];
//    NSData* dataToBeSaved = [NSKeyedArchiver archivedDataWithRootObject:_settings requiringSecureCoding:false error:nil];
//    [[NSUserDefaults standardUserDefaults] setValue:dataToBeSaved forKey:@"savedDevices"];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) onDevicePairSuccess:(Device*)device
{
    //NSLog(@"%lu", [device _type]);
    NSLog(@"bg on device pair success");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairSuccess:[device _id]];
    }
    //[device setAsPaired]; is already called in the caller of this method
    NSError* error;
    NSData* deviceData = [NSKeyedArchiver archivedDataWithRootObject:device requiringSecureCoding:YES error:&error];
    NSLog(@"device object with pair status %lu encoded into UserDefaults as: %@ with error: %@", [device _pairStatus], deviceData, error);
    [_settings setValue:deviceData forKey:[device _id]]; //[device _name]
//    NSData* dataToBeSaved = [NSKeyedArchiver archivedDataWithRootObject:_settings requiringSecureCoding:false error:nil];
//    [[NSUserDefaults standardUserDefaults] setValue:dataToBeSaved forKey:@"savedDevices"];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) onDevicePairRejected:(Device*)device
{
    NSLog(@"bg on device pair rejected");
    if (_backgroundServiceDelegate) {
        [_backgroundServiceDelegate onPairRejected:[device _id]];
    }
    [_settings removeObjectForKey:[device _id]];
//    NSData* dataToBeSaved = [NSKeyedArchiver archivedDataWithRootObject:_settings requiringSecureCoding:false error:nil];
//    [[NSUserDefaults standardUserDefaults] setValue:dataToBeSaved forKey:@"savedDevices"];
    [[NSUserDefaults standardUserDefaults] setObject:_settings forKey:@"savedDevices"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) reloadAllPlugins
{
    for (Device* device in _devices) { //_visibleDevices
        [device reloadPlugins];
    }
}

@end

