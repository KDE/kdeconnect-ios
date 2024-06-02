/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//Copyright 29/4/14  YANG Qiao yangqiao0505@me.com
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
#import "NetworkPacket.h"
#import "UIKit/UIKit.h"
//#import "deviceDelegate.h"
//#import "BackgroundService.h"
@class BaseLink;
@class NetworkPacket;
@class DeviceInfo;
@protocol Plugin;
//@class Ping;
//@class Share;
//@class FindMyPhone;
//@class Battery;
//@interface PluginInterface;

typedef NS_ENUM(NSUInteger, PairStatus)
{
    NotPaired=0,
    Requested=1,
    RequestedByPeer=2,
    Paired=3
};

@protocol DeviceDelegate;

@interface Device : NSObject <LinkDelegate, NSSecureCoding>

@property(readonly, nonatomic) DeviceInfo *_deviceInfo;

@property(readonly, nonatomic) PairStatus _pairStatus;

@property(nonatomic) NSMutableArray* _links;
@property(nonatomic, setter=setPlugins:) NSDictionary<NetworkPacketType, id<Plugin>> *plugins;
@property(nonatomic) NSMutableArray* _failedPlugins;

@property(nonatomic) id<DeviceDelegate> deviceDelegate;

//@property(readonly,nonatomic) BOOL _testDevice;

// Plugin enable status
@property(nonatomic, setter=setPluginsEnableStatus:) NSDictionary<NetworkPacketType, NSNumber *> *pluginsEnableStatus;

// Plugin-specific persistent data are stored in the Device object. Plugin objects contain runtime
// data only and are therefore NOT stored persistently
// Remote Input
@property(nonatomic) float _cursorSensitivity;
@property(nonatomic) UIImpactFeedbackStyle hapticStyle;
// Presenter
@property(nonatomic) float _pointerSensitivity;

// For NSCoding
@property (class, readonly) BOOL supportsSecureCoding;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLink:(BaseLink*)link
                              delegate:(id<DeviceDelegate>)deviceDelegate;
- (NSInteger) compareProtocolVersion;

#pragma mark Link-related Functions
- (bool)updateInfo:(DeviceInfo *)newDeviceInfo;
- (void)addLink:(BaseLink *)link;
- (void)onPacketReceived:(NetworkPacket *)np;
- (void)onLinkDestroyed:(BaseLink *)link;
- (BOOL)sendPacket:(NetworkPacket *)np tag:(long)tag;
- (BOOL)isReachable;

#pragma mark Pairing-related Functions
- (BOOL)isPaired;
- (BOOL)isPaireRequested;
//- (void)setAsPaired; // Is this needed to be public?
- (void)requestPairing;
- (void)setAsUnpaired;
- (void)unpair;
- (void)acceptPairing;

#pragma mark Plugin-related Functions
- (void) reloadPlugins;
// - (NSArray*) getPluginViews:(UIViewController*)vc;
@end

@protocol DeviceDelegate <NSObject>
@optional
- (void)onDeviceReachableStatusChanged:(Device *)device;
- (void)onDevicePairRequest:(Device *)device;
- (void)onDevicePairTimeout:(Device *)device;
- (void)onDevicePairSuccess:(Device *)device;
- (void)onDevicePairRejected:(Device *)device;
- (void)onDeviceUnpaired:(Device *)device;
- (void)onDevicePluginChanged:(Device *)device;
- (void)onLinkDestroyed:(BaseLink *)link;
@end
