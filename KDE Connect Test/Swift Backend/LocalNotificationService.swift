//
//  LocalNotificationService.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

//import SwiftUI
//// TODO: Code does not run when app is in the background, not sure how we're gonna do local notificatio
//// to be honest
//class LocalNotificationService : ObservableObject {
//    var notifications = [Notification]()
//
//    init() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if (granted && error == nil) {
//                print("Notification permission granted")
//            } else {
//                print("Notification permission NOT granted")
//            }
//        }
//    }
//
//    func sendNotification(title: String, subtitle: String?, body: String, launchIn: Double) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        if let subtitle = subtitle {
//            content.subtitle = subtitle
//        }
//        content.body = body
//        // TODO: Maybe add "attachments" with files to give the notifications more visual flair???
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: launchIn, repeats: false)
//        let request = UNNotificationRequest(identifier: "localNotification", content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request)
//    }
//}
