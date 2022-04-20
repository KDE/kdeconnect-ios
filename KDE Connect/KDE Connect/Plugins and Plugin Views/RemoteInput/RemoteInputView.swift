/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  RemoteInputView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-06.
//

import SwiftUI

struct RemoteInputView: View {
    @Environment(\.colorScheme) var colorScheme
    let detailsDeviceId: String
    @State private var previousHorizontalDragOffset: Float = 0.0
    @State private var previousVerticalDragOffset: Float = 0.0
    
    @State private var previousScrollVerticalDragOffset: Float = 0.0
    @State private var previousScrollHorizontalDragOffset: Float = 0.0
    
    @State private var cursorSensitivityFromSlider: Float = 3.0 // defaults to the middle
    @State private var hapticSettings: UIImpactFeedbackGenerator.FeedbackStyle = .light
    @State private var showingSensitivitySlider: Bool = false
    @State private var showingHapticSegmentPicker: Bool = false
    
    var body: some View {
        VStack {
            TwoFingerTapView { gesture in
                sendRightClick()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let dxDrag: Float = Float(gesture.translation.width) - previousHorizontalDragOffset
                        let dyDrag: Float = Float(gesture.translation.height) - previousVerticalDragOffset
                        //if (Dx > 0.3 || Dy > 0.3) { // Do we want this check here?
                        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendMouseDelta(dx: dxDrag * cursorSensitivityFromSlider, dy: dyDrag * cursorSensitivityFromSlider)
                        print("Moved by \(dxDrag) horizontally")
                        print("Moved by \(dyDrag) vertically")
                        //}
                        previousHorizontalDragOffset = Float(gesture.translation.width)
                        previousVerticalDragOffset = Float(gesture.translation.height)
                    }
                    .onEnded { gesture in
                        previousHorizontalDragOffset = 0.0
                        previousVerticalDragOffset = 0.0
                        print("Drag ended, resetting to 0.0")
                    }
            )
            .tapRecognizer(tapSensitivity: 0.2, singleTapAction: sendSingleTap, doubleTapAction: sendDoubleTap)
            .onLongPressGesture {
                sendSingleHold()
            }
            .overlay( // FIXME: Migrate to new overlay() when iOS 15 comes out
                VStack {
                    Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                        .resizable()
                        .frame(width: 110, height: 120)
                        //.scaledToFit()
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let DxScroll: Float = Float(gesture.translation.width) - previousScrollHorizontalDragOffset
                                    let DyScroll: Float = Float(gesture.translation.height) - previousScrollVerticalDragOffset
                                    //if (Dx > 0.3 || Dy > 0.3) { // Do we want this check here?
                                    (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendScroll(Dx: DxScroll * cursorSensitivityFromSlider, Dy: DyScroll * cursorSensitivityFromSlider)
                                    print("Scrolled by \(DxScroll) horizontally")
                                    print("Scrolled by \(DyScroll) vertically")
                                    //}
                                    previousScrollHorizontalDragOffset = Float(gesture.translation.width)
                                    previousScrollVerticalDragOffset = Float(gesture.translation.height)
                                }
                                .onEnded { gesture in
                                    previousScrollHorizontalDragOffset = 0.0
                                    previousScrollVerticalDragOffset = 0.0
                                    print("Scroll ended, resetting to 0.0")
                                }
                        )
                        .onTapGesture {
                            sendMiddleClick()
                            print("Middle click from scroll wheel")
                        }
                        .padding(.top, 5)
                    Spacer()
                }
            , alignment: .bottom)
            
            if (showingSensitivitySlider) {
                Slider(
                    value: $cursorSensitivityFromSlider,
                    in: 0.5...5.5
                ) {
                    Text("Cursor Sensitivity")
                } minimumValueLabel: {
                    Image(systemName: "minus")
                } maximumValueLabel: {
                    Image(systemName: "plus")
                } onEditingChanged: { editing in
                    if (!editing) {
                        UIImpactFeedbackGenerator(style: hapticSettings).impactOccurred()
                        saveDeviceToUserDefaults(deviceId: detailsDeviceId)
                    }
                }
                .padding(.all, 15)
                .transition(.opacity)
                .onChange(of: cursorSensitivityFromSlider) { value in
                    backgroundService._devices[detailsDeviceId]!._cursorSensitivity = value
                }
            }
            
