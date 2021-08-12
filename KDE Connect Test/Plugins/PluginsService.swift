//
//  PluginsService.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-11.
//

import Foundation
import UIKit

protocol Plugin {
    func onDevicePackageReceived(np: NetworkPackage) -> Bool
}
// TODO: Is there a more elegant way of having a protocal with objects with different methods than just
// force casting like this?
let avaliablePlugins: [String : Any] = ["kdeconnect.ping":Ping()]
let haptics = UIImpactFeedbackGenerator(style: .heavy)

@objc class PluginsService : NSObject {
    @objc static func goThroughHostPluginsForReceiving(np: NetworkPackage) -> Void {
        for plugin in avaliablePlugins.values {
            print((plugin as! Plugin).onDevicePackageReceived(np: np))
        }
    }
}
