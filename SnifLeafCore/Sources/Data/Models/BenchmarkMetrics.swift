//
//  BenchmarkMetrics.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 7/7/25.
//

import Foundation
public struct BenchmarkMetrics: Identifiable {
    public let id = UUID()
    public let dimension: String
    public let requestCount: Int
    public let avgLatency: Double
    public let p95Latency: Double // 95th percentile latency
    public let errorRate: Double // Percentage of requests with non-2xx status codes

    public init(dimension: String, requestCount: Int, avgLatency: Double, p95Latency: Double, errorRate: Double) {
        self.dimension = dimension
        self.requestCount = requestCount
        self.avgLatency = avgLatency
        self.p95Latency = p95Latency
        self.errorRate = errorRate
    }
}
