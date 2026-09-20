//
//  OSLogView.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/3/22.
//

import SwiftUI
import OSLog

@available(iOS 15.0, *)
struct OSLogView: View {
    @ObservedObject var osLog: OSLogManager = OSLogManager()
    @State var query: String = ""
    @State var categoryFilter: Set<String> = []
    @State var logLevelFilter: Set<OSLogEntryLog.Level> = []
    
    var hasFilter: Bool {
        return !query.isEmpty || !logLevelFilter.isEmpty || !categoryFilter.isEmpty
    }
    
    var entries: [OSLogEntry] {
        guard hasFilter else {
            return osLog.entries
        }
        return osLog.entries.filter { entry in
            switch entry {
            case let logEntry as OSLogEntryLog:
                var satisfyQuery: Bool {
                    query.isEmpty
                    || logEntry.category.localizedCaseInsensitiveContains(query)
                    || logEntry.composedMessage.localizedCaseInsensitiveContains(query)
                }
                var satisfyLogLevel: Bool {
                    logLevelFilter.isEmpty
                    || logLevelFilter.contains(logEntry.level)
                }
                return satisfyQuery && satisfyLogLevel
            default:
                var satisfyQuery: Bool {
                    query.isEmpty
                    || entry.composedMessage.localizedCaseInsensitiveContains(query)
                }
                var satisfyLogLevel: Bool {
                    logLevelFilter.isEmpty
                }
                return satisfyQuery && satisfyLogLevel
            }
        }
    }
    
    var body: some View {
        List {
            if entries.isEmpty {
                if hasFilter {
                    Text("No matching logs yet")
                } else {
                    Text("Waiting for logs...")
                }
            } else {
                logsDisplay
            }
        }
        .searchable(text: $query)
        // TODO: for whatever reason, suggestions won't be dismissed on iPad
        // {
        //     ForEach(osLog.categories.sorted(), id: \.self) { category in
        //         Text(category)
        //             .searchCompletion(category)
        //     }
        // }
        .toolbar {
            Picker("", selection: $logLevelFilter) {
                Text("All Messages")
                    .tag(Set<OSLogEntryLog.Level>())
                Text("Errors and Faults")
                    .tag(Set<OSLogEntryLog.Level>([.error, .fault]))
            }
            .pickerStyle(.segmented)
        }
        .navigationTitle("Logs for \(OSLog.subsystem)")
    }
    
    var logsDisplay: some View {
        ForEach(entries, id: \.hash) { entry in
            switch entry {
            case let logEntry as OSLogEntryLog:
                OSLogEntryLogView(logEntry: logEntry)
            default:
                Label {
                    Text(entry.composedMessage)
                        .textSelection(.enabled)
                } icon: {
                    Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                        .renderingMode(.original)
                        .accentColor(.mint)
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct OSLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OSLogView()
        }
    }
}
