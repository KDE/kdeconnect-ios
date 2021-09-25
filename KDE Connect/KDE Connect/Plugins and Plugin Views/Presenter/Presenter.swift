//
//  Presenter.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-13.
//

import Foundation

@objc class Presenter : NSObject, Plugin {
    @objc let controlDevice: Device
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_PRESENTER) {
            print("Presenter received a package, can't do anything about it, ignoring")
            return true
        }
        return false
    }
    
    @objc func sendNext() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD_REQUEST)
        np.setInteger(KeyEvent.KEYCODE_PAGE_DOWN.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendPrevious() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD_REQUEST)
        np.setInteger(KeyEvent.KEYCODE_PAGE_UP.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendFullscreen() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD_REQUEST)
        np.setInteger(KeyEvent.KEYCODE_F5.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendEsc() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_MOUSEPAD_REQUEST)
        np.setInteger(KeyEvent.KEYCODE_ESCAPE.rawValue, forKey: "specialKey")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_MOUSEPAD))
    }
    
    @objc func sendPointerPosition(Dx: Float, Dy: Float) -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_PRESENTER)
        np.setFloat(Dx, forKey: "dx")
        np.setFloat(Dy, forKey: "dy")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func sendStopPointer() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_PRESENTER)
        np.setBool(true, forKey: "stop")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
}
