//
//  NotificationView.swift
//  KDE Connect
//
//  Created by TURX on 2025/01/03.
//

#if os(macOS)

import SwiftUI
import UserNotifications

class InAppNotificationManager: ObservableObject {
    @Published var requests: [UNNotificationRequest]
    @Published var removers: [() -> Void]  // remove from UNUserNotificationCenter with UUID
    
    init(requests: [UNNotificationRequest] = [], removers: [() -> Void] = []) {
        self.requests = requests
        self.removers = removers
    }
    
    convenience init(mode: String) {
        if mode == "demo" {
            let demoInAppNotifications = Self.genDemoInAppNotifications()
            self.init(requests: demoInAppNotifications.requests, removers: demoInAppNotifications.removers)
        } else {
            self.init(requests: [], removers: [])
        }
    }
    
    func addNotification(request: UNNotificationRequest, remover: @escaping () -> Void) {
        self.requests.append(request)
        self.removers.append(remover)
    }
    
    func removeNotification(at index: Int) {
        self.requests.remove(at: index)
        self.removers[index]()
        self.removers.remove(at: index)
    }
    
    static func genDemoInAppNotifications() -> (requests: [UNNotificationRequest], removers: [() -> Void]) {
        let builders = [
            ("Incoming Pairing Request", "iPhone wants to pair with this device", "PAIR_REQUEST"),
            ("Pairing Timed Out", "Pairing with iPhone failed", "FAILURE"),
            ("Pairing Complete", "Pairing with iPhone succeeded", "SUCCESS"),
            ("Pairing Rejected", "Pairing with iPhone failed", "FAILURE"),
            ("Ping!", "Ping received from a connected device", "NORMAL"),
            ("Find My Mac", "Find My Mac initiated from a remote device", "FIND_MY_DEVICE"),
        ]
        var requests: [UNNotificationRequest] = []
        var removers: [() -> Void] = []
        builders.forEach { builder in
            let title = builder.0
            let body = builder.1
            let identifier = builder.2
            let prepared = NotificationManager.prepareRequest(title: title, body: body, categoryIdentifier: identifier)
            requests.append(prepared.request)
            removers.append(prepared.remover)
        }
        return (requests, removers)
    }
}

struct NotificationView: View {
    @EnvironmentObject var inAppNotificationManager: InAppNotificationManager
    @State var backgroundColor: Color = .clear
    @State var selectedNotificationIndex: Int = 0
    @State var selectedRequest: UNNotificationRequest?
    @State var selectedRemover: (() -> Void) = { }
    @State var prevButtonEnabled: Bool = false
    @State var nextButtonEnabled: Bool = false
    @State var actions: [(title: String, action: () -> Void)] = []
    let notificationCenter = NotificationCenter.default
    
    func updateSelection() {
        if selectedNotificationIndex >= inAppNotificationManager.requests.count {
            selectedNotificationIndex = 0
            selectedRequest = nil
            selectedRemover = { }
            return
        }
        selectedRequest = inAppNotificationManager.requests[selectedNotificationIndex]
        selectedRemover = { inAppNotificationManager.removeNotification(at: selectedNotificationIndex) }
        let selectedCategoryActions = NotificationManager.categories
            .first { $0.identifier == selectedRequest!.content.categoryIdentifier }!
            .actions
        backgroundColor = switch selectedRequest!.content.categoryIdentifier {
            case "PAIR_REQUEST": .yellow
            case "NORMAL": .secondary
            case "SUCCESS": .green
            case "FAILURE": .red
            case "FIND_MY_DEVICE": .yellow
            default: .clear
            }
        actions = if selectedCategoryActions.isEmpty {
            [("Dismiss", selectedRemover)]
        } else {
            selectedCategoryActions.map { action in
                (action.title, {
                    // same as AppDelegate
                    let userInfo = selectedRequest!.content.userInfo
                    let deviceId = userInfo["DEVICE_ID"] as? String ?? nil
                    switch action.identifier {
                    case "PAIR_ACCEPT_ACTION":
                        backgroundService.pairDevice(deviceId)
                    case "PAIR_DECLINE_ACTION":
                        backgroundService.unpairDevice(deviceId)
                    case "FMD_FOUND_ACTION":
                        MainView.updateFindMyPhoneTimer(isRunning: false)
                    default:
                        break
                    }
                    selectedRemover()
                })
            }
        }
        
        selectedNotificationIndex = min(selectedNotificationIndex, inAppNotificationManager.requests.count - 1)
        selectedNotificationIndex = max(selectedNotificationIndex, 0)
        prevButtonEnabled = ( selectedNotificationIndex > 0 )
        nextButtonEnabled = ( selectedNotificationIndex < inAppNotificationManager.requests.count - 1 )
    }
    
    func gotoNextNotification() {
        selectedNotificationIndex += 1
        updateSelection()
    }
    
    func gotoPrevNotification() {
        selectedNotificationIndex -= 1
        updateSelection()
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("\(selectedNotificationIndex + 1) / \(inAppNotificationManager.requests.count)")
                    Spacer()
                    Text(selectedRequest?.content.title ?? "")
                    Spacer()
                    Button("", systemImage: "chevron.left", action: gotoPrevNotification)
                        .buttonStyle(.borderless)
                        .disabled(!prevButtonEnabled)
                    Button("", systemImage: "chevron.right", action: gotoNextNotification)
                        .buttonStyle(.borderless)
                        .disabled(!nextButtonEnabled)
                }
                Text(selectedRequest?.content.body ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Spacer()
                    ForEach(actions.indices, id: \.self) { index in
                        Button(actions[index].title) { actions[index].action() }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                backgroundColor.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .onAppear {
                updateSelection()
            }
            .onChange(of: inAppNotificationManager.requests) { _ in
                updateSelection()
            }
        }
        .padding(4)
    }
}

#Preview {
    NotificationView()
        .environmentObject(InAppNotificationManager(mode: "demo"))
}

#endif
