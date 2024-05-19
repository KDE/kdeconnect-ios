//
//  NetworkPacket+Extensions.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/4/22.
//

import Foundation

extension NetworkPacket {
    @objc
    static let allPacketTypes: [`Type`] = [
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
        case -1: return "PACKET_TAG_PAYLOAD"
        case  0: return "PACKET_TAG_NORMAL"
        case  1: return "PACKET_TAG_IDENTITY"
        case  2: return "PACKET_TAG_ENCRYPTED"
        case  3: return "PACKET_TAG_PAIR"
        case  4: return "PACKET_TAG_UNPAIR"
        case  5: return "PACKET_TAG_PING"
        case  6: return "PACKET_TAG_MPRIS"
        case  7: return "PACKET_TAG_SHARE"
        case  8: return "PACKET_TAG_CLIPBOARD"
        case  9: return "PACKET_TAG_MOUSEPAD"
        case 10: return "PACKET_TAG_BATTERY"
        case 11: return "PACKET_TAG_CALENDAR"
        case 12: return "PACKET_TAG_REMINDER"
        case 13: return "PACKET_TAG_CONTACT"
        default:
            Logger(category: "NetworkPacket").info("Describing unknown tag: \(tag)")
            return "PACKET_TAG_UNKNOWN(\(tag))"
        }
    }
    
    static let allPacketTags: [Int] = Array(-3...13)
}
