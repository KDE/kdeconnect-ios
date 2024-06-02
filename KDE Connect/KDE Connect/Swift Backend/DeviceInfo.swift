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
    let type: DeviceType
    let cert: SecCertificate
    let protocolVersion: Int
    let incomingCapabilities: [NetworkPacket.`Type`]
    let outgoingCapabilities: [NetworkPacket.`Type`]

    init(id: String, name: String, type: DeviceType, cert: SecCertificate, protocolVersion: Int, incomingCapabilities: [NetworkPacket.`Type`], outgoingCapabilities: [NetworkPacket.`Type`]) {
        self.id = id
        self.name = name
        self.type = type
        self.cert = cert
        self.protocolVersion = protocolVersion
        self.incomingCapabilities = incomingCapabilities
        self.outgoingCapabilities = outgoingCapabilities
    }
    
    static func getOwn() -> DeviceInfo {
        return DeviceInfo(
            id: KdeConnectSettings.getUUID(),
            name: KdeConnectSettings.shared.deviceName,
            type: DeviceType.current,
            cert: CertificateService.shared.getHostCertificate(),
            protocolVersion: KdeConnectSettings.CurrentProtocolVersion,
            // FIXME: actually read what plugins are available
            incomingCapabilities: KdeConnectSettings.IncomingCapabilities,
            outgoingCapabilities: KdeConnectSettings.OutgoingCapabilities
        )
    }

    static func from(networkPacket: NetworkPacket, cert: SecCertificate) -> DeviceInfo {
        return DeviceInfo(
            id: networkPacket.string(forKey: "deviceId"),
            name: filterDeviceName(name: networkPacket.string(forKey: "deviceName")),
            type: strToDeviceType(str: networkPacket.string(forKey: "deviceType")),
            cert: cert,
            protocolVersion: networkPacket.integer(forKey: "protocolVersion"),
            incomingCapabilities: networkPacket.object(forKey: "outgoingCapabilities") as! [NetworkPacket.`Type`],
            outgoingCapabilities: networkPacket.object(forKey: "outgoingCapabilities") as! [NetworkPacket.`Type`]
        )
    }

    static func isValidIdentityPacket(networkPacket: NetworkPacket) -> Bool {
        return networkPacket.type == .identity &&
            !filterDeviceName(name: networkPacket.string(forKey: "deviceName")).isEmpty &&
            !networkPacket.string(forKey: "deviceId").isEmpty
    }
    
    static func filterDeviceName(name: String) -> String {
        // swiftlint:disable:next force_try
        let nameInvalidCharactersRegex = try! NSRegularExpression(pattern: "[\"',;:.!?()\\[\\]<>]")
        let nameMaxLength = 32
        
        return String(
            nameInvalidCharactersRegex.stringByReplacingMatches(
                in: name,
                range: NSRange(location: 0, length: name.count),
                withTemplate: ""
            )
            .prefix(nameMaxLength)
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
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
