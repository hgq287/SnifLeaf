//
//  LogProcessor.swift
//  Shared
//
//  Created by Hg Q. on 11/6/25.
//

import Foundation
import SnifLeafCore

public class LogProcessor: ObservableObject {

    // MARK: - Dependencies
    private var dbManager: GRDBManager!

    public init(dbManager: GRDBManager) {
        self.dbManager = dbManager
        print("LogProcessor initialized.")
    }
    
    public func processBatchNewLogs(_ logEntries: [LogEntry]) {
        Task {
            for logEntry in logEntries {
                let logToSave = logEntry
                self.processNewLog(logToSave)
            }
        }
    }

    public func processNewLog(_ logEntry: LogEntry) {
        Task {
            var logToSave = logEntry
            
            let filteredCategory: TrafficCategory
            if logEntry.host!.contains("http://") {
                filteredCategory = .unknown
            } else if logEntry.host!.contains("docker") {
                filteredCategory = .systemUpdates
            } else if logEntry.host!.contains("floware") {
                filteredCategory = .apiCallJson
            } else if logEntry.host!.contains("teams") {
                filteredCategory = .productivity
            } else if logEntry.host!.contains("google") {
                filteredCategory = .googleServices
            } else if logEntry.host!.contains("youtube") {
                filteredCategory = .videoStreaming
            } else if logEntry.host!.contains("zalo")
                        || logEntry.host!.contains("messenger")
                        || logEntry.host!.contains("whatsapp")
                        || logEntry.host!.contains("viber")
                        || logEntry.host!.contains("telegram") {
                filteredCategory = .socialMedia
            } else {
                filteredCategory = .others
            }
            
            logToSave.trafficCategory = filteredCategory
            dbManager.insertLogEntry(log: logToSave)
        }
    }
}
