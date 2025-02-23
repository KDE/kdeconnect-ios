/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below://Copyright 27/4/14  YANG Qiao yangqiao0505@me.com
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

#import "NetworkPacket.h"
#import "Device.h"
#import "KDE_Connect-Swift.h"
#if !TARGET_OS_OSX
@import UIKit;
#else
@import SystemConfiguration;
#import <IOKit/IOKitLib.h>
#endif

@import os.log;

#define LFDATA [NSData dataWithBytes:"\x0A" length:1]

#pragma mark Implementation
@implementation NetworkPacket

- (NetworkPacket*) initWithType:(NetworkPacketType)type
{
    if ((self=[super init]))
    {
        self.type=type;
        _Body=[NSMutableDictionary dictionary];
    }
    return self;
}

@synthesize type;
@synthesize _Body;
@synthesize _PayloadSize;

#pragma mark create Packet
+ (NetworkPacket *)createIdentityPacket
{
    DeviceInfo* ownDeviceInfo = [DeviceInfo getOwn];
    NetworkPacket* np=[[NetworkPacket alloc] initWithType:NetworkPacketTypeIdentity];
    [np setObject:ownDeviceInfo.id forKey:@"deviceId"];
    [np setObject:ownDeviceInfo.name forKey:@"deviceName"];
    [np setInteger:ownDeviceInfo.protocolVersion forKey:@"protocolVersion"];
    [np setObject:[ownDeviceInfo getTypeAsString] forKey:@"deviceType"];
    [np setObject:ownDeviceInfo.incomingCapabilities forKey:@"incomingCapabilities"];
    [np setObject:ownDeviceInfo.outgoingCapabilities forKey:@"outgoingCapabilities"];
    return np;
}

+ (NetworkPacket *)createIdentityPacketWithTCPPort:(uint16_t)tcpPort
{
    NetworkPacket* np=[self createIdentityPacket];
    [np setInteger:tcpPort forKey:@"tcpPort"];
    return np;
}

+ (NetworkPacket*) createPairRequestPacket:(NSInteger)pairingTimestamp
{
    NetworkPacket* np=[[NetworkPacket alloc] initWithType:NetworkPacketTypePair];
    [np setBool:YES forKey:@"pair"];
    [np setInteger:pairingTimestamp forKey:@"timestamp"];
    return np;
}

+ (NetworkPacket*) createPairAcceptPacket:(BOOL)accept
{
    NetworkPacket* np=[[NetworkPacket alloc] initWithType:NetworkPacketTypePair];
    [np setBool:accept forKey:@"pair"];
    return np;
}

#if TARGET_OS_OSX
// https://stackoverflow.com/questions/11113735/how-to-identify-a-mac-system-uniquely
+ (NSString *) getMacUUID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMainPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert) return nil;

    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    if (!serialNumberAsCFString) return nil;

    IOObjectRelease(platformExpert);
    return (__bridge NSString *)(serialNumberAsCFString);
}
#endif

//
- (BOOL) bodyHasKey:(NSString*)key
{
    // FIXME: this implementation is most likely inaccurate;
    // might have bug when key starts with "@" because for valueForKey:
    //  If key does not start with “@”, invokes `objectForKey:`.
    //  If key does start with “@”, strips the “@” and
    //      invokes [super valueForKey:] with the rest of the key.
    if ([self._Body valueForKey:key]!=nil) {
        return true;
    }
    return false;
};

