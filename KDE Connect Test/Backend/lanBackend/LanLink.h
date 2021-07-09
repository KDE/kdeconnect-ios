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

#import <Foundation/Foundation.h>
#import "BaseLink.h"
#import "LanLinkProvider.h"
#import "GCDAsyncSocket.h"

@class LanLinkProvider;
@class BaseLink;
@class Device;

@interface LanLink : BaseLink <GCDAsyncSocketDelegate>

- (LanLink*) init:(GCDAsyncSocket*)socket deviceId:(NSString*) deviceid setDelegate:(id)linkDelegate;
- (BOOL) sendPackage:(NetworkPackage *)np tag:(long)tag;
- (void) disconnect;
@end
