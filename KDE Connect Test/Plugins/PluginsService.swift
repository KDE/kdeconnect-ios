//
//  PluginsService.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

import Foundation

@objc protocol Plugin {
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool
}
// TODO: Is there a more elegant way of having a protocal with objects with different methods than just
// force casting like this?
// MARK: Currently, Plugin objects are device agnostic as they rely on the deviceId of the device that needs to be interacted with to be passed to them. A device specific (non-agnostic) approach would be to have a deviceId field in each Plugin object and for each Device object (in Obj-C) to keep an Array of their own Plugins that they can use (this is the approach of the old Obj-C code)

// FIXME: the dic and the objective-c class below are not used anymore
//let avaliablePlugins: [String : Any] = [PACKAGE_TYPE_PING:Ping(), PACKAGE_TYPE_SHARE:Share(), PACKAGE_TYPE_FINDMYPHONE_REQUEST:FindMyPhone(), PACKAGE_TYPE_BATTERY:Battery()]

//@objc class PluginsService : NSObject {
//    @objc static func goThroughHostPluginsForReceiving(np: NetworkPackage) -> Void {
//        for plugin in avaliablePlugins.values {
//            (plugin as! Plugin).onDevicePackageReceived(np: np)
//        }
//    }
//}
