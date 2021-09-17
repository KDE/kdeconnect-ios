//
//  CommandEntry.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-16.
//

import Foundation

class CommandEntry: Decodable {
    final var name: String
    final var command: String
    final var key: String?
    
//    init(name: String, cmd: String, key: String) {
//        self.name = name
//        self.cmd = cmd
//        self.key = key
//    }
}
