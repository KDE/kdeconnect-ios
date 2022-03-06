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

#import "NetworkPackage.h"
#import "Device.h"
#import "KDE_Connect-Swift.h"
#import "KeychainItemWrapper.h"
@import UIKit;

#define LFDATA [NSData dataWithBytes:"\x0A" length:1]

__strong static NSString* _UUID;

#pragma mark Implementation
@implementation NetworkPackage

- (NetworkPackage*) initWithType:(NetworkPackageType)type
{
    if ((self=[super init]))
    {
        _Id=[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
        self.type=type;
        _Body=[NSMutableDictionary dictionary];
    }
    return self;
}

@synthesize _Id;
@synthesize type;
@synthesize _Body;
@synthesize _Payload;
@synthesize _PayloadSize;
@synthesize _PayloadTransferInfo;

#pragma mark create Package
+(NetworkPackage*) createIdentityPackage
{
    NetworkPackage* np=[[NetworkPackage alloc] initWithType:NetworkPackageTypeIdentity];
    [np setObject:[NetworkPackage getUUID] forKey:@"deviceId"];
    NSString* deviceName=[[NSUserDefaults standardUserDefaults] stringForKey:@"deviceName"];
    if (deviceName == nil) {
        deviceName=[UIDevice currentDevice].name;
    }
    [np setObject:deviceName forKey:@"deviceName"];
    [np setInteger:ProtocolVersion forKey:@"protocolVersion"];
    [np setObject:[Device DeviceType2Str:Device.currentDeviceType] forKey:@"deviceType"];
    [np setInteger:1716 forKey:@"tcpPort"];
    
    // TODO: Instead of @[] actually import what plugins are available, UserDefaults to store maybe?
    // For now, manually putting everything in to trick the other device to sending the iOS host the
    // identity packets so debugging is easier
    [np setObject:@[NetworkPackageTypePing,
                    NetworkPackageTypeShare,
                    //@"kdeconnect.share.request.update",
                    NetworkPackageTypeFindMyPhoneRequest,
                    NetworkPackageTypeBatteryRequest,
                    NetworkPackageTypeBattery,
                    NetworkPackageTypeClipboard,
                    NetworkPackageTypeClipboardConnect,
                    NetworkPackageTypeRunCommand
                    ] forKey:@"incomingCapabilities"];
    [np setObject:@[NetworkPackageTypePing,
                    NetworkPackageTypeShare,
                    //@"kdeconnect.share.request.update",
                    NetworkPackageTypeFindMyPhoneRequest,
                    NetworkPackageTypeBatteryRequest,
                    NetworkPackageTypeBattery,
                    NetworkPackageTypeClipboard,
                    NetworkPackageTypeClipboardConnect,
                    NetworkPackageTypeMousePadRequest,
                    NetworkPackageTypePresenter,
                    NetworkPackageTypeRunCommandRequest
                    ] forKey:@"outgoingCapabilities"];
    
    // FIXME: Remove object
//    [np setObject:[[PluginFactory sharedInstance] getSupportedIncomingInterfaces] forKey:@"SupportedIncomingInterfaces"];
//    [np setObject:[[PluginFactory sharedInstance] getSupportedOutgoingInterfaces] forKey:@"SupportedOutgoingInterfaces"];
//    
    return np;
}

//Never touch these!
+ (NSString*) getUUID
{
    if (!_UUID) {
        NSString* group = @"Q9HDHY97NW.org.kde.kdeconnect-ios";
        KeychainItemWrapper* wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"org.kde.kdeconnect-ios" accessGroup:group];
        _UUID = [wrapper objectForKey:(__bridge id)(kSecValueData)];
        if (!_UUID || [_UUID length] < 1) {
            // FIXME: identifierForVendor might be nil
            // Documentation reads:
            // If the value is nil, wait and get the value again later.
            // This happens, for example, after the device has been restarted
            // but before the user has unlocked the device.
            _UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            _UUID = [_UUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
            _UUID = [_UUID stringByReplacingOccurrencesOfString:@"_" withString:@""];
            [wrapper setObject:_UUID forKey:(__bridge id)(kSecValueData)];
        }
    }
    NSLog(@"Get UUID %@", _UUID);
    return _UUID;
}

+ (NetworkPackage*) createPairPackage
{
    NetworkPackage* np=[[NetworkPackage alloc] initWithType:NetworkPackageTypePair];
    [np setBool:YES forKey:@"pair"];

    return np;
}

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

#pragma mark Serialize
- (NSData*) serialize
{
    NSArray* keys=[NSArray arrayWithObjects:@"id",@"type",@"body", nil];
    NSArray* values=[NSArray arrayWithObjects:[self _Id],self.type,[self _Body], nil];
    NSMutableDictionary* info=[NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
    if (_Payload) {
        [info setObject:[NSNumber numberWithLong:(_PayloadSize?_PayloadSize:-1)] forKey:@"payloadSize"];
        [info setObject: _PayloadTransferInfo forKey:@"payloadTransferInfo"];
    }
    NSError* err=nil;
    NSMutableData* jsonData=[[NSMutableData alloc] initWithData:[NSJSONSerialization dataWithJSONObject:info options:0 error:&err]];
    if (err) {
        NSLog(@"NP serialize error");
        return nil;
    }
    [jsonData appendData:LFDATA];
    return jsonData;
}

+ (NetworkPackage*) unserialize:(NSData*)data
{
    NetworkPackage* np=[[NetworkPackage alloc] init];
    NSError* err=nil;
    NSDictionary* info=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];

    // FIXME: add missing null check
    [np set_Id:[info valueForKey:@"id"]];
    np.type = [info valueForKey:@"type"];
    [np set_Body:[info valueForKey:@"body"]];
    [np set_PayloadSize:[[info valueForKey:@"payloadSize"]longValue]];
    [np set_PayloadTransferInfo:[info valueForKey:@"payloadTransferInfo"]];
    
    // NSLog(@"Parsed id: %@, type: %@", [info valueForKey:@"id"], [info valueForKey:@"type"]);
    
    //TO-DO should change for laptop
    if ([np _PayloadSize]==-1) {
        NSInteger temp;
        long size=(temp=[np integerForKey:@"size"])?temp:-1;
        [np set_PayloadSize:size];
    }
    [np set_PayloadTransferInfo:[info valueForKey:@"payloadTransferInfo"]];
    
    // FIXME: error check too late
    if (err) {
        return nil;
    }
    return np;
}

@end

#pragma mark - Package Types

NetworkPackageType const NetworkPackageTypeIdentity                 = @"kdeconnect.identity";
NetworkPackageType const NetworkPackageTypeEncrypted                = @"kdeconnect.encrypted";
NetworkPackageType const NetworkPackageTypePair                     = @"kdeconnect.pair";
NetworkPackageType const NetworkPackageTypePing                     = @"kdeconnect.ping";

NetworkPackageType const NetworkPackageTypeMPRIS                    = @"kdeconnect.mpris";

NetworkPackageType const NetworkPackageTypeShare                    = @"kdeconnect.share.request";
NetworkPackageType const NetworkPackageTypeShareInternal            = @"kdeconnect.share";

NetworkPackageType const NetworkPackageTypeClipboard                = @"kdeconnect.clipboard";
NetworkPackageType const NetworkPackageTypeClipboardConnect         = @"kdeconnect.clipboard.connect";

NetworkPackageType const NetworkPackageTypeBattery                  = @"kdeconnect.battery";
NetworkPackageType const NetworkPackageTypeCalendar                 = @"kdeconnect.calendar";
// NetworkPackageType const NetworkPackageTypeReminder                 = @"kdeconnect.reminder";
NetworkPackageType const NetworkPackageTypeContact                  = @"kdeconnect.contact";

NetworkPackageType const NetworkPackageTypeBatteryRequest           = @"kdeconnect.battery.request";
NetworkPackageType const NetworkPackageTypeFindMyPhoneRequest       = @"kdeconnect.findmyphone.request";

NetworkPackageType const NetworkPackageTypeMousePadRequest          = @"kdeconnect.mousepad.request";
NetworkPackageType const NetworkPackageTypeMousePadKeyboardState    = @"kdeconnect.mousepad.keyboardstate";
NetworkPackageType const NetworkPackageTypeMousePadEcho             = @"kdeconnect.mousepad.echo";

NetworkPackageType const NetworkPackageTypePresenter                = @"kdeconnect.presenter";

NetworkPackageType const NetworkPackageTypeRunCommandRequest        = @"kdeconnect.runcommand.request";
NetworkPackageType const NetworkPackageTypeRunCommand               = @"kdeconnect.runcommand";
