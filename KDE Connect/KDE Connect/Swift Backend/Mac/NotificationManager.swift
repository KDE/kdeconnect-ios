//
//  NotificationManager.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/13.
//

#if os(macOS)

import Foundation
import UserNotifications
import SwiftUICore

class NotificationManager: ObservableObject {
    static let categories: Set<UNNotificationCategory> = {
        let acceptAction = UNNotificationAction(identifier: "PAIR_ACCEPT_ACTION", title: "Accept", options: [])
        let declineAction = UNNotificationAction(identifier: "PAIR_DECLINE_ACTION", title: "Decline", options: [])
        let foundAction = UNNotificationAction(identifier: "FMD_FOUND_ACTION", title: "Found", options: [])
        let normalCategory = UNNotificationCategory(identifier: "NORMAL", actions: [], intentIdentifiers: [])
        let successCategory = UNNotificationCategory(identifier: "SUCCESS", actions: [], intentIdentifiers: [])
        let failureCategory = UNNotificationCategory(identifier: "FAILURE", actions: [], intentIdentifiers: [])
        let pairRequestCategory = UNNotificationCategory(identifier: "PAIR_REQUEST", actions: [ acceptAction, declineAction ], intentIdentifiers: [], options: .customDismissAction)
        let findMyDeviceCategory = UNNotificationCategory(identifier: "FIND_MY_DEVICE", actions: [ foundAction ], intentIdentifiers: [], options: .customDismissAction)
        return [ normalCategory, successCategory, failureCategory, pairRequestCategory, findMyDeviceCategory ]
    }()
    @ObservedObject var inAppNotificationManager: InAppNotificationManager
    
    init(_ inAppNotificationManager: InAppNotificationManager) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories(Self.categories)
        self.inAppNotificationManager = inAppNotificationManager
    }
    
    func pairRequestPost(title: String, body: String, deviceId: String) {
        post(title: title, body: body, userInfo: [ "DEVICE_ID": deviceId ], categoryIdentifier: "PAIR_REQUEST")
    }
    
    func post(title: String, body: String, userInfo: [AnyHashable: Any] = [:], categoryIdentifier: String = "NORMAL", interruptionLevel: UNNotificationInterruptionLevel = .timeSensitive) {
        let prepared = NotificationManager.prepareRequest(title: title, body: body, userInfo: userInfo, categoryIdentifier: categoryIdentifier, interruptionLevel: interruptionLevel)
        inAppNotificationManager.addNotification(request: prepared.request, remover: prepared.remover)
        UNUserNotificationCenter.current().add(prepared.request)
    }
    
    static func prepareRequest(title: String, body: String, userInfo: [AnyHashable: Any] = [:], categoryIdentifier: String = "NORMAL", interruptionLevel: UNNotificationInterruptionLevel = .timeSensitive) -> (request: UNNotificationRequest, remover: () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        content.categoryIdentifier = categoryIdentifier
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        let remover = {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [ uuidString ])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [ uuidString ])
        }
        
        return (request, remover)
    }
}

#endif
