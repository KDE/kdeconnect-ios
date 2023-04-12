//
//  OSLog+KDE Connect.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/3/22.
//

import OSLog

extension NSString {
    @objc
    static let kdeConnectOSLogSubsystem = Bundle.main.bundleIdentifier ?? "org.kde.kdeconnect"
}

extension OSLog {
    static let subsystem = NSString.kdeConnectOSLogSubsystem
}

/// Pretend to be the actual initializer for os.Logger, but not.
/// - Parameter category: the Logger's category.
/// Defaults to #function, which would be the class/struct/function's name.
/// - Returns: os.Logger with subsystem OSLog.subsystem and the specified category.
func Logger(category: String = #function) -> os.Logger {
    // swiftlint:disable:previous identifier_name
    // This naming is intentional in tricking the compiler
    print("os.Logger(subsystem: \(OSLog.subsystem), category: \(category))")
    return os.Logger(subsystem: OSLog.subsystem, category: category)
}
