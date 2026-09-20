//
//  OSLogManager.swift
//  KDE Connect
//
//  Created by Apollo Zhu on 3/3/22.
//

import OSLog
import Combine

@available(iOS 15.0, *)
class OSLogManager: ObservableObject {
    private let store: OSLogStore?
    @Published
    private(set) var entries: [OSLogEntry] = []
    @Published
    private(set) var categories: Set<String> = []
    private var timerCancellable: AnyCancellable?
    private let dispatchQueue = DispatchQueue(label: UUID().uuidString)
    private let subsystem: String
    
    init(subsystem: String = OSLog.subsystem, refreshInterval: TimeInterval = 1) {
        self.subsystem = subsystem
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
            startPolling(refreshInterval: refreshInterval)
        } catch {
            // OSLog failed, probably shouldn't use OSLog to log here
            print("OSLogManager: cannot instantiate OSLogStore")
            store = nil
        }
    }
    
    private func startPolling(refreshInterval: TimeInterval) {
        guard let store = store else { return }
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .receive(on: dispatchQueue)
            .tryMap { [subsystem] _ in
                try store.getEntries(matching: NSPredicate(format: #"subsystem == "\#(subsystem)""#))
            }
            .replaceError(with: AnySequence<OSLogEntry>([]))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEntries in
                guard let self = self else { return }
                // single use sequence, convert to array
                let actuallyNewEntries = Array(newEntries.dropFirst(self.entries.count))
                self.entries.append(contentsOf: actuallyNewEntries)
                for case let logEntry as OSLogEntryLog in actuallyNewEntries {
                    self.categories.insert(logEntry.category)
                }
            }
    }
}
