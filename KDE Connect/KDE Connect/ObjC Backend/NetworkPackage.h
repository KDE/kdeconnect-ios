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
//---------------------------------------------------------------------

#import <Foundation/Foundation.h>

#pragma mark Package related macro

#define UDPBROADCAST_TAG        -3
#define TCPSERVER_TAG           -2

#define PACKAGE_TAG_PAYLOAD     -1
#define PACKAGE_TAG_NORMAL      0
#define PACKAGE_TAG_IDENTITY    1
#define PACKAGE_TAG_ENCRYPTED   2
#define PACKAGE_TAG_PAIR        3
#define PACKAGE_TAG_UNPAIR      4
#define PACKAGE_TAG_PING        5
#define PACKAGE_TAG_MPRIS       6
#define PACKAGE_TAG_SHARE       7
#define PACKAGE_TAG_CLIPBOARD   8
#define PACKAGE_TAG_MOUSEPAD    9
#define PACKAGE_TAG_BATTERY     10
#define PACKAGE_TAG_CALENDAR    11
// #define PACKAGE_TAG_REMINDER    12
#define PACKAGE_TAG_CONTACT     13 

#define UDP_PORT                1716
#define PORT                    1716    /* Fallback */
#define MIN_TCP_PORT            1716
#define MAX_TCP_PORT            1764
#define ProtocolVersion         7

#define PACKAGE_TYPE_IDENTITY                   @"kdeconnect.identity"
#define PACKAGE_TYPE_ENCRYPTED                  @"kdeconnect.encrypted"
#define PACKAGE_TYPE_PAIR                       @"kdeconnect.pair"
#define PACKAGE_TYPE_PING                       @"kdeconnect.ping"

#define PACKAGE_TYPE_MPRIS                      @"kdeconnect.mpris"

#define PACKAGE_TYPE_SHARE                      @"kdeconnect.share.request"
#define PACKAGE_TYPE_SHARE_INTERNAL             @"kdeconnect.share"

#define PACKAGE_TYPE_CLIPBOARD                  @"kdeconnect.clipboard"
#define PACKAGE_TYPE_CLIPBOARD_CONNECT          @"kdeconnect.clipboard.connect"

#define PACKAGE_TYPE_BATTERY                    @"kdeconnect.battery"
#define PACKAGE_TYPE_CALENDAR                   @"kdeconnect.calendar"
// #define PACKAGE_TYPE_REMINDER           @"kdeconnect.reminder"
#define PACKAGE_TYPE_CONTACT                    @"kdeconnect.contact"

#define PACKAGE_TYPE_BATTERY_REQUEST            @"kdeconnect.battery.request"
#define PACKAGE_TYPE_FINDMYPHONE_REQUEST        @"kdeconnect.findmyphone.request"

#define PACKAGE_TYPE_MOUSEPAD_REQUEST           @"kdeconnect.mousepad.request"
#define PACKAGE_TYPE_MOUSEPAD_KEYBOARDSTATE     @"kdeconnect.mousepad.keyboardstate"
#define PACKAGE_TYPE_MOUSEPAD_ECHO              @"kdeconnect.mousepad.echo"

#define PACKAGE_TYPE_PRESENTER                  @"kdeconnect.presenter"

#define PACKAGE_TYPE_RUNCOMMAND_REQUEST         @"kdeconnect.runcommand.request"
#define PACKAGE_TYPE_RUNCOMMAND                 @"kdeconnect.runcommand"

#pragma mark -

@interface NetworkPackage : NSObject

@property(nonatomic) NSNumber *_Id;
@property(nonatomic) NSString *_Type;
@property(nonatomic) NSMutableDictionary *_Body;
@property(nonatomic) NSData *_Payload;
@property(nonatomic) NSDictionary *_PayloadTransferInfo;
@property(nonatomic)long _PayloadSize;

- (NetworkPackage*) initWithType:(NSString*)type;
+ (NetworkPackage*) createIdentityPackage;
+ (NetworkPackage*) createPairPackage;
+ (NSString*) getUUID;

- (BOOL) bodyHasKey:(NSString*)key;
- (void)setBool:(BOOL)value      forKey:(NSString*)key;
- (void)setFloat:(float)value    forKey:(NSString*)key;
- (void)setDouble:(double)value  forKey:(NSString*)key;
- (void)setInteger:(NSInteger)value    forKey:(NSString*)key;
- (void)setObject:(id)value      forKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key;
- (float)floatForKey:(NSString*)key;
- (double)doubleForKey:(NSString*)key;
- (NSInteger)integerForKey:(NSString*)key;
- (id)objectForKey:(NSString*)key;

#pragma mark Serialize
- (NSData*) serialize;
+ (NetworkPackage*) unserialize:(NSData*)data;

@end
