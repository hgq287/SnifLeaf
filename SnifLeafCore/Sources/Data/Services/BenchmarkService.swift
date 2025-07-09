//
//  BenchmarkService.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 7/7/25.
//

import Foundation
import GRDB // Import GRDB

public class BenchmarkService {
    private let dbPool: DatabasePool

    public init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

    private func calculateP95(latencies: [Double]) -> Double {
        guard !latencies.isEmpty else { return 0.0 }
        let sortedLatencies = latencies.sorted()
        let index = Int(ceil(0.95 * Double(sortedLatencies.count))) - 1
        return sortedLatencies[max(0, min(index, sortedLatencies.count - 1))]
    }

    // MARK: - Fetch Category Benchmarks
        public func fetchCategoryBenchmarks(since startDate: Date?) async throws -> [BenchmarkMetrics] {
            try await dbPool.read { db in
                var sql = """
                SELECT
                    traffic_category AS dimension,
                    COUNT(id) AS requestCount,
                    AVG(latency) AS avgLatency,
                    SUM(CASE WHEN statusCode >= 400 THEN 1 ELSE 0 END) AS errorCount
                FROM
                    log_entries
                """
                
                var arguments: StatementArguments = []
                if let start = startDate {
                    sql += " WHERE timestamp >= ?"
                    // FIX HERE: Convert Date to TimeIntervalSince1970 (Unix timestamp)
                    arguments.append(contentsOf: [start])
                }
                
                sql += " GROUP BY traffic_category ORDER BY traffic_category"

                // Fetch rows using raw SQL
                let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)

                var metrics: [BenchmarkMetrics] = []
                for row in rows {
                    let category: String = row["dimension"]
                    let requestCount: Int = row["requestCount"]
                    let avgLatency: Double = row["avgLatency"] ?? 0.0
                    let errorCount: Int = row["errorCount"] ?? 0

                    // For P95, we still need to fetch individual latencies.
                    // Using QueryInterface for this sub-query is fine as it's a simple filter and select.
                    let latenciesForCategory = try LogEntry.filter(
                        LogEntry.Columns.trafficCategory == category &&
                        (startDate == nil || LogEntry.Columns.timestamp >= startDate!)
                    )
                    .select(LogEntry.Columns.latency)
                    .fetchAll(db)
                    .map { $0[LogEntry.Columns.latency] as Double }

                    let p95Latency = self.calculateP95(
                        latencies: latenciesForCategory
                    )
                    let errorRate = requestCount > 0 ? Double(errorCount) / Double(requestCount) : 0.0

                    metrics.append(BenchmarkMetrics(
                        dimension: category,
                        requestCount: requestCount,
                        avgLatency: avgLatency,
                        p95Latency: p95Latency,
                        errorRate: errorRate
                    ))
                }
                return metrics.sorted { $0.requestCount > $1.requestCount }
            }
        }
    
    // MARK: - Fetch Endpoint Benchmarks
    public func fetchEndpointBenchmarks(since startDate: Date?, filterByUrlContains: String? = nil) async throws -> [BenchmarkMetrics] {
            try await dbPool.read { db in
                var sql = """
                SELECT
                    url AS dimension,
                    COUNT(id) AS requestCount,
                    AVG(latency) AS avgLatency,
                    SUM(CASE WHEN statusCode >= 400 THEN 1 ELSE 0 END) AS errorCount
                FROM
                    log_entries
                """
                
                var whereClauses: [String] = []
                var arguments: StatementArguments = []

                if let start = startDate {
                    whereClauses.append("timestamp >= ?")
                    arguments.append(contentsOf: [start])
                }
                
                if let filter = filterByUrlContains, !filter.isEmpty {
                    whereClauses.append("url LIKE ?")
                    arguments.append(contentsOf: ["%" + filter + "%"])
                }

                if !whereClauses.isEmpty {
                    sql += " WHERE " + whereClauses.joined(separator: " AND ")
                }
                
                sql += " GROUP BY url ORDER BY url"

                let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)

                var metrics: [BenchmarkMetrics] = []
                for row in rows {
                    let dimension: String = row["dimension"]
                    let requestCount: Int = row["requestCount"]
                    let avgLatency: Double = row["avgLatency"] ?? 0.0
                    let errorCount: Int = row["errorCount"] ?? 0

                    var p95Query = LogEntry.filter(LogEntry.Columns.url == dimension)
                    
                    if let start = startDate {
                        p95Query = p95Query.filter(LogEntry.Columns.timestamp >= start)
                    }
                    
                    if let filter = filterByUrlContains, !filter.isEmpty {
                        p95Query = p95Query.filter(LogEntry.Columns.url.like("%" + filter + "%"))
                    }


                    let latenciesForEndpoint = try p95Query
                        .select(LogEntry.Columns.latency)
                        .fetchAll(db)
                        .map { $0[LogEntry.Columns.latency] as Double }

                    let p95Latency = self.calculateP95(
                        latencies: latenciesForEndpoint
                    )
                    let errorRate = requestCount > 0 ? Double(errorCount) / Double(requestCount) : 0.0

                    metrics.append(BenchmarkMetrics(
                        dimension: dimension,
                        requestCount: requestCount,
                        avgLatency: avgLatency,
                        p95Latency: p95Latency,
                        errorRate: errorRate
                    ))
                }
                return metrics.sorted { $0.requestCount > $1.requestCount }
            }
        }
}
