/*
 * SPDX-FileCopyrightText: 2024 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#import "LoopbackLinkProvider.h"
#import "NetworkPacket.h"
#import "KDE_Connect-Swift.h"

#import <Security/Security.h>
#import <Security/SecItem.h>
#import <Security/SecTrust.h>
#import <Security/CipherSuite.h>
#import <Security/SecIdentity.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@import os.log;

@implementation LoopbackLinkProvider

- (LoopbackLinkProvider *) initWithDelegate:(id<LinkProviderDelegate>)linkProviderDelegate
{
    return [super initWithDelegate:linkProviderDelegate];
}

- (void) onStart {
    LoopbackLink* loopbackLink = [[LoopbackLink alloc] init];
    [[self _linkProviderDelegate] onConnectionReceived:loopbackLink];
}

- (void) onStop {
}

- (void) onRefresh
{
    [self onStop];
    [self onStart];
}

- (void) onNetworkChange
{
    [self onRefresh];
}

- (void) onLinkDestroyed:(BaseLink*)link
{
    
}

@end
