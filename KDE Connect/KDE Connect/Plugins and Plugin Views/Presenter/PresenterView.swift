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
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @State private var pointerSensitivityFromSlider: Float = 0.07 // defaults to the middle
    @State private var showingSensitivitySlider: Bool = false

    var body: some View {
        VStack { // TODO: This is a rough first implementation of getting it "optimized" for different displays and orientations. But let's test if the gyroscope backend even works first
            if (horizontalSizeClass == .compact && verticalSizeClass == .regular) || (horizontalSizeClass == .regular && verticalSizeClass == .regular) { //iPhone Portrait or iPad Landscape AND portrait
                
            } else if (horizontalSizeClass == .regular && verticalSizeClass == .compact) { //iPhone Landscape
                
            }
            
            if (showingSensitivitySlider) {
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
                        hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred()
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
        .navigationBarTitle("Slideshow Remote", displayMode: .inline)
        .navigationBarItems(trailing: {
            Menu {
                Button(action: {
                    goFullscreenAction()
                }, label: {
                    HStack {
                        Text("Go FullScreen")
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                })
                
                Button(action: {
                    goEscapeAction()
                }, label: {
                    HStack {
                        Text("Exit Presentation")
                        Image(systemName: "arrowshape.turn.up.left")
                    }
                })
                
                Button(action: {
                    withAnimation {
                        showingSensitivitySlider.toggle()
                    }
                }, label: {
                    HStack {
                        Text("\((showingSensitivitySlider) ? "Hide" : "Show") Sensitivity Slider")
                        Image(systemName: "cursorarrow.motionlines")
                    }
                })
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }())
    }
    
    var portraitPresenterView: some View {
        Group {
            if backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop {
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
                            .onChanged({ _ in
                                startGyroAndPointer()
                            })
                            .onEnded({ _ in
                                stopGyroAndPointer()
                            })
                    )
            }
            
            HStack {
                Button(action: {
                    goBackAction()
                }, label: {
                    Image(systemName: "backward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                    // TODO: reduce duplication
                        .padding(EdgeInsets(top: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 30 : 200, leading: 70, bottom: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 30 : 200, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                })
                
                Button(action: {
                    goForwardAction()
                }, label: {
                    Image(systemName: "forward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 30 : 200, leading: 70, bottom: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 30 : 200, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                })
            }
        }
    }
    
    var landscapePresenterView: some View {
        HStack {
            Button(action: {
                goBackAction()
            }, label: {
                Image(systemName: "backward.end")
                    .resizable()
                    .frame(width: 40, height: 50)
                    .foregroundColor(.white)
                // TODO: reduce duplication
                    .padding(EdgeInsets(top: 80, leading: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 50 : 200, bottom: 80, trailing: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 50 : 200))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(20)
            })
            
            if backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop {
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
                            .onChanged({ _ in
                                startGyroAndPointer()
                            })
                            .onEnded({ _ in
                                stopGyroAndPointer()
                            })
                    )
            }
            
            Button(action: {
                goForwardAction()
            }, label: {
                Image(systemName: "forward.end")
                    .resizable()
                    .frame(width: 40, height: 50)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 80, leading: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 50 : 200, bottom: 80, trailing: (backgroundService._devices[detailsDeviceId]!._type == DeviceType.Desktop) ? 50 : 200))
                    .background(Color.orange)
                    .clipShape(Rectangle())
                    .cornerRadius(20)
            })
        }
    }
    
    func startGyroAndPointer() -> Void {
        //hapticGenerators[Int(HapticStyle.heavy.rawValue)].impactOccurred()
        motionManager.startGyroUpdates(to: .main) { (data, error) in
            if (data != nil) {
                var DxToSend: Float = 0.0 //
                var DyToSend: Float = 0.0
                if (horizontalSizeClass == .compact && verticalSizeClass == .regular) || (horizontalSizeClass == .regular && verticalSizeClass == .regular) {
                    DxToSend = -(Float(data!.rotationRate.z) * pointerSensitivityFromSlider)
                    DyToSend = -(Float(data!.rotationRate.x) * pointerSensitivityFromSlider)
                } else if (horizontalSizeClass == .regular && verticalSizeClass == .compact) {
                    if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
                        DxToSend = -(Float(data!.rotationRate.z) * pointerSensitivityFromSlider)
                        DyToSend = (Float(data!.rotationRate.y) * pointerSensitivityFromSlider)
                    } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
                        DxToSend = (Float(data!.rotationRate.z) * pointerSensitivityFromSlider)
                        DyToSend = (Float(data!.rotationRate.y) * pointerSensitivityFromSlider)
                    }
                }
                if DxToSend != 0.0 && DyToSend != 0.0 {
                    (backgroundService.devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendPointerPosition(Dx: DxToSend, Dy: DyToSend)
                }
            }
        }
    }
    
    func stopGyroAndPointer() -> Void {
        //hapticGenerators[Int(HapticStyle.heavy.rawValue)].impactOccurred()
        (backgroundService._devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendStopPointer()
        motionManager.stopGyroUpdates()
    }
    
    func goFullscreenAction() -> Void {
        notificationHapticsGenerator.notificationOccurred(.success)
        (backgroundService._devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendFullscreen()
    }
    
    func goEscapeAction() -> Void {
        notificationHapticsGenerator.notificationOccurred(.warning)
        (backgroundService._devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendEsc()
    }
    
    func goBackAction() -> Void {
        hapticGenerators[Int(HapticStyle.soft.rawValue)].impactOccurred()
        (backgroundService._devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendPrevious()
    }
    
    func goForwardAction() -> Void {
        hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred()
        (backgroundService._devices[detailsDeviceId]!._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendNext()
    }
}

struct PresenterView_Previews: PreviewProvider {
    static var previews: some View {
        PresenterView(detailsDeviceId: "Hi")
    }
}
