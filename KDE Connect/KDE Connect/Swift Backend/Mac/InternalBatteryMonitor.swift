//
//  InternalBatteryMonitor.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2023/08/29.
//

#if os(macOS)

import Foundation

// https://stackoverflow.com/questions/51275093/is-there-a-battery-level-did-change-notification-equivalent-for-kiopscurrentcapa

import Cocoa
import IOKit

// Swift doesn't support nested protocol(?!)
protocol BatteryInfoObserverProtocol: AnyObject {
    func batteryInfo(didChange info: BatteryInfo)
}

class BatteryInfo {
    typealias ObserverProtocol = BatteryInfoObserverProtocol
    struct Observation {
        weak var observer: ObserverProtocol?
    }
    
    static let shared = BatteryInfo()
    private init() {}
    
    private var notificationSource: CFRunLoopSource?
    var observers = [ObjectIdentifier: Observation]()
    
    private func startNotificationSource() {
        if notificationSource != nil {
            stopNotificationSource()
        }
        notificationSource = IOPSNotificationCreateRunLoopSource({ _ in
            BatteryInfo.shared.observers.forEach { (_, value) in
                value.observer?.batteryInfo(didChange: BatteryInfo.shared)
            }
        }, nil).takeRetainedValue() as CFRunLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationSource, .defaultMode)
    }
    private func stopNotificationSource() {
        guard let loop = notificationSource else { return }
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), loop, .defaultMode)
    }
    
    func addObserver(_ observer: ObserverProtocol) {
        if observers.count == 0 {
            startNotificationSource()
        }
        observers[ObjectIdentifier(observer)] = Observation(observer: observer)
    }
    func removeObserver(_ observer: ObserverProtocol) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
        if observers.count == 0 {
            stopNotificationSource()
        }
    }
    
    // Functions for retrieving different properties in the battery description...
}

class BatteryObserver: BatteryInfo.ObserverProtocol {
    var batteryInfoClosure: (_ info: BatteryInfo) -> ()
    
    func batteryInfo(didChange info: BatteryInfo) {
        self.batteryInfoClosure(info)
    }
    
    init(_ callback: @escaping (_ info: BatteryInfo) -> ()) {
        self.batteryInfoClosure = callback
        BatteryInfo.shared.addObserver(self)
    }

    deinit {
        BatteryInfo.shared.removeObserver(self)
    }
}

#endif
