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

#import "BaseLinkProvider.h"

@implementation BaseLinkProvider

@synthesize _linkProviderDelegate;

- (BaseLinkProvider*) initWithDelegate:(id)linkProviderDelegate
{
    if ((self=[super init])) {
        _linkProviderDelegate=linkProviderDelegate;
    }
    return self;
}

- (void) onStart
{
    // do nothing
}

- (void) onRefresh
{
    // do nothing
}

- (void) onStop
{
    // do nothing
}

- (void) onNetworkChange
{
    // do nothing
}

- (void) onLinkDestroyed:(BaseLink*)link
{
    // do nothing
}

@end
