/*
 * SPDX-FileCopyrightText: 2024 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#import "LoopbackLink.h"
#import "KDE_Connect-Swift.h"

@import os.log;

@implementation LoopbackLink

- (LoopbackLink *) init
{
    return [super init:[DeviceInfo getOwn]];
}

- (BOOL) sendPacket:(NetworkPacket *)np tag:(long)tag
{
    [[self linkDelegate] onPacketReceived:np];
    return YES;
}

- (void)disconnect {
}

@end

