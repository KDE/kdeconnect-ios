/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  RunCommand.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import SwiftUI

// TODO: rename to RunCommandPlugin
@objc class RunCommand : NSObject, ObservablePlugin {
    @objc let controlDevice: Device
    @Published
    var commandEntries: [CommandEntry] = []
    
    @objc init(controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .runCommand) {
            if np.bodyHasKey("commandList") {
                // Process the received commandList here
                let jsonString = np.object(forKey: "commandList") as! String
                DispatchQueue.main.async { [self] in
                    commandEntries = processCommandsJSON(jsonString)
                }
            } else {
                print("Runcommand packet received with no commandList, ignoring")
            }
            return true
        }
        return false
    }
    
    @objc func runCommand(cmdKey: String) -> Void {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setObject(cmdKey, forKey: "key")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func requestCommandList() -> Void {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setBool(true, forKey: "requestCommandList")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func sendSetupPackage() -> Void {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setBool(true, forKey: "setup")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    private func processCommandsJSON(_ json: String) -> [CommandEntry] {
        guard let jsonData = json.data(using: .utf8) else {
            return []
        }
        do {
            guard let commandsDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : [String : String]] else {
                print("RunCommand: commandList decode failed")
                return []
            }
            return commandsDict.compactMap { (commandKey, commandInfo) in
                if let commandName = commandInfo["name"],
                    let command = commandInfo["command"] {
                    let commandEntry = CommandEntry(name: commandName, command: command, key: commandKey)
                    return commandEntry
                } else {
                    print("Command or CommandName for \(commandKey) is nil")
                    return nil
                }
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}
