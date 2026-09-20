/*
 * SPDX-FileCopyrightText: 2024 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#import <Foundation/Foundation.h>
#import "LoopbackLink.h"
#import "BaseLinkProvider.h"

@interface LoopbackLinkProvider : BaseLinkProvider <LinkDelegate>

- (LoopbackLinkProvider *)initWithDelegate:(id<LinkProviderDelegate>)linkProviderDelegate;

@end
