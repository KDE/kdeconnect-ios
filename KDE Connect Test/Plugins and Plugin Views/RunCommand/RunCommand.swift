//
//  RunCommand.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import SwiftUI

@objc class RunCommand : NSObject, Plugin {
    @objc let controlDevice: Device
    final var controlView: RunCommandView?
    var commandItems: [CommandEntry] = []
    
    @objc init (controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np._Type == PACKAGE_TYPE_RUNCOMMAND) {
            if (np.bodyHasKey("commandList")) {
                // Process the received commandList here
                let jsonString: String = np.object(forKey: "commandList") as! String
                if let jsonDictionary: [String : String] = JSONStringtoDictionary(json: jsonString) {
                    for key in jsonDictionary.keys {
                        if let commandEntryData: Data = jsonDictionary[key]!.data(using: .utf8) {
                            let commandEntry: CommandEntry = try! JSONDecoder().decode(CommandEntry.self, from: commandEntryData)
                            commandEntry.key = key
                            commandItems.append(commandEntry)
                        } else {
                            print("RunCommand: CommandEntry decode failed")
                        }
                    }
                    processCommandItemsAndGiveToRunCommandView()
                } else {
                    print("RunCommand: commandList decode failed")
                }
            } else {
                print("Runcommand packet received with no commandList, ignoring")
            }
            return true
        }
        return false
    }
    
    @objc func processCommandItemsAndGiveToRunCommandView() -> Void {
        if (controlView != nil) {
            for command in commandItems {
                controlView!.commandItemsInsideView[command.key!] = command
            }
        }
    }
    
    @objc func runCommand(cmdKey: String) -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_RUNCOMMAND_REQUEST)
        np.setObject(cmdKey, forKey: "key")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func requestCommandList() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_RUNCOMMAND_REQUEST)
        np.setBool(true, forKey: "requestCommandList")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func sendSetupPackage() -> Void {
        let np: NetworkPackage = NetworkPackage(type: PACKAGE_TYPE_RUNCOMMAND_REQUEST)
        np.setBool(true, forKey: "setup")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
}
