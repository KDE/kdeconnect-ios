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
    
    let testSensitivity: Double = 3 // TODO: Move this into Device() object so each device can have its own persistently saved mouse sensitivity that can also be adjusted in Plugin settings
    
    var body: some View {
        //Text("Move a finger on the screen to move the mouse cursor. Tap for left click.")
        TwoFingerTapView { gesture in
            rightClickAction()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background((colorScheme == .light) ? Color.white : Color.black)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let Dx: Double = Double(gesture.translation.width) - previousHorizontalDragOffset
                        let Dy: Double = Double(gesture.translation.height) - previousVerticalDragOffset
                        //if (Dx > 0.3 || Dy > 0.3) { // Do we want this check here?
                        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendMouseDelta(Dx: Dx * testSensitivity, Dy: Dy * testSensitivity)
                        print("Moved by \(Dx) horizontally")
                        print("Moved by \(Dy) vertically")
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
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }())
    }
    
    func singleTapAction() {
        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendSingleClick()
        print("single clicked")
    }
    
    func doubleTapAction() {
        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendDoubleClick()
        print("double clicked")
    }
    
    func rightClickAction() {
        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendRightClick()
        print("2 finger tap")
    }
    
    func singleHoldAction() {
        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendSingleHold()
        print("Long press")
    }
    
    func middleClickAction() {
        ((backgroundService._devices[detailsDeviceId as Any] as! Device)._plugins[PACKAGE_TYPE_MOUSEPAD] as! RemoteInput).sendMiddleClick()
        print("Middle Click")
    }
}

//struct MousePadView_Previews: PreviewProvider {
//    static var previews: some View {
//        MousePadView()
//    }
//}
