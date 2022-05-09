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
    @objc weak var controlDevice: Device!
    @Published
    var commandEntries: [CommandEntry] = []
    
    @objc init(controlDevice: Device) {
        self.controlDevice = controlDevice
    }
    
    typealias CommandsDictionary = [String : [String : String]]
    
    @objc func onDevicePackageReceived(np: NetworkPackage) -> Bool {
        if (np.type == .runCommand) {
            if np.bodyHasKey("commandList") {
                // Process the received commandList here
                let commandsDict: CommandsDictionary
                switch np.object(forKey: "commandList") {
                case let jsonString as String:
                    commandsDict = processCommandsJSON(jsonString)
                case let dict as CommandsDictionary:
                    print("out of date GSConnect with wrong RunCommand implementation")
                    commandsDict = dict
                case let somethingElse:
                    print("unexpected commandList format \(type(of: somethingElse))")
                    commandsDict = [:]
                }
                let newCommandEntries = processCommandsDict(commandsDict)
                DispatchQueue.main.async { [weak self] in
                    self?.commandEntries = newCommandEntries
                }
            } else {
                print("RunCommand packet received with no commandList, ignoring")
            }
            return true
        }
        return false
    }
    
    @objc func runCommand(cmdKey: String) {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setObject(cmdKey, forKey: "key")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func requestCommandList() {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setBool(true, forKey: "requestCommandList")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    @objc func sendSetupPackage() {
        let np: NetworkPackage = NetworkPackage(type: .runCommandRequest)
        np.setBool(true, forKey: "setup")
        controlDevice.send(np, tag: Int(PACKAGE_TAG_NORMAL))
    }
    
    private func processCommandsJSON(_ json: String) -> CommandsDictionary {
        guard let jsonData = json.data(using: .utf8) else {
            return [:]
        }
        do {
            guard let commandsDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? CommandsDictionary else {
                print("commandList string is not convertible to CommandsDictionary")
                return [:]
            }
            return commandsDict
        } catch {
            print(error.localizedDescription)
            return [:]
        }
    }
    
    private func processCommandsDict(_ commandsDict: CommandsDictionary) -> [CommandEntry] {
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
    }
}
