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

    public func processNewLog(_ logEntry: LogEntry) {
        Task {
            await dbManager.insertLogEntry(log: logEntry)
        }
    }
}
