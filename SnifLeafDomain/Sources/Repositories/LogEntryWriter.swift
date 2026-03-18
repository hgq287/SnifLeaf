//
//  LogEntryWriter.swift
//  SnifLeafDomain
//
//  Port: narrow interface for log ingestion (used by Shared/LogProcessor).
//

import Foundation

public protocol LogEntryWriter: AnyObject {
    func append(_ log: LogEntry) async throws
    func appendBatch(_ logs: [LogEntry]) async throws
}
