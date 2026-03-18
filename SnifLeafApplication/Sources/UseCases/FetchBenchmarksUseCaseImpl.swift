//
//  FetchBenchmarksUseCaseImpl.swift
//  SnifLeafApplication
//

import Foundation
import SnifLeafDomain

public final class FetchBenchmarksUseCaseImpl: FetchBenchmarksUseCase {
    private let repository: BenchmarkRepository

    public init(repository: BenchmarkRepository) {
        self.repository = repository
    }

    public func fetchCategoryBenchmarks(since startDate: Date?) async throws -> [BenchmarkMetrics] {
        try await repository.fetchCategoryBenchmarks(since: startDate)
    }

    public func fetchEndpointBenchmarks(since startDate: Date?, filterByUrlContains: String?) async throws -> [BenchmarkMetrics] {
        try await repository.fetchEndpointBenchmarks(since: startDate, filterByUrlContains: filterByUrlContains)
    }
}
