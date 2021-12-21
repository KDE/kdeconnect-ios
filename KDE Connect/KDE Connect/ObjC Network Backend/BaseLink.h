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
//----------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "NetworkPackage.h"

@interface BaseLink : NSObject

@property(nonatomic) NSString* _deviceId;
@property(nonatomic, weak) id _linkDelegate;
//@property(nonatomic) SecKeyRef _publicKey;

- (BaseLink*) init:(NSString*)deviceId setDelegate:(id)linkDelegate;
- (BOOL) sendPackage:(NetworkPackage*)np tag:(long)tag;
- (void) disconnect;

@end;

@protocol linkDelegate <NSObject>
@optional
- (void) onPackageReceived:(NetworkPackage*)np;
- (void) onSendSuccess:(long)tag;
- (void) onSentPercentage:(short)percentage tag:(long)tag;
- (void) onLinkDestroyed:(BaseLink*)link;
@end
