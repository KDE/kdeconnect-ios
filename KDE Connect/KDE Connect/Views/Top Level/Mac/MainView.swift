//
//  ContentView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/11.
//

#if os(macOS)

import SwiftUI
import Combine
import AVFoundation

struct MainView: View {
    static var mainViewSingleton: Self?
    var deviceView: DevicesView?
    var notificationView: NotificationView?
    @Environment(\.openWindow) private var openWindow
    @State static var findMyPhoneTimer = Empty<Date, Never>().eraseToAnyPublisher()
    @ObservedObject var selfData = KdeConnectSettings.shared
    @State var disabledSingletonConflict: Bool
    @Binding var grantedNotificationPermission: Bool
    @Binding var showingHelpWindow: Bool
    @EnvironmentObject var inAppNotificationManager: InAppNotificationManager
    
    init(grantedNotificationPermission: Binding<Bool>, showingHelpWindow: Binding<Bool>) {
        self.deviceView = DevicesView()
        self.notificationView = NotificationView()
        self._disabledSingletonConflict = State(initialValue: false)
        self._grantedNotificationPermission = grantedNotificationPermission
        self._showingHelpWindow = showingHelpWindow
    }
    
    func helpButton(_ action: @escaping () -> Void) -> some View {
        // ref: https://blog.urtti.com/creating-a-macos-help-button-in-swiftui
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(Color(NSColor.controlShadowColor), lineWidth: 0.5)
                    .background(Circle().foregroundColor(Color(NSColor.controlColor)))
                    .shadow(color: Color(NSColor.controlShadowColor).opacity(0.3), radius: 1)
                    .frame(width: 20, height: 20)
                Text("?").font(.system(size: 15, weight: .medium ))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        if !self.disabledSingletonConflict {
            VStack {
                if !self.grantedNotificationPermission && !inAppNotificationManager.requests.isEmpty {
                    notificationView
                }
                deviceView
                Divider()
                HStack {
                    Spacer().frame(maxWidth: .infinity)
                    HStack {
                        DeviceItemView(deviceId: "0", parent: nil, deviceName: $selfData.deviceName, icon: DevicesView.getIconFromDeviceType(DeviceType.current), connState: .local)
                            .padding(.all)
                    }.frame(maxWidth: .infinity)
                    if !self.showingHelpWindow {
                        helpButton {
                            self.showingHelpWindow = true
                            openWindow(id: "help")
                        }
                        .padding(.all)
                        .frame(maxWidth: .infinity, maxHeight: 128, alignment: .bottomTrailing)
                    } else {
                        Spacer().frame(maxWidth: .infinity, maxHeight: 128, alignment: .bottomTrailing)
                    }
                }
            }
            .refreshable {
                refreshDiscoveryAndList()
            }
            .onAppear {
                self.disabledSingletonConflict = Self.mainViewSingleton != nil
                if !self.disabledSingletonConflict {
                    Self.mainViewSingleton = self
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceivePairRequestNotification, object: nil)
                .receive(on: RunLoop.main)) { notification in
                    onPairRequest(fromDeviceWithID: notification.userInfo?["deviceID"] as? String)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pairRequestTimedOutNotification, object: nil)
                        .receive(on: RunLoop.main)) { notification in
                onPairTimeout(toDeviceWithID: notification.userInfo?["deviceID"] as? String)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pairRequestSucceedNotification, object: nil)
                        .receive(on: RunLoop.main)) { notification in
                onPairSuccess(withDeviceWithID: notification.userInfo?["deviceID"] as? String)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pairRequestRejectedNotification, object: nil)
                        .receive(on: RunLoop.main)) { notification in
                onPairRejected(byDeviceWithID: notification.userInfo?["deviceID"] as? String)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceivePingNotification, object: nil)
                        .receive(on: RunLoop.main)) { _ in
                showPingAlert()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveFindMyPhoneRequestNotification, object: nil)
                        .receive(on: RunLoop.main)) { _ in
                showFindMyPhoneAlert()
                Self.updateFindMyPhoneTimer(isRunning: true) // TODO: alert sound does not work
            }
            .onReceive(Self.findMyPhoneTimer) { _ in
                SystemSound.calendarAlert.play()
            }
        } else {
            ErrorView("There cannot be multiple main windows. Please close this window to proceed.")
        }
    }
    
    @EnvironmentObject var notificationManager: NotificationManager
    
    func currentPairingDeviceName(id: String) -> String? {
        backgroundService._devices[id]?._deviceInfo.name
    }

    func deleteDevice(at offsets: IndexSet) {
        offsets
            .map { (offset: $0, id: deviceView!.savedDevicesIds[$0]) }
            .forEach { device in
                // TODO: Update Device.m to indicate nullability
                let name = backgroundService._devices[device.id]!._deviceInfo.name
                print("Remembered device \(name) removed at index \(device.offset)")
                backgroundService.unpairDevice(device.id)
            }
    }
    
    func onPairRequest(fromDeviceWithID deviceId: String!) {
        notificationManager.pairRequestPost(title: "Incoming Pairing Request", body: "\(currentPairingDeviceName(id: deviceId) ?? "Unknown device") wants to pair with this device", deviceId: deviceId)
    }
    
    func onPairTimeout(toDeviceWithID deviceId: String!) {
        notificationManager.post(title: "Pairing Timed Out", body: "Pairing with \(currentPairingDeviceName(id: deviceId) ?? "Unknown device") failed", categoryIdentifier: "FAILURE")
    }
    
    func onPairSuccess(withDeviceWithID deviceId: String!) {
        notificationManager.post(title: "Pairing Complete", body: "Pairing with \(currentPairingDeviceName(id: deviceId) ?? "Unknown device") succeeded", categoryIdentifier: "SUCCESS")
    }
    
    func onPairRejected(byDeviceWithID deviceId: String!) {
        notificationManager.post(title: "Pairing Rejected", body: "Pairing with \(currentPairingDeviceName(id: deviceId) ?? "Unknown device") failed", categoryIdentifier: "FAILURE")
    }
    
    func showPingAlert() {
        SystemSound.smsReceived.play()
        notificationManager.post(title: "Ping!", body: "Ping received from a connected device", categoryIdentifier: "NORMAL")
    }
    
    func showFindMyPhoneAlert() {
        notificationManager.post(title: "Find My Mac", body: "Find My Mac initiated from a remote device", categoryIdentifier: "FIND_MY_DEVICE", interruptionLevel: .critical)
        // TODO: notification does not stay
    }
    
    static func updateFindMyPhoneTimer(isRunning: Bool) {
        if isRunning {
            Self.findMyPhoneTimer = Deferred {
                Just(Date())
            }
            .append(Timer.publish(every: 4, on: .main, in: .common).autoconnect())
            .eraseToAnyPublisher()
        } else {
            Self.findMyPhoneTimer = Empty<Date, Never>().eraseToAnyPublisher()
        }
    }
    
    func refreshDiscoveryAndList() {
        withAnimation {
            backgroundService.refreshDiscovery()
            broadcastBatteryStatusAllDevices()
            requestBatteryStatusAllDevices()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(grantedNotificationPermission: .constant(false), showingHelpWindow: .constant(false))
    }
}

#endif
