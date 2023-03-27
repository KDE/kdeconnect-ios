/*
 * SPDX-FileCopyrightText: 2014 YANG Qiao <yangqiao0505@me.com>
 *                         2020 Weixuan Xiao <veyx.shaw@gmail.com>
 *                         2021 Lucas Wang <lucas.wang@tuta.io>
 *                         2023 Apollo Zhu <public-apollonian@outlook.com>
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

@class BaseLink;
@class KDEFileTransferItem;

NS_ASSUME_NONNULL_BEGIN

@protocol LinkDelegate <NSObject>
@optional
- (void)onPackageReceived:(NetworkPackage *)np;
- (void)onSendingPayload:(KDEFileTransferItem *)payload;
- (void)onPackage:(NetworkPackage *)np sentWithPackageTag:(long)tag;
- (void)onPackage:(NetworkPackage *)np sendWithPackageTag:(long)tag
  failedWithError:(NSError *)error;
- (void)willReceivePayload:(KDEFileTransferItem *)payload
  totalNumOfFilesToReceive:(long)numberOfFiles;
- (void)onReceivingPayload:(KDEFileTransferItem *)payload;
- (void)onReceivingPayload:(KDEFileTransferItem *)payload
           failedWithError:(NSError *)error;
- (void)onLinkDestroyed:(BaseLink *)link;
@end

NS_ASSUME_NONNULL_END
