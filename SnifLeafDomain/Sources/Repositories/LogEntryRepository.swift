//
//  LogEntryRepository.swift
//  SnifLeafDomain
//
//  Port: repository protocol for log entry persistence.
//

import Foundation

public protocol LogEntryRepository: AnyObject {
    func fetchLogs(limit: Int, offset: Int, searchText: String) async throws -> [LogEntry]
    func fetchLogsCount(searchText: String) async throws -> Int
    func insert(_ log: LogEntry) async throws
    func deleteAllLogEntries() async throws
}
