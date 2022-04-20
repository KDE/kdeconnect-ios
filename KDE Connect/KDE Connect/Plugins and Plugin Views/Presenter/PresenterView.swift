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

import SwiftUI
import UIKit.UIDevice

struct PresenterView: View {
    let detailsDeviceId: String
    
    @State var currentBroadcastingDeviceOrientation = UIDevice.current.orientation
    
    @State private var pointerSensitivityFromSlider: Float = 0.07 // defaults to the middle
    @State private var showingSensitivitySlider: Bool = false

    var body: some View {
        VStack { // TODO: This is a rough first implementation of getting it "optimized" for different displays and orientations. But let's test if the gyroscope backend even works first
            switch currentBroadcastingDeviceOrientation {
            case .landscapeLeft, .landscapeRight:
                landscapePresenterView
            case .portrait, .portraitUpsideDown, .faceUp, .faceDown, .unknown:
                portraitPresenterView
            @unknown default:
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
        .navigationBarItems(trailing:
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
                    Label("\((showingSensitivitySlider) ? "Hide" : "Show") Sensitivity Slider",
                          systemImage: "cursorarrow.motionlines")
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            switch currentBroadcastingDeviceOrientation {
            case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
                print("PresenterView appeared with defined orientation")
                break
            case .faceUp, .faceDown, .unknown:
                currentBroadcastingDeviceOrientation = .portrait
                print("PresenterView appeared without defined orientation, defaulting to portrait")
            @unknown default:
                currentBroadcastingDeviceOrientation = .portrait
                print("PresenterView appeared without defined orientation, defaulting to portrait")
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
    
    var portraitPresenterView: some View {
        Group {
            if backgroundService._devices[detailsDeviceId]!._type == .desktop {
                Image(systemName: "wand.and.rays")
                    .resizable()
                    .frame(width: 110, height: 110)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 130, leading: 130, bottom: 130, trailing: 130))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(50)
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
            
            HStack {
                Button(action: sendGoPreviousSlideAction) {
                    Image(systemName: "backward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                    // TODO: reduce duplication
                        .padding(EdgeInsets(top: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 30 : 200, leading: 70, bottom: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 30 : 200, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                }
                
                Button(action: sendGoNextSlideAction) {
                    Image(systemName: "forward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 30 : 200, leading: 70, bottom: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 30 : 200, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                }
            }
        }
    }
    
    var landscapePresenterView: some View {
        HStack {
            Button(action: sendGoPreviousSlideAction) {
                Image(systemName: "backward.end")
                    .resizable()
                    .frame(width: 40, height: 50)
                    .foregroundColor(.white)
                // TODO: reduce duplication
                    .padding(EdgeInsets(top: 80, leading: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 50 : 200, bottom: 80, trailing: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 50 : 200))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(20)
            }
            
            if backgroundService._devices[detailsDeviceId]!._type == .desktop {
                Image(systemName: "wand.and.rays")
                    .resizable()
                    .frame(width: 110, height: 110)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 100, leading: 130, bottom: 100, trailing: 130))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(50)
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
            
            Button(action: sendGoNextSlideAction) {
                Image(systemName: "forward.end")
                    .resizable()
                    .frame(width: 40, height: 50)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 80, leading: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 50 : 200, bottom: 80, trailing: (backgroundService._devices[detailsDeviceId]!._type == .desktop) ? 50 : 200))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(20)
            }
        }
    }
    
    func startGyroAndPointer() {
            //UIImpactFeedbackGenerator(style: .heavy).impactOcurred()
            motionManager.startGyroUpdates(to: .main) { (data, error) in
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
