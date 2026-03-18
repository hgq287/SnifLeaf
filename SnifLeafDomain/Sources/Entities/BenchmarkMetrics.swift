//
//  BenchmarkMetrics.swift
//  SnifLeafDomain
//
//  Domain value type – framework-agnostic.
//

import Foundation

public struct BenchmarkMetrics: Identifiable {
    public let id = UUID()
    public let dimension: String
    public let requestCount: Int
    public let avgLatency: Double
    public let p95Latency: Double
    public let errorRate: Double

    public init(dimension: String, requestCount: Int, avgLatency: Double, p95Latency: Double, errorRate: Double) {
        self.dimension = dimension
        self.requestCount = requestCount
        self.avgLatency = avgLatency
        self.p95Latency = p95Latency
        self.errorRate = errorRate
    }
}
