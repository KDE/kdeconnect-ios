/*
 * SPDX-FileCopyrightText: 2024 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#import "BaseLink.h"

@class BaseLink;

@interface LoopbackLink : BaseLink

- (LoopbackLink *) init;
- (BOOL) sendPacket:(NetworkPacket *)np tag:(long)tag;
- (void) disconnect;
@end
