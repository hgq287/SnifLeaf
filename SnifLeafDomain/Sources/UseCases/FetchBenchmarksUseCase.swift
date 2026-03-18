//
//  FetchBenchmarksUseCase.swift
//  SnifLeafDomain
//
//  Use case protocol: fetch benchmarks by category or endpoint.
//

import Foundation

public protocol FetchBenchmarksUseCase: AnyObject {
    func fetchCategoryBenchmarks(since startDate: Date?) async throws -> [BenchmarkMetrics]
    func fetchEndpointBenchmarks(since startDate: Date?, filterByUrlContains: String?) async throws -> [BenchmarkMetrics]
}
