//
//  GRDBManager.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 3/6/25.
//

import Foundation
import Combine
import GRDB

public class GRDBManager: ObservableObject {
    public static let shared = GRDBManager()

    public var dbPool: DatabasePool!

    private init() {
        print("GRDBManager: Initialized")
    }
    
    public func openDatabase(databaseURL: URL) {
        do {
            dbPool = try DatabasePool(path: databaseURL.path)
            print("GRDBManager: Database opened and migrated at \(databaseURL.path)")
        } catch {
            print("GRDBManager: Error opening or migrating database: \(error)")
        }
    }
    
    public func migrateDatabase() {
        do {
            try migrator.migrate(dbPool)
            print("GRDBManager: Database migrated successfully.")
        } catch {
            print("GRDBManager: Error migrating database: \(error)")
        }
    }

    // MARK: - Database Migrations
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.eraseDatabaseOnSchemaChange = true

        migrator.registerMigration("createLogEntriesTable") { db in
            try db.create(table: LogEntry.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey(LogEntry.Columns.id.name)
                
                t.column(LogEntry.Columns.timestamp.name, .datetime).notNull()
                t.column(LogEntry.Columns.method.name, .text).notNull()
                t.column(LogEntry.Columns.url.name, .text).notNull()
                t.column(LogEntry.Columns.host.name, .text).notNull()
                t.column(LogEntry.Columns.path.name, .text)
                t.column(LogEntry.Columns.queryParams.name, .text)
                t.column(LogEntry.Columns.requestSize.name, .integer).notNull()
                t.column(LogEntry.Columns.responseSize.name, .integer).notNull()
                t.column(LogEntry.Columns.statusCode.name, .integer).notNull()
                t.column(LogEntry.Columns.latency.name, .double).notNull()
                t.column(LogEntry.Columns.requestHeaders.name, .text)
                t.column(LogEntry.Columns.responseHeaders.name, .text)
                t.column(LogEntry.Columns.requestBodyContent.name, .blob)
                t.column(LogEntry.Columns.responseBodyContent.name, .blob)
                t.column(LogEntry.Columns.trafficCategory.name, .text).notNull().collate(.nocase)
            }
        }
        
        migrator.registerMigration("addIndexesToLogEntries") { db in
            try db.execute(sql: """
                   CREATE UNIQUE INDEX IF NOT EXISTS idx_logEntries_timestamp_id ON log_entries (timestamp DESC, id DESC);
               """)
            
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_log_entries_url ON log_entries (url);
                CREATE INDEX IF NOT EXISTS idx_log_entries_host ON log_entries (host);
                CREATE INDEX IF NOT EXISTS idx_log_entries_path ON log_entries (path);
                CREATE INDEX IF NOT EXISTS idx_log_entries_method ON log_entries (method);
                CREATE INDEX IF NOT EXISTS idx_log_entries_statusCode ON log_entries (statusCode);
                CREATE INDEX IF NOT EXISTS idx_log_entries_latency ON log_entries (latency);
                CREATE INDEX IF NOT EXISTS idx_log_entries_queryParams ON log_entries (queryParams);
                CREATE INDEX IF NOT EXISTS idx_log_entries_requestSize ON log_entries (requestSize);
                CREATE INDEX IF NOT EXISTS idx_log_entries_responseSize ON log_entries (responseSize);
            """)
        }
        
        return migrator
    }

    // MARK: - Database Operations
    
    public func insertLogEntry(log: LogEntry) {
        var savedLog = log
        do {
            try dbPool.write { db in
                try savedLog.save(db)
            }

            DispatchQueue.main.async { [savedLog] in
                NotificationCenter.default.post(
                    name: .GRDBSavedNewLog,
                    object: nil,
                    userInfo: [NotificationKeys.newLogEntry: savedLog]
                )
            }
        } catch {
            print("Error saving log entry: \(error)")
        }
    }

    public func fetchLogEntries(limit: Int = 100, offset: Int = 0) async -> [LogEntry] {
        do {
            return try await dbPool.read { db in
                try LogEntry
                    .order(LogEntry.Columns.timestamp.desc) // Vẫn dùng Columns cho order/filter
                    .limit(limit, offset: offset)
                    .fetchAll(db)
            }
        } catch {
            print("GRDBManager: Error fetching log entries: \(error)")
            return []
        }
    }
    
    public func fetchAllLogs() async throws -> [LogEntry] {
        return try await dbPool.read { db in
            try LogEntry.order(LogEntry.Columns.timestamp.desc).fetchAll(db)
        }
    }
    
    public func fetchLog(by id: Int64) async throws -> LogEntry? {
        return try await dbPool.read { db in
            try LogEntry.filter(LogEntry.Columns.id == id).fetchOne(db)
        }
    }

    public func filterLogs(searchText: String) async throws -> [LogEntry] {
        return try await dbPool.read { db in
            var query = LogEntry.order(LogEntry.Columns.timestamp.desc).asRequest(of: LogEntry.self)

            if !searchText.isEmpty {
                let pattern = "%" + searchText.lowercased() + "%"
                query = query.filter(
                    LogEntry.Columns.url.like(pattern) ||
                    LogEntry.Columns.host.like(pattern) ||
                    LogEntry.Columns.method.like(pattern) ||
                    LogEntry.Columns.statusCode.like(pattern) // Coi statusCode là text để tìm kiếm
                )
            }
            return try query.fetchAll(db)
        }
    }
    
    public func fetchLogs(limit: Int, offset: Int, searchText: String) async throws -> [LogEntry] {
        return try await dbPool.read { db in
            var query = LogEntry.order(LogEntry.Columns.timestamp.desc).asRequest(of: LogEntry.self)

            if !searchText.isEmpty {
                let pattern = "%" + searchText.lowercased() + "%"
                query = query.filter(
                    LogEntry.Columns.url.like(pattern) ||
                    LogEntry.Columns.host.like(pattern) ||
                    LogEntry.Columns.method.like(pattern) ||
                    LogEntry.Columns.statusCode.like(pattern)
                )
            }

            return try query.limit(limit, offset: offset).fetchAll(db)
        }
    }
    public func fetchLogsCount(searchText: String) async throws -> Int {
        return try await dbPool.read { db in
            var query = LogEntry.all()
            if !searchText.isEmpty {
                let pattern = "%" + searchText.lowercased() + "%"
                query = query.filter(
                    LogEntry.Columns.url.like(pattern) ||
                    LogEntry.Columns.host.like(pattern) ||
                    LogEntry.Columns.method.like(pattern) ||
                    LogEntry.Columns.statusCode.like(pattern)
                )
            }
            return try query.fetchCount(db)
        }
    }
    
    public func deleteOldLogs(before date: Date) async throws {
        _ = try await dbPool.write { db in
            try LogEntry.filter(LogEntry.Columns.timestamp < date).deleteAll(db)
        }
        print("GRDBManager: Deleted logs older than \(date).")
    }


    public func deleteAllLogEntries() async {
       do {
           _ = try await dbPool.write { db in
               try LogEntry.deleteAll(db)
           }
           NotificationCenter.default.post(name: .GRDBDidUpdate, object: nil)
       } catch {
           print("Error deleting all log entries: \(error)")
       }
    }
}
