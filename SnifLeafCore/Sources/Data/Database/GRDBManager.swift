//
//  GRDBManager.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 3/6/25.
//

import Foundation
import GRDB

public class GRDBManager: ObservableObject {
    public static let shared = GRDBManager()

    private var dbPool: DatabasePool!
    public var dbQueue: DatabaseQueue!

    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbURL = URL(fileURLWithPath: path).appendingPathComponent("snifleaf.sqlite3")
            
            dbPool = try DatabasePool(path: dbURL.path)
            self.dbQueue = try DatabaseQueue(path: dbURL.path)
            
            try migrator.migrate(dbPool)
            print("GRDBManager: Database opened and migrated at \(dbURL.path)")
        } catch {
            print("GRDBManager: Error opening or migrating database: \(error)")
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
            }
        }
        return migrator
    }

    // MARK: - Database Operations
    
    public func insertLogEntry(log: LogEntry) async {
        do {
            try await dbPool.write { db in
                let mutableLog = log
                try mutableLog.insert(db)
            }
        } catch {
            print("GRDBManager: Error inserting log entry: \(error)")
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
    
    public func deleteOldLogs(before date: Date) async throws {
        try await dbPool.write { db in
            try LogEntry.filter(LogEntry.Columns.timestamp < date).deleteAll(db)
        }
        print("GRDBManager: Deleted logs older than \(date).")
    }

    public func deleteAllLogEntries() async throws {
        try await dbPool.write { db in
            try LogEntry.deleteAll(db)
        }
        print("GRDBManager: All logs deleted.")
    }
    
    /// Lấy tất cả LogEntry từ database, sắp xếp theo thời gian mới nhất.
    public func fetchAllLogs() async throws -> [LogEntry] {
        return try await dbQueue.read { db in
            try LogEntry.order(LogEntry.Columns.timestamp.desc).fetchAll(db)
        }
    }

    /// Lấy một LogEntry cụ thể theo ID.
    public func fetchLog(by id: Int64) async throws -> LogEntry? {
        return try await dbQueue.read { db in
            try LogEntry.filter(LogEntry.Columns.id == id).fetchOne(db)
        }
    }

    /// Lọc logs theo điều kiện tìm kiếm.
    /// Lưu ý: Đây là ví dụ đơn giản. Đối với các query phức tạp hơn, bạn sẽ xây dựng predicate GRDB.
    public func filterLogs(searchText: String) async throws -> [LogEntry] {
        return try await dbQueue.read { db in
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
}
