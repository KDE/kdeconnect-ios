/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  RunCommandView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import SwiftUI
struct RunCommandView: View {
    let detailsDeviceId: String
    @ObservedObject var runCommandPlugin: RunCommand
    
    init(detailsDeviceId: String) {
        self.detailsDeviceId = detailsDeviceId
        self.runCommandPlugin = backgroundService.devices[detailsDeviceId]!._plugins[.runCommand] as! RunCommand
    }
    
    var body: some View {
        List {
            ForEach(runCommandPlugin.commandEntries) { entry in
                Button {
                    runCommandPlugin.runCommand(cmdKey: entry.key)
#if !os(macOS)
                    notificationHapticsGenerator.notificationOccurred(.success)
#endif
                } label: {
                    VStack(alignment: .leading) {
                        Text(entry.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(entry.command)
                            .font(.caption)
                    }
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
        .navigationTitle("Run Command")
#if !os(macOS)
        .navigationBarItems(trailing: Button(action: runCommandPlugin.sendSetupPacket) {
            Image(systemName: "command") // is there a better choice for this? This is a nice reference though I think
        })
#endif
    }
}

// struct RunCommandView_Previews: PreviewProvider {
//     static var previews: some View {
//         RunCommandView()
//     }
// }
