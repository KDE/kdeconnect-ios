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

#import <Foundation/Foundation.h>
#import "BaseLink.h"
#import "BaseLinkProvider.h"
#import "Device.h"
#import "NetworkPackage.h"
//#import "PluginFactory.h"
#import "common.h"
//#import "deviceDelegate.h"
//#import "KDE_Connect-Swift.h"
//@class PluginFactory;
@class BaseLink;
@class Device;
@class ConnectedDevicesViewModel;
@class CertificateService;

@interface BackgroundService : NSObject<linkProviderDelegate,deviceDelegate>

- (BackgroundService*) initWithconnectedDeviceViewModel:(ConnectedDevicesViewModel*)connectedDeviceViewModel certificateService:(CertificateService*) certificateService;
@property(nonatomic)NSMutableDictionary* _devices;
@property(nonatomic)NSMutableDictionary* _settings;

+ (id) sharedInstance;

- (void) startDiscovery;
- (void) refreshDiscovery;
- (void) stopDiscovery;
- (void) pairDevice:(NSString*)deviceId;
- (void) unpairDevice:(NSString*)deviceId;
//- (NSArray*) getDevicePluginViews:(NSString*)deviceId viewController:(UIViewController*)vc;
- (NSDictionary*) getDevicesLists;
- (void) reloadAllPlugins;
- (void) refreshVisibleDeviceList;

- (void) onNetworkChange;
//- (void) onLinkDestroyed:(BaseLink *)link;
@end
