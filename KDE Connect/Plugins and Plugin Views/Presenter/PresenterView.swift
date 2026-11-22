/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  PresenterView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-13.
//

#if !os(macOS)

import SwiftUI
import UIKit.UIDevice

struct PresenterView: View {
    let detailsDeviceId: String
    
    /// For translating gyroscope to coordinates
    @State var currentBroadcastingDeviceOrientation = UIDevice.current.orientation
    /// For optimizing layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var pointerSensitivityFromSlider: Float = 0.07 // defaults to the middle
    @State private var showingSensitivitySlider: Bool = false
    private let logger = Logger()

    var body: some View {
        VStack {
            if horizontalSizeClass == .regular {
                landscapePresenterView
            } else {
                portraitPresenterView
            }
            
            if showingSensitivitySlider {
                Slider(
                    value: $pointerSensitivityFromSlider,
                    in: 0.05...0.09
                ) {
                    Text("Pointer Sensitivity")
                } minimumValueLabel: {
                    Image(systemName: "minus")
                } maximumValueLabel: {
                    Image(systemName: "plus")
                } onEditingChanged: { editing in
                    if (!editing) {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        saveDeviceToUserDefaults(deviceId: detailsDeviceId)
                    }
                }
                .padding(.all, 15)
                .transition(.opacity)
                .onChange(of: pointerSensitivityFromSlider) { value in
                    backgroundService._devices[detailsDeviceId]!._pointerSensitivity = value
                }
            }
        }
        .navigationTitle("Slideshow Remote")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: sendGoFullscreenAction) {
                        Label("Go FullScreen", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    
                    Button(action: sendEscapeKey) {
                        Label("Exit Presentation", systemImage: "arrowshape.turn.up.left")
                    }
                    
                    Button {
                        withAnimation {
                            showingSensitivitySlider.toggle()
                        }
                    } label: {
                        Label {
                            if showingSensitivitySlider {
                                Text("Hide Sensitivity Slider")
                            } else {
                                Text("Show Sensitivity Slider")
                            }
                        } icon: {
                            Image(systemName: "cursorarrow.motionlines")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            switch currentBroadcastingDeviceOrientation {
            case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
                logger.debug("PresenterView appeared with defined orientation")
            case .faceUp, .faceDown, .unknown:
                currentBroadcastingDeviceOrientation = .portrait
                logger.debug("PresenterView appeared without defined orientation, defaulting to portrait")
            @unknown default:
                currentBroadcastingDeviceOrientation = .portrait
                logger.debug("PresenterView appeared without defined orientation, defaulting to portrait")
            }
        }
        .onDisappear {
            stopGyroAndPointer()
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newOrientation = UIDevice.current.orientation
            switch newOrientation {
            case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
                currentBroadcastingDeviceOrientation = newOrientation
            case .faceUp, .faceDown, .unknown:
                break
            @unknown default:
                break
            }
        }
    }
    
    private var hasPointer: Bool {
        let type = backgroundService._devices[detailsDeviceId]!._deviceInfo.type
        return type == .desktop || type == .laptop
    }

    var portraitPresenterView: some View {
        VStack(spacing: 10) {
            if hasPointer {
                pointerTile
            }
            HStack(spacing: 10) {
                previousSlideButton
                nextSlideButton
            }
        }
        .padding()
    }

    var landscapePresenterView: some View {
        HStack(spacing: 10) {
            previousSlideButton
            if hasPointer {
                pointerTile
            }
            nextSlideButton
        }
        .padding()
    }

    private var pointerTile: some View {
        tile(systemName: "wand.and.rays", iconSize: CGSize(width: 110, height: 110), cornerRadius: 50)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        startGyroAndPointer()
                    }
                    .onEnded { _ in
                        stopGyroAndPointer()
                    }
            )
    }

    private var previousSlideButton: some View {
        Button(action: sendGoPreviousSlideAction) {
            tile(systemName: "backward.end", iconSize: CGSize(width: 40, height: 50), cornerRadius: 20)
        }
    }

    private var nextSlideButton: some View {
        Button(action: sendGoNextSlideAction) {
            tile(systemName: "forward.end", iconSize: CGSize(width: 40, height: 50), cornerRadius: 20)
        }
    }

    /// An orange tile that fills all the available space, with an icon centered in it.
    private func tile(systemName: String, iconSize: CGSize, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.orange)
            .overlay {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: iconSize.width, maxHeight: iconSize.height)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    func startGyroAndPointer() {
            // UIImpactFeedbackGenerator(style: .heavy).impactOcurred()
            motionManager.startGyroUpdates(to: .main) { data, _ in
                guard let data = data else { return }
                var dxToSend: Float = 0.0 //
                var dyToSend: Float = 0.0
                switch currentBroadcastingDeviceOrientation {
                case .portrait:
                    dxToSend = -(Float(data.rotationRate.z) * pointerSensitivityFromSlider)
                    dyToSend = -(Float(data.rotationRate.x) * pointerSensitivityFromSlider)
                case .portraitUpsideDown:
                    dxToSend = -(Float(data.rotationRate.z) * pointerSensitivityFromSlider)
                    dyToSend =  (Float(data.rotationRate.x) * pointerSensitivityFromSlider)
                case .landscapeLeft:
                    dxToSend = -(Float(data.rotationRate.z) * pointerSensitivityFromSlider)
                    dyToSend =  (Float(data.rotationRate.y) * pointerSensitivityFromSlider)
                case .landscapeRight:
                    dxToSend = -(Float(data.rotationRate.z) * pointerSensitivityFromSlider)
                    dyToSend = -(Float(data.rotationRate.y) * pointerSensitivityFromSlider)
                case .faceUp, .faceDown, .unknown:
                    break
                @unknown default:
                    break
                }
                if dxToSend != 0.0 || dyToSend != 0.0 {
                    (backgroundService.devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendPointerPosition(dx: dxToSend, dy: dyToSend)
                }
            }
        }
    
    func stopGyroAndPointer() {
        (backgroundService._devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendStopPointer()
        motionManager.stopGyroUpdates()
    }
    
    func sendGoFullscreenAction() {
        notificationHapticsGenerator.notificationOccurred(.success)
        (backgroundService._devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendFullscreen()
    }
    
    func sendEscapeKey() {
        notificationHapticsGenerator.notificationOccurred(.warning)
        (backgroundService._devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendEsc()
    }
    
    func sendGoPreviousSlideAction() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        (backgroundService._devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendPrevious()
    }
    
    func sendGoNextSlideAction() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        (backgroundService._devices[detailsDeviceId]!._plugins[.presenter] as! Presenter).sendNext()
    }
}

struct PresenterView_Previews: PreviewProvider {
    static var previews: some View {
        PresenterView(detailsDeviceId: "Hi")
    }
}

#endif
