/*
 * SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import Foundation
import AVFoundation

// System sounds definitions, for a list of all IDs, see
// https://github.com/TUNER88/iOSSystemSoundsLibrary
enum SystemSound: SystemSoundID {
    case mailReceived = 1000
    case mailSent = 1001
    case smsReceived = 1003
    case calendarAlert = 1005
    case audioToneBusy = 1070
    case audioError = 1073
    
    func play() {
        AudioServicesPlaySystemSound(self.rawValue)
    }
}
