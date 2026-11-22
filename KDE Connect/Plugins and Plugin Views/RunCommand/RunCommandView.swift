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
    @ObservedObject var runCommandPlugin: RunCommand
    
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
        .overlay {
            if runCommandPlugin.commandEntries.isEmpty {
                VStack(spacing: 8) {
                    Text("There are no commands registered")
                    if !runCommandPlugin.canAddCommand {
                        Text("You can add new commands in the KDE Connect System Settings")
                    }
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            }
        }
        .environment(\.defaultMinListRowHeight, 50) // TODO: make this dynamic with GeometryReader???
        .navigationTitle("Run Command")
#if !os(macOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: runCommandPlugin.sendSetupPacket) {
                    Image(systemName: "plus")
                }
            }
        }
#endif
    }
}

// struct RunCommandView_Previews: PreviewProvider {
//     static var previews: some View {
//         RunCommandView()
//     }
// }
