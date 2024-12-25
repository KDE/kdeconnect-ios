//
//  ContentView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/11.
//

#if os(macOS)

import SwiftUI
import Combine

struct DevicesView: View {
    var connectedDevicesIds: [String] {
        viewModel.connectedDevices.keys.sorted()
    }
    
    var visibleDevicesIds: [String] {
        viewModel.visibleDevices.keys.sorted()
    }
    
    var savedDevicesIds: [String] {
        viewModel.savedDevices.keys.sorted()
    }
        
    @ObservedObject var viewModel: ConnectedDevicesViewModel = connectedDevicesViewModel
    
    @State public var clickedDeviceId: String
    @State private var counter: Int
    
    enum GenMode {
        case normal
        case empty
        case demo
        case hundred
    }
    let genMode: GenMode
    
    enum ConnectionState {
        case connected
        case saved
        case visible
        case local
    }
    
    init(genMode: GenMode = .normal) {
        self.clickedDeviceId = "-1"
        self.counter = 0
        self.genMode = genMode
    }
    
    static func getEmojiFromDeviceType(_ deviceType: DeviceType) -> String {
        switch (deviceType) {
        case .desktop:
            return "\u{1F5A5}"
        case .laptop:
            return "\u{1F4BB}"
        case .phone:
            return "\u{1F4F1}"
        case .tablet:
            return "\u{1F3AC}"
        case .appletv:
            return "\u{1F4FA}"
        case .unknown:
            return "\u{2754}"
        @unknown default:
            return "\u{2753}"
        }
    }
    
    func getDeviceIcons() -> [DeviceItemView] {
        switch (self.genMode) {
        case .empty:
            return []
        case .demo:
            return [
                DeviceItemView(deviceId: "1", parent: self, deviceName: .constant("My iPhone"), emoji: DevicesView.getEmojiFromDeviceType(.phone), connState: .connected, mockBatteryLevel: 67),
                DeviceItemView(deviceId: "2", parent: self, deviceName: .constant("My iMac"), emoji: DevicesView.getEmojiFromDeviceType(.desktop), connState: .connected),
                DeviceItemView(deviceId: "3", parent: self, deviceName: .constant("My MacBook"), emoji: DevicesView.getEmojiFromDeviceType(.laptop), connState: .saved),
                DeviceItemView(deviceId: "4", parent: self, deviceName: .constant("My iPad"), emoji: DevicesView.getEmojiFromDeviceType(.tablet), connState: .visible),
                DeviceItemView(deviceId: "5", parent:self, deviceName: .constant("My Apple TV"), emoji: DevicesView.getEmojiFromDeviceType(.appletv), connState: .visible),
                DeviceItemView(deviceId: "6", deviceName: .constant("Unknown device"), emoji: DevicesView.getEmojiFromDeviceType(.unknown), connState: .visible)
            ]
        case .hundred:
            var deviceIcons = [DeviceItemView]()
            for demoDeviceId in 1...100 {
                deviceIcons.append(DeviceItemView(deviceId: String(demoDeviceId), parent: self, deviceName: .constant(String(demoDeviceId)), emoji: "\u{1F4F1}", connState: .saved))
            }
            return deviceIcons
        case .normal:
            var deviceIcons = [DeviceItemView]()
            for key in connectedDevicesIds {
                deviceIcons.append(DeviceItemView(
                    deviceId: key,
                    parent: self,
                    deviceName: .constant(viewModel.connectedDevices[key] ?? "Unknown device"),
                    emoji: DevicesView.getEmojiFromDeviceType(backgroundService._devices[key]?._deviceInfo.type ?? .unknown),
                    connState: .connected
                ))
            }
            for key in savedDevicesIds {
                deviceIcons.append(DeviceItemView(
                    deviceId: key,
                    parent: self,
                    deviceName: .constant(viewModel.savedDevices[key] ?? "Unknown device"),
                    emoji: DevicesView.getEmojiFromDeviceType(backgroundService._devices[key]?._deviceInfo.type ?? .unknown),
                    connState: .saved
                ))
            }
            for key in visibleDevicesIds {
                deviceIcons.append(DeviceItemView(
                    deviceId: key,
                    parent: self,
                    deviceName: .constant(viewModel.visibleDevices[key] ?? "Unknown device"),
                    emoji: DevicesView.getEmojiFromDeviceType(backgroundService._devices[key]?._deviceInfo.type ?? .unknown),
                    connState: .visible
                ))
            }
            return deviceIcons
        }
    }
    
    var body: some View {
        if getDeviceIcons().isEmpty {
            VStack {
                Spacer()
                Text("No device discovered in the current network.")
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView(.vertical) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128))]) {
                    ForEach(getDeviceIcons(), id: \.deviceId) {deviceIcon in
                        deviceIcon
                            .padding(.all)
                    }
                }
            }
            .padding(.all)
            .onTapGesture {
                self.clickedDeviceId = "-1"
            }
        }
    }
}

struct DevicesView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesView(genMode: .demo)
    }
}

#endif
