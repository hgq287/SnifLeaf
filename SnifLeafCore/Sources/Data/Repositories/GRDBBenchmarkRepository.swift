//
//  GRDBBenchmarkRepository.swift
//  SnifLeafCore
//

import Foundation
import SnifLeafDomain

public final class GRDBBenchmarkRepository: BenchmarkRepository {
    private let benchmarkService: BenchmarkService

    public init(benchmarkService: BenchmarkService) {
        self.benchmarkService = benchmarkService
    }

    public func fetchCategoryBenchmarks(since startDate: Date?) async throws -> [SnifLeafDomain.BenchmarkMetrics] {
        try await benchmarkService.fetchCategoryBenchmarks(since: startDate)
    }

    public func fetchEndpointBenchmarks(since startDate: Date?, filterByUrlContains: String?) async throws -> [SnifLeafDomain.BenchmarkMetrics] {
        try await benchmarkService.fetchEndpointBenchmarks(since: startDate, filterByUrlContains: filterByUrlContains)
    }
}
