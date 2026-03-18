//
//  GRDBLogEntryRepository.swift
//  SnifLeafCore
//

import Foundation
import SnifLeafDomain

public final class GRDBLogEntryRepository: LogEntryRepository, LogEntryWriter {
    private let manager: GRDBManager

    /// Called after a log is successfully inserted (e.g. for UI subscription).
    public var onLogInserted: ((SnifLeafDomain.LogEntry) -> Void)?

    public init(manager: GRDBManager) {
        self.manager = manager
    }

    public func fetchLogs(limit: Int, offset: Int, searchText: String) async throws -> [SnifLeafDomain.LogEntry] {
        let coreLogs = try await manager.fetchLogs(limit: limit, offset: offset, searchText: searchText)
        return coreLogs.map { $0.toDomain() }
    }

    public func fetchLogsCount(searchText: String) async throws -> Int {
        try await manager.fetchLogsCount(searchText: searchText)
    }

    public func insert(_ log: SnifLeafDomain.LogEntry) async throws {
        let coreLog = LogEntry(from: log)
        try await manager.insertLogEntryAsync(coreLog)
        onLogInserted?(log)
    }

    public func deleteAllLogEntries() async throws {
        await manager.deleteAllLogEntries()
    }

    public func append(_ log: SnifLeafDomain.LogEntry) async throws {
        try await insert(log)
    }

    public func appendBatch(_ logs: [SnifLeafDomain.LogEntry]) async throws {
        for log in logs {
            try await append(log)
        }
    }
}
