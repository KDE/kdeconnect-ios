/*
 * SPDX-FileCopyrightText: 2023 Apollo Zhu <public-apollonian@outlook.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  NetworkChangeMonitor.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/1/23.
//

import Network
import Combine

@objc
public protocol NetworkChangeMonitorDelegate: AnyObject {
    func onNetworkChange()
}

@objcMembers
public class NetworkChangeMonitor: NSObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "org.kde.kdeconnect.queue.NetworkChangeMonitor")
    private var isMonitoring = false
    private let publisher = PassthroughSubject<NWPath, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let logger = Logger()
    
    public weak var delegate: NetworkChangeMonitorDelegate?
    
    public func startMonitoring() {
        isMonitoring = true
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            self?.publisher.send(path)
        }
        publisher
            .removeDuplicates {
                // The default NWPath equality changes even for the same network
                // so use a less strict equality comparison that's good enough
                $0.status == $1.status
                && $0.isExpensive == $1.isConstrained
                && $0.isConstrained == $1.isConstrained
                && $0.gateways == $1.gateways
                && $0.supportsDNS == $1.supportsDNS
                && $0.supportsIPv4 == $1.supportsIPv4
                && $0.supportsIPv6 == $1.supportsIPv6
            }
            .dropFirst() // ignore when first open app
            .sink { [weak self, logger] path in
                logger.debug("\(path.debugDescription)")
                self?.delegate?.onNetworkChange()
            }
            .store(in: &cancellables)
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}
