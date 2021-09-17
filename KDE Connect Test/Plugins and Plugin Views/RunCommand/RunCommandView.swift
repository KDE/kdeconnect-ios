//
//  RunCommandView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import SwiftUI

struct RunCommandView: View {
    let detailsDeviceId: String
    @State var commandItemsInsideView: [String : CommandEntry] = [:]
    
    var body: some View {
        List {
            ForEach(Array(commandItemsInsideView.keys), id: \.self) { commandkey in
                Button(action: {
                    ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).runCommand(cmdKey: commandkey)
                    notificationHapticsGenerator.notificationOccurred(.success)
                }, label: {
                    VStack {
                        Text(commandItemsInsideView[commandkey]?.name ?? "ERROR")
                            .font(.system(size: 18, weight: .bold))
                        Text(commandItemsInsideView[commandkey]?.command ?? "ERROR")
                            .font(.system(size: 12))
                    }
                })
            }
        }
        .navigationTitle("Run Command")
        .navigationBarItems(trailing: Button(action: {
            ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).sendSetupPackage()
        }, label: {
            Image(systemName: "command") // is there a better choice for this? This is a nice reference though I think
        }))
        .onAppear {
            if (((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).controlView == nil) {
                ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).controlView = self
            }
            ((backgroundService._devices[detailsDeviceId] as! Device)._plugins[PACKAGE_TYPE_RUNCOMMAND] as! RunCommand).processCommandItemsAndGiveToRunCommandView()
        }
    }
}

//struct RunCommandView_Previews: PreviewProvider {
//    static var previews: some View {
//        RunCommandView()
//    }
//}
