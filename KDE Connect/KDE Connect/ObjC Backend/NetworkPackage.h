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

#pragma mark - Package Types

NS_ASSUME_NONNULL_BEGIN

typedef NSString *NetworkPackageType NS_TYPED_ENUM NS_SWIFT_NAME(NetworkPackage.Type);

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeIdentity;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeEncrypted;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypePair;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypePing;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeMPRIS;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeShare;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeShareRequestUpdate;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeShareInternal;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeClipboard;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeClipboardConnect;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeBattery;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeCalendar;
// FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeReminder;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeContact;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeBatteryRequest;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeFindMyPhoneRequest;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeMousePadRequest;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeMousePadKeyboardState;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeMousePadEcho;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypePresenter;

FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeRunCommandRequest;
FOUNDATION_EXPORT NetworkPackageType const NetworkPackageTypeRunCommand;

#pragma mark -

@interface NetworkPackage : NSObject

@property(nonatomic) NSNumber *_Id;
@property(nonatomic) NetworkPackageType type;
@property(nonatomic) NSMutableDictionary<NSString *, id> *_Body;
@property(nonatomic, nullable) NSURL *payloadPath;
@property(nonatomic, nullable) NSDictionary<NSString *, id> *payloadTransferInfo;
@property(nonatomic) long _PayloadSize;

- (NetworkPackage *) initWithType:(NetworkPackageType)type;
+ (NetworkPackage *)createIdentityPackageWithTCPPort:(uint16_t)tcpPort;
+ (NetworkPackage *) createPairPackage;
+ (nullable NSString *) getUUID;

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

#pragma mark Serialize
- (nullable NSData *) serialize;
+ (nullable NetworkPackage *) unserialize:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
