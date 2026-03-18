//
//  LogProcessor.swift
//  Shared
//
//  Depends only on SnifLeafDomain; categorizes and stores via use case.
//

import Foundation
import SnifLeafDomain

public class LogProcessor: ObservableObject {
    private let categorizeAndStore: CategorizeAndStoreLogUseCase

    public init(categorizeAndStore: CategorizeAndStoreLogUseCase) {
        self.categorizeAndStore = categorizeAndStore
    }

    public func processBatchNewLogs(_ logEntries: [LogEntry]) {
        Task {
            for logEntry in logEntries {
                await processNewLog(logEntry)
            }
        }
    }

    public func processNewLog(_ logEntry: LogEntry) {
        Task {
            do {
                try await categorizeAndStore.execute(logEntry)
            } catch {
                print("LogProcessor: Failed to store log: \(error)")
            }
        }
    }
}
