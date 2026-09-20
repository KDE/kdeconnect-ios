//
//  OSLogEntryLogView.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/3/22.
//

import SwiftUI
import OSLog

@available(iOS 15.0, *)
struct OSLogEntryLogView: View {
    let logEntry: OSLogEntryLog
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(logEntry.composedMessage)
                    .textSelection(.enabled)
                Text(logEntry.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Category: \(logEntry.category)")
            }
        } icon: {
            switch logEntry.level {
            case .undefined:
                Image(systemName: "questionmark.diamond")
            case .debug:
                Image(systemName: "ladybug.fill")
                    .foregroundColor(.primary)
            case .info:
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.indigo)
            case .notice:
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(.blue)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
            case .fault:
                Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(.red)
            @unknown default:
                Image(systemName: "questionmark.diamond")
            }
        }
        .accessibilityValue({ () -> Text in
            switch logEntry.level {
            case .undefined:
                return Text("")
            case .debug:
                return Text("Debug")
            case .info:
                return Text("Info")
            case .notice:
                return Text("Notice")
            case .error:
                return Text("Error")
            case .fault:
                return Text("Fault")
            @unknown default:
                return Text("")
            }
        }())
    }
}

@available(iOS 15.0, *)
struct OSLogEntryLogView_Previews: PreviewProvider {
    static var previews: some View {
        OSLogEntryLogView(logEntry: OSLogEntryLog())
    }
}
