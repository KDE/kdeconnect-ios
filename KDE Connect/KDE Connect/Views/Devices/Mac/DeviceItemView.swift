//
//  DeviceIcon.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/11.
//

#if os(macOS)

import SwiftUI
import MediaPicker

struct DeviceItemView: View {
    let deviceId: String
    let parent: DevicesView?
    @Binding var deviceName: String
    let icon: Image
    let connState: DevicesView.ConnectionState
    let mockBatteryLevel: Int?
    @State var backgroundColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    init(deviceId: String, parent: DevicesView? = nil, deviceName: Binding<String>, icon: Image, connState: DevicesView.ConnectionState, mockBatteryLevel: Int? = nil) {
        self.deviceId = deviceId
        self.parent = parent
        self._deviceName = deviceName
        self.icon = icon
        self.connState = connState
        self.mockBatteryLevel = mockBatteryLevel
        switch (connState) {
        case .connected:
            self._backgroundColor = State(initialValue: .green)
        case .saved:
            self._backgroundColor = State(initialValue: .gray)
        case .visible:
            self._backgroundColor = State(initialValue: .cyan)
        case .local:
            self._backgroundColor = State(initialValue: .cyan)
        }
    }
    
    func getBackgroundColor(_ connState: DevicesView.ConnectionState) -> Color {
        switch (connState) {
        case .connected:
            return .green
        case .saved:
            return .gray
        case .visible:
            return .cyan
        case .local:
            return .cyan
        }
    }

    func isPluginAvailable(_ plugin: NetworkPacket.`Type`) -> Bool {
        if let pluginsEnableStatus = backgroundService.devices[deviceId]?.pluginsEnableStatus {
            if pluginsEnableStatus[plugin] != nil {
                return (backgroundService.devices[deviceId]?.isPaired() ?? false) && (backgroundService.devices[deviceId]?.isReachable() ?? false)
            }
            return false
        }
        return false
    }
    
    func isPaired() -> Bool {
        backgroundService.devices[self.deviceId]?.isPaired() ?? false
    }
    
    func isReachable() -> Bool {
        backgroundService.devices[self.deviceId]?.isReachable() ?? false
    }
    
