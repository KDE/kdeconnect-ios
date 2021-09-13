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
    @State private var previousHorizontalDragOffset: Double = 0.0
    @State private var previousVerticalDragOffset: Double = 0.0
    
    @State private var previousScrollVerticalDragOffset: Double = 0.0
    @State private var previousScrollHorizontalDragOffset: Double = 0.0
    
    @State private var cursorSensitivityFromSlider: Double = 3.0 // defaults to the middle
    @State private var hapticSettingsSegmentPickerIndex: Int = 0
    @State private var showingSensitivitySlider: Bool = false
    @State private var showingHapticSegmentPicker: Bool = false
    
    var body: some View {
        VStack {
            TwoFingerTapView { gesture in
                rightClickAction()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background((colorScheme == .light) ? Color.white : Color.black)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let DxDrag: Double = Double(gesture.translation.width) - previousHorizontalDragOffset
                        let DyDrag: Double = Double(gesture.translation.height) - previousVerticalDragOffset
                        //if (Dx > 0.3 || Dy > 0.3) { // Do we want this check here?
                        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendMouseDelta(Dx: DxDrag * cursorSensitivityFromSlider, Dy: DyDrag * cursorSensitivityFromSlider)
                        print("Moved by \(DxDrag) horizontally")
                        print("Moved by \(DyDrag) vertically")
                        //}
                        previousHorizontalDragOffset = Double(gesture.translation.width)
                        previousVerticalDragOffset = Double(gesture.translation.height)
                    }
                    .onEnded { gesture in
                        previousHorizontalDragOffset = 0.0
                        previousVerticalDragOffset = 0.0
                        print("Drag ended, resetting to 0.0")
                    }
            )
            .tapRecognizer(tapSensitivity: 0.2, singleTapAction: singleTapAction, doubleTapAction: doubleTapAction)
            .onLongPressGesture {
                singleHoldAction()
            }
            .overlay( // FIXME: Migrate to new overlay() when iOS 15 comes out
                VStack {
                    Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                        .resizable()
                        .frame(width: 120, height: 120)
                        //.scaledToFit()
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let DxScroll: Double = Double(gesture.translation.width) - previousScrollHorizontalDragOffset
                                    let DyScroll: Double = Double(gesture.translation.height) - previousScrollVerticalDragOffset
                                    //if (Dx > 0.3 || Dy > 0.3) { // Do we want this check here?
                                    ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendScroll(Dx: DxScroll * cursorSensitivityFromSlider, Dy: DyScroll * cursorSensitivityFromSlider)
                                    print("Scrolled by \(DxScroll) horizontally")
                                    print("Scrolled by \(DyScroll) vertically")
                                    //}
                                    previousScrollHorizontalDragOffset = Double(gesture.translation.width)
                                    previousScrollVerticalDragOffset = Double(gesture.translation.height)
                                }
                                .onEnded { gesture in
                                    previousScrollHorizontalDragOffset = 0.0
                                    previousScrollVerticalDragOffset = 0.0
                                    print("Scroll ended, resetting to 0.0")
                                }
                        )
                        .onTapGesture {
                            middleClickAction()
                            print("Middle click from scroll wheel")
                        }
                        .padding(.top, 5)
                    Spacer()
                }
            , alignment: .bottom)
            
            if (showingSensitivitySlider) {
                VStack {
                    HStack {
                        Image(systemName: "minus")
                        Slider(
                            value: $cursorSensitivityFromSlider,
                            in: 0.5...5.5,
                            onEditingChanged: { editing in
                                if (!editing) {
                                    hapticGenerators[hapticSettingsSegmentPickerIndex].impactOccurred()
                                }
                            }
                        )
                        .onChange(of: cursorSensitivityFromSlider, perform: { value in
                            ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sensitivity = value
                            (backgroundService._devices[detailsDeviceId] as! Device)._cursorSensitivity = value
                        })
                        Image(systemName: "plus")
                    }
                    Text("Crusor Sensitivity")
                }
                .padding(.all, 15)
            }
            
            if (showingHapticSegmentPicker) {
                VStack {
                    Picker(selection: $hapticSettingsSegmentPickerIndex, label: Text("Haptics Style")) {
                        Text("Light").tag(0)
                        Text("Medium").tag(1)
                        Text("Heavy").tag(2)
                        Text("Soft").tag(3)
                        Text("Rigid").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: hapticSettingsSegmentPickerIndex, perform: { value in
                        hapticGenerators[value].impactOccurred()
                        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).hapticStyleEnumType = HapticStyle(rawValue: UInt(value))! // ?? HapticStyle.medium
                        (backgroundService._devices[detailsDeviceId] as! Device)._hapticStyle = HapticStyle(rawValue: UInt(value))! // ?? HapticStyle.medium
                    })
                    Text("On-Click Haptic Style")
                }
                .padding(.all, 15)
            }
        }
        .navigationTitle("Remote Input")
        .navigationBarItems(trailing: {
            Menu {
                Button(action: {
                    singleTapAction()
                }, label: {
                    HStack {
                        Text("Send Single Left Click")
                        Image(systemName: "cursorarrow.click")
                    }
                })
                
                Button(action: {
                    doubleTapAction()
                }, label: {
                    HStack {
                        Text("Send Double Left Click")
                        Image(systemName: "cursorarrow.click.2")
                    }
                })
                
                Button(action: {
                    rightClickAction()
                }, label: {
                    HStack {
                        Text("Send Right Click")
                        Image(systemName: "line.diagonal.arrow")
                    }
                })
                
                Button(action: {
                    singleHoldAction()
                }, label: {
                    HStack {
                        Text("Send Left Hold")
                        Image(systemName: "cursorarrow.rays")
                    }
                })
                
                Button(action: {
                    middleClickAction()
                }, label: {
                    HStack {
                        Text("Send Middle Click")
                        Image(systemName: "square.and.line.vertical.and.square")
                    }
                })
                
                Button(action: {
                    showingSensitivitySlider.toggle()
                }, label: {
                    HStack {
                        Text("\((showingSensitivitySlider) ? "Hide" : "Show") Sensitivity Slider")
                        Image(systemName: "cursorarrow.motionlines")
                    }
                })
                
                Button(action: {
                    showingHapticSegmentPicker.toggle()
                }, label: {
                    HStack {
                        Text("\((showingHapticSegmentPicker) ? "Hide" : "Show") Haptics Style Selector")
                        Image(systemName: "cursorarrow.motionlines.click")
                    }
                })
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }())
        .onAppear() {
            cursorSensitivityFromSlider = ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sensitivity
            // If new device, give default sensitivity of 3.0
            if (cursorSensitivityFromSlider == 0.0) {
                cursorSensitivityFromSlider = 3.0
                ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sensitivity = 3.0
                (backgroundService._devices[detailsDeviceId as Any] as! Device)._cursorSensitivity = 3.0
            }
            // New device's hapticStyle is automatically 0 (light) as it came from Obj-C initialization
            hapticSettingsSegmentPickerIndex = Int(((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).hapticStyleEnumType.rawValue)
        }
    }
    
    func singleTapAction() {
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendSingleClick()
        hapticGenerators[hapticSettingsSegmentPickerIndex].impactOccurred() //intensity: 0.7
        print("single clicked")
    }
    
    func doubleTapAction() {
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendDoubleClick()
        notificationHapticsGenerator.notificationOccurred(.success)
        print("double clicked")
    }
    
    func rightClickAction() {
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendRightClick()
        hapticGenerators[hapticSettingsSegmentPickerIndex].impactOccurred() //intensity: 1.0
        print("2 finger tap")
    }
    
    func singleHoldAction() {
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendSingleHold()
        hapticGenerators[hapticSettingsSegmentPickerIndex].impactOccurred() //intensity: 0.5
        print("Long press")
    }
    
    func middleClickAction() {
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendMiddleClick()
        hapticGenerators[hapticSettingsSegmentPickerIndex].impactOccurred() //intensity: 0.3
        print("Middle Click")
    }
}

//struct MousePadView_Previews: PreviewProvider {
//    static var previews: some View {
//        MousePadView()
//    }
//}
