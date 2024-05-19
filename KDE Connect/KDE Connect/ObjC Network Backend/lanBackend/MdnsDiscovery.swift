/*
 * SPDX-FileCopyrightText: 2023 Albert Vaca Cintora <albertvaka@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import Foundation
import Network

@objc
public class MDNSDiscovery: NSObject, NetServiceDelegate {
    private static let serviceType = "_kdeconnect._udp"
    private static let domain = ""
    private var browser: NWBrowser?
    private var service: NetService?
    private var tcpPort: UInt16 = 0

    private static let logger = Logger()

    @objc
    public func startDiscovering() {
        if (self.browser != nil) {
            Self.logger.debug("MDNS Already discovering")
            return
        }
        Self.logger.debug("MDNS Start discovering")
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: Self.serviceType, domain: Self.domain), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .failed(let error):
                Self.logger.error("MDNS Discovery failed with \(error)")
            case .ready:
                Self.logger.info("MDNS Discovery ready with \(browser.browseResults.count) results")
                self.processBrowserResults(browser.browseResults)
            case .cancelled:
                Self.logger.info("MDNS Discovery cancelled")
            case .waiting(let error):
                Self.logger.info("MDNS Discovery waiting: \(error)")
            case .setup:
                break
            @unknown default:
                break
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Self.logger.info("MDNS Discovery found \(results.count) results")
            self?.processBrowserResults(results)
        }

        browser.start(queue: .main)
    }

    @objc
    public func startAnnouncing(tcpPort: UInt16) {
        if (self.service != nil) {
            Self.logger.debug("MDNS Already announcing")
            return
        }
        Self.logger.debug("MDNS Start announcing")

        self.tcpPort = tcpPort

        let ownDeviceInfo = DeviceInfo.getDeviceInfo()
        // We can't use NWListener until allowLocalEndpointReuse is fixed
        // https://developer.apple.com/forums/thread/129452
        // https://openradar.appspot.com/FB8658821
        let service = NetService(
            domain: Self.domain,
            type: Self.serviceType,
            name: ownDeviceInfo.id,
            port: Int32(tcpPort)
        )
        self.service = service
        service.setTXTRecord(ownDeviceInfo.txtRecordData)
        service.includesPeerToPeer = true
        service.delegate = self
        service.publish()
    }

    @objc
    public func stopDiscovering() {
        Self.logger.debug("MDNS Stop discovering")
        browser?.cancel()
        browser = nil
    }

    @objc
    public func stopAnnouncing() {
        Self.logger.debug("MDNS Stop announcing")
        service?.stop()
        service = nil
    }

    deinit {
        stopDiscovering()
        stopAnnouncing()
    }

    public func netServiceDidPublish(_ sender: NetService) {
        Self.logger.debug("MDNS announced \(sender.name)")
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        Self.logger.fault("MDNS announcing failed with \(NetService.error(from: errorDict))")
    }

    public func netServiceDidStop(_ sender: NetService) {
        Self.logger.debug("MDNS stopped anouncing")
    }

    private func processBrowserResults(_ results: Set<NWBrowser.Result>) {
        let ownDeviceId = NetworkPacket.getUUID()
        for result in results {
            if case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                if name == ownDeviceId {
                    Self.logger.info("MDNS ignoring myself")
                    continue
                }
                Self.logger.info("MDNS found \(name)")
                let connection = NWConnection(to: result.endpoint, using: .udp)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        Self.logger.info("MDNS sending identity packet to \(result.endpoint.debugDescription)")
                        let np = NetworkPacket.createIdentityPacket(withTCPPort: self.tcpPort)
                        let data = np.serialize()
                        connection.send(content: data, completion: .contentProcessed { error in
                            if (error != nil) {
                                Self.logger.error("MDNS send UDP failed: \(error.debugDescription)")
                            }
                        })
                    case .failed(let error):
                        Self.logger.error("MDNS Connection failed: \(error.debugDescription)")
                    case .cancelled:
                        Self.logger.info("MDNS Connection cancelled")
                    case .waiting(let error):
                        Self.logger.info("MDNS Connection waiting: \(error)")
                    case .setup:
                        break
                    case .preparing:
                        break
                    @unknown default:
                        break
                    }
                }
                connection.start(queue: .global())
            }
        }
    }

    private struct DeviceInfo {
        let id: String
        let name: String
        let type: String
        let protocolVersion: Int

        fileprivate static func getDeviceInfo() -> Self {
            let packet = NetworkPacket.createIdentityPacket(withTCPPort: 0)
            return Self(
                id: packet.object(forKey: "deviceId") as! String,
                name: packet.object(forKey: "deviceName") as! String,
                type: packet.object(forKey: "deviceType") as! String,
                protocolVersion: packet.integer(forKey: "protocolVersion")
            )
        }

        fileprivate var txtRecordData: Data {
            let record = [
                "id": Data(id.utf8),
                "name": Data(name.utf8),
                "type": Data(type.utf8),
                "protocol": Data("\(protocolVersion)".utf8),
            ]
            let data = NetService.data(fromTXTRecord: record)
            switch data.count {
            case ...512:
                logger.debug("TXT record size: \(data.count) bytes, okay")
            case ...65535:
                logger.error("TXT record size: \(data.count) bytes, exceeds the maximum RECOMMENDED size of 512 bytes")
            default:
                logger.fault("TXT record size: \(data.count) bytes, exceeds the maximum size of 65535 bytes")
            }
            return data
        }
    }
}

extension NetService {
    static func error(from errorDict: [String: NSNumber]) -> NSError {
        let code = errorDict[NetService.errorCode]
            .flatMap { NetService.ErrorCode(rawValue: $0.intValue) }
            ?? .unknownError
        return NSError(domain: NetService.errorDomain, code: code.rawValue)
    }
}
