//
//  GRDBManagerTests.swift
//  SnifLeafCoreTests
//
//  Created by Hg Q. on 30/6/25.
//

import XCTest
import GRDB
@testable import SnifLeafCore

final class GRDBManagerTests: XCTestCase {

    var dbPool: DatabasePool!
    var grdbManager: GRDBManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbURL = URL(fileURLWithPath: path).appendingPathComponent("test_snifleaf.sqlite3")
        grdbManager = GRDBManager.shared
        grdbManager.openDatabase(databaseURL: dbURL)
    }

    override func tearDownWithError() throws {
        grdbManager = nil
        dbPool = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Initialization

    func testDatabaseInitialization() async throws {
        // In setUp, the database is already initialized.
        // You might want to add assertions to check if the database file exists, etc.
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbURL = URL(fileURLWithPath: path).appendingPathComponent("test_snifleaf.sqlite3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbURL.path), "Database file should exist")
    }

    // MARK: - Test Insertion

    func testInsertLogEntry() async throws {
        let logEntry = LogEntry(
            id: nil, timestamp: Date(), method: "GET", url: "/test", host: "example.com",
            path: nil, queryParams: nil, requestSize: 100, responseSize: 200, statusCode: 200, latency: 0.1,
            requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil
        )
        await grdbManager.insertLogEntry(log: logEntry)

        let fetchedLogs = try await grdbManager.fetchAllLogs()
        XCTAssertEqual(fetchedLogs.count, 1, "Should be one log entry in the database")
        XCTAssertEqual(fetchedLogs.first?.url, "/test", "Fetched log entry URL should match")
    }

    // MARK: - Test Fetching

    func testFetchLogEntriesWithLimitAndOffset() async throws {
        // Insert multiple log entries
        for i in 0..<5 {
            let logEntry = LogEntry(
                id: nil, timestamp: Date().addingTimeInterval(TimeInterval(-i)), method: "GET", url: "/test\(i)", host: "example.com",
                path: nil, queryParams: nil, requestSize: 100, responseSize: 200, statusCode: 200, latency: 0.1,
                requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil
            )
            await grdbManager.insertLogEntry(log: logEntry)
        }

        let fetchedLogs = await grdbManager.fetchLogEntries(limit: 3)
        XCTAssertEqual(fetchedLogs.count, 3, "Should fetch 3 log entries with limit")

        let fetchedLogsWithOffset = await grdbManager.fetchLogEntries(limit: 2, offset: 2)
        XCTAssertEqual(fetchedLogsWithOffset.count, 2, "Should fetch 2 log entries with limit and offset")
        XCTAssertEqual(fetchedLogsWithOffset.first?.url, "/test2", "Fetched log entry URL at offset 2 should match")
    }

    func testFetchLogById() async throws {
        let logEntry = LogEntry(
            id: nil, timestamp: Date(), method: "POST", url: "/item", host: "api.example.com",
            path: nil, queryParams: nil, requestSize: 150, responseSize: 250, statusCode: 201, latency: 0.2,
            requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil
        )
        await grdbManager.insertLogEntry(log: logEntry)
        let insertedLogs = try await grdbManager.fetchAllLogs()
        guard let firstLogId = insertedLogs.first?.id else {
            XCTFail("Could not get ID of inserted log")
            return
        }

        let fetchedLog = try await grdbManager.fetchLog(by: Int64(firstLogId))
        XCTAssertNotNil(fetchedLog, "Should fetch a log entry by ID")
        XCTAssertEqual(fetchedLog?.method, "POST", "Fetched log entry method should match")
    }

    func testFilterLogsBySearchText() async throws {
        await insertTestLogs() // Helper function to insert some logs

        let filteredLogsByURL = try await grdbManager.filterLogs(searchText: "example.com/api")
        XCTAssertEqual(filteredLogsByURL.count, 2, "Should find logs with 'example.com/api' in URL")

        let filteredLogsByMethod = try await grdbManager.filterLogs(searchText: "PUT")
        XCTAssertEqual(filteredLogsByMethod.count, 1, "Should find log with 'PUT' method")

        let filteredLogsByStatusCode = try await grdbManager.filterLogs(searchText: "404")
        XCTAssertEqual(filteredLogsByStatusCode.count, 1, "Should find log with status code '404'")
    }

    func testFetchLogsWithLimitOffsetAndSearchText() async throws {
        await insertTestLogs()

        let fetchedLogs = try await grdbManager.fetchLogs(limit: 1, offset: 1, searchText: "example.com")
        XCTAssertEqual(fetchedLogs.count, 1, "Should fetch 1 log entry with limit, offset, and search text")
        XCTAssertTrue(fetchedLogs.first?.url.contains("example.com") ?? false, "Fetched log should contain the search text")
    }

    // MARK: - Test Deletion

    func testDeleteAllLogEntries() async throws {
        await insertTestLogs()

        await grdbManager.deleteAllLogEntries()
        let allLogs = try await grdbManager.fetchAllLogs()
        XCTAssertTrue(allLogs.isEmpty, "Database should be empty after deleting all logs")
    }

    // MARK: - Helper Functions

    private func insertTestLogs() async {
        await grdbManager.insertLogEntry(log: LogEntry(id: nil, timestamp: Date(), method: "GET", url: "https://example.com/api/data", host: "example.com", path: nil, queryParams: nil, requestSize: 200, responseSize: 300, statusCode: 200, latency: 0.15, requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil))
        await grdbManager.insertLogEntry(log: LogEntry(id: nil, timestamp: Date(), method: "POST", url: "https://example.com/api/items", host: "example.com", path: nil, queryParams: nil, requestSize: 250, responseSize: 350, statusCode: 201, latency: 0.20, requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil))
        await grdbManager.insertLogEntry(log: LogEntry(id: nil, timestamp: Date(), method: "PUT", url: "https://anothersite.com/resource", host: "anothersite.com", path: nil, queryParams: nil, requestSize: 180, responseSize: 280, statusCode: 200, latency: 0.10, requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil))
        await grdbManager.insertLogEntry(log: LogEntry(id: nil, timestamp: Date(), method: "GET", url: "https://example.com/error", host: "example.com", path: nil, queryParams: nil, requestSize: 100, responseSize: 150, statusCode: 404, latency: 0.08, requestHeaders: nil, responseHeaders: nil, requestBodyContent: nil, responseBodyContent: nil))
    }
}