- (void)setBool:(BOOL)value forKey:(NSString*)key {
    [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (void)setFloat:(float)value forKey:(NSString*)key {
    [self setObject:[NSNumber numberWithFloat:value] forKey:key];
}

- (void)setInteger:(NSInteger)value forKey:(NSString*)key {
    [self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString*)key {
    [self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

- (void)setObject:(id)value forKey:(NSString *)key{
    [_Body setObject:value forKey:key];
}

- (BOOL)boolForKey:(NSString*)key {
    return [[self objectForKey:key] boolValue];
}

- (float)floatForKey:(NSString*)key {
    return [[self objectForKey:key] floatValue];
}
- (NSInteger)integerForKey:(NSString*)key {
    return [[self objectForKey:key] integerValue];
}

- (double)doubleForKey:(NSString*)key {
    return [[self objectForKey:key] doubleValue];
}

- (id)objectForKey:(NSString *)key{
    return [_Body objectForKey:key];
}

- (NSString*)stringForKey:(NSString *)key{
    return [_Body objectForKey:key];
}

#pragma mark Serialize
- (NSData*) serialize
{
    NSArray* keys=[NSArray arrayWithObjects:@"id",@"type",@"body", nil];
    NSNumber* _id = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
    NSArray* values=[NSArray arrayWithObjects:_id, self.type, [self _Body], nil];
    NSMutableDictionary* info=[NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
    if (_payloadPath) {
        // TODO: is checking _PayloadSize == 0 then changing it to -1 necessary?
        // what about empty files e.g. `.gitkeep`?
        [info setObject:[NSNumber numberWithLong:(_PayloadSize?_PayloadSize:-1)] forKey:@"payloadSize"];
        [info setObject:_payloadTransferInfo forKey:@"payloadTransferInfo"];
    }
    NSError* err=nil;
    NSMutableData* jsonData=[[NSMutableData alloc] initWithData:[NSJSONSerialization dataWithJSONObject:info options:0 error:&err]];
    if (err) {
        os_log_t logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                                        NSStringFromClass([self class]).UTF8String);
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "NP serialize error");
        return nil;
    }
    [jsonData appendData:LFDATA];
    return jsonData;
}

+ (NetworkPacket*) unserialize:(NSData*)data
{
    NetworkPacket* np=[[NetworkPacket alloc] init];
    NSError* err=nil;
    NSDictionary* info=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];

    // FIXME: add missing null check
    np.type = [info valueForKey:@"type"];
    [np set_Body:[info valueForKey:@"body"]];
    [np set_PayloadSize:[[info valueForKey:@"payloadSize"]longValue]];
    [np setPayloadTransferInfo:[info valueForKey:@"payloadTransferInfo"]];
    
    // NSLog(@"Parsed type: %@", [info valueForKey:@"type"]);
    
    //TO-DO should change for laptop
    if ([np _PayloadSize]==-1) {
        NSInteger temp;
        long size=(temp=[np integerForKey:@"size"])?temp:-1;
        [np set_PayloadSize:size];
    }
    [np setPayloadTransferInfo:[info valueForKey:@"payloadTransferInfo"]];
    
    // FIXME: error check too late
    if (err) {
        return nil;
    }
    return np;
}

@end

#pragma mark - Packet Types

NetworkPacketType const NetworkPacketTypeIdentity                 = @"kdeconnect.identity";
NetworkPacketType const NetworkPacketTypePair                     = @"kdeconnect.pair";
NetworkPacketType const NetworkPacketTypePing                     = @"kdeconnect.ping";

NetworkPacketType const NetworkPacketTypeMPRIS                    = @"kdeconnect.mpris";

NetworkPacketType const NetworkPacketTypeShare                    = @"kdeconnect.share.request";
NetworkPacketType const NetworkPacketTypeShareRequestUpdate       = @"kdeconnect.share.request.update";
NetworkPacketType const NetworkPacketTypeShareInternal            = @"kdeconnect.share";

NetworkPacketType const NetworkPacketTypeClipboard                = @"kdeconnect.clipboard";
NetworkPacketType const NetworkPacketTypeClipboardConnect         = @"kdeconnect.clipboard.connect";

NetworkPacketType const NetworkPacketTypeBattery                  = @"kdeconnect.battery";
NetworkPacketType const NetworkPacketTypeCalendar                 = @"kdeconnect.calendar";
// NetworkPacketType const NetworkPacketTypeReminder                 = @"kdeconnect.reminder";
NetworkPacketType const NetworkPacketTypeContact                  = @"kdeconnect.contact";

NetworkPacketType const NetworkPacketTypeBatteryRequest           = @"kdeconnect.battery.request";
NetworkPacketType const NetworkPacketTypeFindMyPhoneRequest       = @"kdeconnect.findmyphone.request";

NetworkPacketType const NetworkPacketTypeMousePadRequest          = @"kdeconnect.mousepad.request";
NetworkPacketType const NetworkPacketTypeMousePadKeyboardState    = @"kdeconnect.mousepad.keyboardstate";
NetworkPacketType const NetworkPacketTypeMousePadEcho             = @"kdeconnect.mousepad.echo";

NetworkPacketType const NetworkPacketTypePresenter                = @"kdeconnect.presenter";

NetworkPacketType const NetworkPacketTypeRunCommandRequest        = @"kdeconnect.runcommand.request";
NetworkPacketType const NetworkPacketTypeRunCommand               = @"kdeconnect.runcommand";
