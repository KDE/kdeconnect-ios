/*
 * SPDX-FileCopyrightText: 2024 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

@objc
public enum DeviceType: Int {
    case unknown = 0
    case desktop = 1
    case laptop = 2
    case phone = 3
    case tablet = 4
    case appletv = 5
}

@objc
@objcMembers
class DeviceInfo: NSObject {
    let id: String
    let name: String
    let type: DeviceType // DeviceType2Str
    let protocolVersion: Int
    let incomingCapabilities: [NetworkPacket.`Type`]
    let outgoingCapabilities: [NetworkPacket.`Type`]

    init(id: String, protocolVersion: Int, name: String, type: DeviceType, incomingCapabilities: [NetworkPacket.`Type`], outgoingCapabilities: [NetworkPacket.`Type`]) {
        self.id = id
        self.protocolVersion = protocolVersion
        self.name = name
        self.type = type
        self.incomingCapabilities = incomingCapabilities
        self.outgoingCapabilities = outgoingCapabilities
    }
    
    static func getOwn() -> DeviceInfo {
        return DeviceInfo(
            id: KdeConnectSettings.getUUID(),
            protocolVersion: KdeConnectSettings.CurrentProtocolVersion,
            name: KdeConnectSettings.shared.deviceName,
            type: DeviceType.current,
            // FIXME: actually read what plugins are available
            incomingCapabilities: KdeConnectSettings.IncomingCapabilities,
            outgoingCapabilities: KdeConnectSettings.OutgoingCapabilities
        )
    }

    static func from(networkPacket: NetworkPacket) -> DeviceInfo {
        return DeviceInfo(
            id: networkPacket.string(forKey: "deviceId"),
            protocolVersion: networkPacket.integer(forKey: "protocolVersion"),
            name: networkPacket.string(forKey: "deviceName"),
            type: strToDeviceType(str: networkPacket.string(forKey: "deviceType")),
            incomingCapabilities: networkPacket.object(forKey: "outgoingCapabilities") as! [NetworkPacket.`Type`],
            outgoingCapabilities: networkPacket.object(forKey: "outgoingCapabilities") as! [NetworkPacket.`Type`]
        )
    }
    
    func getTypeAsString() -> String {
        return Self.deviceTypeToStr(deviceType: type)
    }
    
    static func deviceTypeToStr(deviceType: DeviceType) -> String {
        switch deviceType {
        case .desktop:
            return "desktop"
        case .laptop:
            return "laptop"
        case .phone:
            return "phone"
        case .tablet:
            return "tablet"
        case .appletv:
            return "tv"
        case .unknown:
            return "unknown"
        }
    }
    
    static func strToDeviceType(str: String) -> DeviceType {
        switch str {
        case "desktop":
            return .desktop
        case "laptop":
            return .laptop
        case "phone":
            return .phone
        case "tablet":
            return .tablet
        case "tv":
            return .appletv
        default:
            return .desktop
        }
    }
}
