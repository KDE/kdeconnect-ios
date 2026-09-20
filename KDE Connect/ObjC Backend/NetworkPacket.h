/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
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

#pragma mark Packet related macro

#define UDPBROADCAST_TAG        -3
#define TCPSERVER_TAG           -2

#define PACKET_TAG_PAYLOAD     -1
#define PACKET_TAG_NORMAL      0
#define PACKET_TAG_IDENTITY    1
#define PACKET_TAG_PAIR        3
#define PACKET_TAG_UNPAIR      4
#define PACKET_TAG_PING        5
#define PACKET_TAG_MPRIS       6
#define PACKET_TAG_SHARE       7
#define PACKET_TAG_CLIPBOARD   8
#define PACKET_TAG_MOUSEPAD    9
#define PACKET_TAG_BATTERY     10
#define PACKET_TAG_CALENDAR    11
// #define PACKET_TAG_REMINDER    12
#define PACKET_TAG_CONTACT     13 

#define UDP_PORT                 1716
#define PORT                     1716    /* Fallback */
#define MIN_TCP_PORT             1716
#define MAX_TCP_PORT             1764
#define MAX_IDENTITY_PACKET_SIZE 8192
#define MAX_PACKET_SIZE          32 * 1024 * 1024

#pragma mark - Packet Types

NS_ASSUME_NONNULL_BEGIN

typedef NSString *NetworkPacketType NS_TYPED_ENUM NS_SWIFT_NAME(NetworkPacket.Type);

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeIdentity;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypePair;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypePing;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeMPRIS;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeShare;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeShareRequestUpdate;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeShareInternal;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeClipboard;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeClipboardConnect;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeBattery;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeCalendar;
// FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeReminder;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeContact;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeBatteryRequest;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeFindMyPhoneRequest;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeMousePadRequest;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeMousePadKeyboardState;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeMousePadEcho;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypePresenter;

FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeRunCommandRequest;
FOUNDATION_EXPORT NetworkPacketType const NetworkPacketTypeRunCommand;

#pragma mark -

@interface NetworkPacket : NSObject

@property(nonatomic) NetworkPacketType type;
@property(nonatomic) NSMutableDictionary<NSString *, id> *_Body;
@property(nonatomic, nullable) NSURL *payloadPath;
@property(nonatomic, nullable) NSDictionary<NSString *, id> *payloadTransferInfo;
@property(nonatomic) long _PayloadSize;

- (NetworkPacket *) initWithType:(NetworkPacketType)type;
+ (NetworkPacket *) createIdentityPacket;
+ (NetworkPacket *) createPairRequestPacket:(NSInteger)pairingTimestamp;
+ (NetworkPacket *) createPairAcceptPacket:(BOOL)accept;
#if TARGET_OS_OSX
+ (NSString *) getMacUUID;
#endif

- (BOOL)bodyHasKey:(nonnull NSString *)key;
- (void)setBool:(BOOL)value         forKey:(NSString *)key;
- (void)setFloat:(float)value       forKey:(NSString *)key;
- (void)setDouble:(double)value     forKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setObject:(id)value         forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (nullable id)objectForKey:(NSString *)key;
- (NSString*)stringForKey:(NSString *)key;

#pragma mark Serialize
- (nullable NSData *) serialize;
+ (nullable NetworkPacket *) unserialize:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