    @State private var showingPhotosPicker: Bool = false
    @State private var showingFilePicker: Bool = false
    @State var chosenFileURLs: [URL] = []
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(parent?.clickedDeviceId == self.deviceId ? Color.accentColor : self.backgroundColor)
                if self.connState == .connected && self.isPluginAvailable(.batteryRequest) {
                    BatteryStatus(device: backgroundService._devices[self.deviceId]!) { battery in
                        Circle()
                            .trim(from: 0, to: CGFloat(battery.remoteChargeLevel) / 100)
                            .rotation(.degrees(-90))
                            .stroke(battery.statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .brightness(colorScheme == .light ? -0.1 : 0.1)
                        Text(String(battery.remoteChargeLevel) + "%")
                            .frame(maxWidth: 64, maxHeight: 64, alignment: .top)
                            .padding(.top, 2)
                            .font(.system(.footnote, design: .rounded).weight(.light))
                            .foregroundColor(.black)
                    }.onAppear {
                        (backgroundService._devices[self.deviceId]!._plugins[.batteryRequest] as! Battery)
                            .sendBatteryStatusOut()
                    }
                } else if self.mockBatteryLevel != nil {
                    Circle()
                        .trim(from: 0, to: CGFloat(self.mockBatteryLevel!) / 100)
                        .rotation(.degrees(-90))
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .brightness(colorScheme == .light ? -0.1 : 0.1)
                    Text(String(self.mockBatteryLevel!) + "%")
                        .frame(maxWidth: 64, maxHeight: 64, alignment: .top)
                        .padding(.top, 2)
                        .font(.system(.footnote, design: .rounded).weight(.light))
                        .foregroundColor(.black)
                }
                icon
                    .font(.system(size: 32))
                    .shadow(radius: 1)
            }
            .frame(width: 64, height: 64)
            HStack {
                Text(deviceName)
                    .multilineTextAlignment(.center)
                    .foregroundColor(parent?.clickedDeviceId == self.deviceId ? .white : Color.primary)
                    .padding(.horizontal, 8)
            }.background(RoundedRectangle(cornerRadius: 8)
                .fill(parent?.clickedDeviceId == self.deviceId ? .accentColor : Color.blue.opacity(0)))
        }.onChange(of: self.connState) { newValue in
            withAnimation {
                self.backgroundColor = getBackgroundColor(newValue)
            }
        }.onTapGesture {
            parent?.clickedDeviceId = self.deviceId
        }.onDrop(of: [.fileURL], isTargeted: nil) { providers in
            // Ref: https://stackoverflow.com/questions/60831260/swiftui-drag-and-drop-files
            if isPluginAvailable(.share) {
                var droppedFileURLs: [URL] = []
                providers.forEach { provider in
                    provider.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                        if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                            droppedFileURLs.append(url)
                            print("File drppped: ", url)
                        }
                    })
                }
                while droppedFileURLs.count != providers.count {
                    continue // block thread until all providers are proceeded
                }
                (backgroundService._devices[self.deviceId]!._plugins[.share] as! Share).prepAndInitFileSend(fileURLs: droppedFileURLs)
                return true
            } else {
                self.backgroundColor = .red
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.backgroundColor = getBackgroundColor(self.connState)
                    }
                }
                return false
            }
        }.contextMenu {
            if parent?.clickedDeviceId == self.deviceId {
                if self.connState == .connected || self.connState == .saved {
                    Button("Unpair") {
                        if self.isPaired() {
                            backgroundService.unpairDevice(self.deviceId)
                        }
                    }
                    
                    if self.isReachable() {
                        if self.isPluginAvailable(.ping) {
                            Button("Ping") {
                                (backgroundService.devices[self.deviceId]!.plugins[.ping] as! Ping).sendPing()
                            }
                        }
                        
                        if self.isPluginAvailable(.clipboard) {
                            Button("Push Local Clipboard") {
                                (backgroundService.devices[self.deviceId]!.plugins[.clipboard] as! Clipboard).sendClipboardContentOut()
                            }
                        }
                        
                        if self.isPluginAvailable(.share) {
                            // TODO: fix media sharing
//                                Button("Send Photos and Videos") {
//                                    showingPhotosPicker = true
//                                }
                            Button("Send Files") {
                                showingFilePicker = true
                            }
                        }
                    } else if self.connState == .connected {
                        Button("Plugins if reachable") {}.disabled(true)
                    }
                } else {
                    Button("Pair") {
                        backgroundService.pairDevice(self.deviceId)
                    }
                }
            }
        }.mediaImporter(isPresented: $showingPhotosPicker, allowedMediaTypes: .all, allowsMultipleSelection: true) { result in
            if case .success(let chosenMediaURLs) = result, !chosenMediaURLs.isEmpty {
                (backgroundService._devices[self.deviceId]!._plugins[.share] as! Share).prepAndInitFileSend(fileURLs: chosenMediaURLs)
            } else {
                print("Media Picker Result: \(result)")
            }
        }.fileImporter(isPresented: $showingFilePicker, allowedContentTypes: allUTTypes, allowsMultipleSelection: true) { result in
            do {
                chosenFileURLs = try result.get()
            } catch {
                print("Document Picker Error")
            }
            if (chosenFileURLs.count > 0) {
                (backgroundService._devices[self.deviceId]!._plugins[.share] as! Share).prepAndInitFileSend(fileURLs: chosenFileURLs)
            }
        }
    }
}

struct DeviceIcon_Previews: PreviewProvider {
    static var previews: some View {
        DeviceItemView(deviceId: "0", parent: nil, deviceName: .constant("TURX's MacBook Pro"), icon: Image(systemName: "laptopcomputer"), connState: .local)
    }
}

#endif
