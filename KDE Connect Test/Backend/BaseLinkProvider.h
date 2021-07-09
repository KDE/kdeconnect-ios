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
#import "NetworkPackage.h"
#import "BaseLink.h"

@interface BaseLinkProvider : NSObject

@property(nonatomic) id _linkProviderDelegate;
@property(nonatomic) NSMutableDictionary* _connectedLinks;

- (BaseLinkProvider*) initWithDelegate:(id)linkProviderDelegate;
- (void) onStart;
- (void) onRefresh;
- (void) onStop;
- (void) onNetworkChange;
- (void) onLinkDestroyed:(BaseLink*)link;

@end

@protocol linkProviderDelegate <NSObject>
@optional
- (void) onConnectionReceived:(NetworkPackage*)np link:(BaseLink*)link;
@end