            if (showingHapticSegmentPicker) {
                VStack {
                    Picker(selection: $hapticSettings, label: Text("Haptics Style")) {
                        ForEach(UIImpactFeedbackGenerator.FeedbackStyle.allCases, id: \.self) { style in
                            style.text
                                .tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: hapticSettings, perform: { style in
                        UIImpactFeedbackGenerator(style: style).impactOccurred()
                        backgroundService._devices[detailsDeviceId]!.hapticStyle = style
                        saveDeviceToUserDefaults(deviceId: detailsDeviceId)
                    })
                    Text("On-Click Haptic Style")
                }
                .padding(.all, 15)
                .transition(.opacity)
            }
        }
        .navigationTitle("Remote Input")
        .navigationBarItems(trailing:
            Menu {
                Button(action: sendSingleTap) {
                    Label("Send Single Left Click", systemImage: "cursorarrow.click")
                }
                
                Button(action: sendDoubleTap) {
                    Label("Send Double Left Click", systemImage: "cursorarrow.click.2")
                }
                
                Button(action: sendRightClick) {
                    Label("Send Right Click", systemImage: "line.diagonal.arrow")
                }
                
                Button(action: sendSingleHold) {
                    Label("Send Left Hold", systemImage: "cursorarrow.rays")
                }
                
                Button(action: sendMiddleClick) {
                    Label("Send Middle Click", systemImage: "square.and.line.vertical.and.square")
                }
                
                Button {
                    withAnimation {
                        showingSensitivitySlider.toggle()
                    }
                } label: {
                    Label("\((showingSensitivitySlider) ? "Hide" : "Show") Sensitivity Slider",
                          systemImage: "cursorarrow.motionlines")
                }
                
                Button {
                    withAnimation {
                        showingHapticSegmentPicker.toggle()
                    }
                } label: {
                    Label("\((showingHapticSegmentPicker) ? "Hide" : "Show") Haptics Style Selector",
                          systemImage: "cursorarrow.motionlines.click")
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .onAppear {
            cursorSensitivityFromSlider = backgroundService._devices[detailsDeviceId]!._cursorSensitivity
            // If new device, give default sensitivity of 3.0
            if (cursorSensitivityFromSlider < 0.5) {
                cursorSensitivityFromSlider = 3.0
                backgroundService._devices[detailsDeviceId]!._cursorSensitivity = 3.0
            }
            // New device's hapticStyle is automatically 0 (light) as it came from Obj-C initialization
            
            hapticSettings = backgroundService._devices[detailsDeviceId]!.hapticStyle
        }
    }
    
    func sendSingleTap() {
        UIImpactFeedbackGenerator(style: hapticSettings).impactOccurred() //intensity: 0.7
        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendSingleClick()
        print("single clicked")
    }
    
    func sendDoubleTap() {
        notificationHapticsGenerator.notificationOccurred(.success)
        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendDoubleClick()
        print("double clicked")
    }
    
    func sendRightClick() {
        UIImpactFeedbackGenerator(style: hapticSettings).impactOccurred() //intensity: 1.0
        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendRightClick()
        print("2 finger tap")
    }
    
    func sendSingleHold() {
        UIImpactFeedbackGenerator(style: hapticSettings).impactOccurred() //intensity: 0.5
        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendSingleHold()
        print("Long press")
    }
    
    func sendMiddleClick() {
        UIImpactFeedbackGenerator(style: hapticSettings).impactOccurred() //intensity: 0.3
        (backgroundService._devices[detailsDeviceId]!._plugins[.mousePadRequest] as! RemoteInput).sendMiddleClick()
        print("Middle Click")
    }
}

struct MousePadView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteInputView(detailsDeviceId: "HI")
    }
}
