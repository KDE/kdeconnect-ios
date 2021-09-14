//
//  PresenterView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-13.
//

import SwiftUI

struct PresenterView: View {
    let detailsDeviceId: String
    @State var currPointerX: Float = 0.0
    @State var currPointerY: Float = 0.0
    
    @State private var pointerSensitivityFromSlider: Float = 3.0 // defaults to the middle
    @State private var showingSensitivitySlider: Bool = false
    
    var body: some View {
        VStack {
//            Spacer()
//                .frame(height: 20)
            Image(systemName: "wand.and.rays")
                .resizable()
                .frame(width: 110, height: 110)
                .foregroundColor(.white)
                .padding(EdgeInsets(top: 150, leading: 150, bottom: 150, trailing: 150))
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
            
            HStack {
                Button(action: {
                    
                }, label: {
                    Image(systemName: "backward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 30, leading: 70, bottom: 30, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                })
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "forward.end")
                        .resizable()
                        .frame(width: 40, height: 50)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 30, leading: 70, bottom: 30, trailing: 70))
                        .background(Color.orange)
                        .clipShape(Rectangle())
                        .cornerRadius(20)
                })
            }
            
            if (showingSensitivitySlider) {
                VStack {
                    HStack {
                        Image(systemName: "minus")
                        Slider(
                            value: $pointerSensitivityFromSlider,
                            in: 0.5...5.5,
                            onEditingChanged: { editing in
                                if (!editing) {
                                    hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred()
                                }
                            }
                        )
                        .onChange(of: pointerSensitivityFromSlider, perform: { value in
                            (backgroundService._devices[detailsDeviceId] as! Device)._pointerSensitivity = value
                        })
                        Image(systemName: "plus")
                    }
                    Text("Pointer Sensitivity")
                }
                .padding(.all, 15)
                .transition(.opacity)
            }
            
        }
        .navigationTitle("Slideshow Remote")
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
    
    func startGyroAndPointer() -> Void {
        hapticGenerators[Int(HapticStyle.heavy.rawValue)].impactOccurred()
        motionManager.startGyroUpdates(to: .main) { (data, error) in
            if (data != nil) {
                ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendPointerPosition(Dx: Float(data!.rotationRate.x) * pointerSensitivityFromSlider, Dy: Float(data!.rotationRate.y) * pointerSensitivityFromSlider)
            }
        }
    }
    
    func stopGyroAndPointer() -> Void {
        hapticGenerators[Int(HapticStyle.heavy.rawValue)].impactOccurred()
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendStopPointer()
        motionManager.stopGyroUpdates()
    }
    
    func goFullscreenAction() -> Void {
        notificationHapticsGenerator.notificationOccurred(.success)
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendFullscreen()
    }
    
    func goEscapeAction() -> Void {
        notificationHapticsGenerator.notificationOccurred(.warning)
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendEsc()
    }
    
    func goBackAction() -> Void {
        hapticGenerators[Int(HapticStyle.soft.rawValue)].impactOccurred()
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendPrevious()
    }
    
    func goForwardAction() -> Void {
        hapticGenerators[Int(HapticStyle.rigid.rawValue)].impactOccurred()
        ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_PRESENTER] as! Presenter).sendNext()
    }
}

//struct PresenterView_Previews: PreviewProvider {
//    static var previews: some View {
//        PresenterView(detailsDeviceId: "Hi")
//    }
//}
