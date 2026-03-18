//
//  BenchmarkRepository.swift
//  SnifLeafDomain
//
//  Port: benchmark query service.
//

import Foundation

public protocol BenchmarkRepository: AnyObject {
    func fetchCategoryBenchmarks(since startDate: Date?) async throws -> [BenchmarkMetrics]
    func fetchEndpointBenchmarks(since startDate: Date?, filterByUrlContains: String?) async throws -> [BenchmarkMetrics]
}
