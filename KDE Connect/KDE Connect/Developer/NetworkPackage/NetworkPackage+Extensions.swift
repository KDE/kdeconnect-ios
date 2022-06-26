//
//  NetworkPackage+Extensions.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/4/22.
//

import Foundation

extension NetworkPackage {
    @objc
    static let allPackageTypes: [`Type`] = [
        .identity,
        .encrypted,
        .pair,
        .ping,
        .MPRIS,
        .share,
        .shareInternal,
        .clipboard,
        .clipboardConnect,
        .battery,
        .calendar,
        .contact,
        .batteryRequest,
        .findMyPhoneRequest,
        .mousePadRequest,
        .mousePadKeyboardState,
        .mousePadEcho,
        .presenter,
        .runCommandRequest,
        .runCommand,
    ]
    
    @objc
    static func description(for tag: Int) -> String {
        switch tag {
        case -3: return "UDPBROADCAST_TAG"
        case -2: return "TCPSERVER_TAG"
        case -1: return "PACKAGE_TAG_PAYLOAD"
        case  0: return "PACKAGE_TAG_NORMAL"
        case  1: return "PACKAGE_TAG_IDENTITY"
        case  2: return "PACKAGE_TAG_ENCRYPTED"
        case  3: return "PACKAGE_TAG_PAIR"
        case  4: return "PACKAGE_TAG_UNPAIR"
        case  5: return "PACKAGE_TAG_PING"
        case  6: return "PACKAGE_TAG_MPRIS"
        case  7: return "PACKAGE_TAG_SHARE"
        case  8: return "PACKAGE_TAG_CLIPBOARD"
        case  9: return "PACKAGE_TAG_MOUSEPAD"
        case 10: return "PACKAGE_TAG_BATTERY"
        case 11: return "PACKAGE_TAG_CALENDAR"
        case 12: return "PACKAGE_TAG_REMINDER"
        case 13: return "PACKAGE_TAG_CONTACT"
        default:
            Logger(category: "NetworkPackage").info("Describing unknown tag: \(tag)")
            return "PACKAGE_TAG_UNKNOWN(\(tag))"
        }
    }
    
    static let allPackageTags: [Int] = Array(-3...13)
}
