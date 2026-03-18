//
//  BenchmarkInteractor.swift
//  SnifLeaf-macOS
//

import Foundation
import Combine
import SnifLeafDomain
import SnifLeafApplication

@MainActor
final class BenchmarkInteractor {
    private unowned let appState: AppState
    private let fetchBenchmarksUseCase: FetchBenchmarksUseCase

    init(appState: AppState, fetchBenchmarksUseCase: FetchBenchmarksUseCase) {
        self.appState = appState
        self.fetchBenchmarksUseCase = fetchBenchmarksUseCase
    }

    func fetchBenchmarks() {
        appState.isLoadingBenchmarks = true
        appState.benchmarkErrorMessage = nil

        Task {
            do {
                let startDate = appState.selectedTimeRange.startDate() ?? Date(timeIntervalSince1970: 0)
                if appState.selectedDimension == .category {
                    let metrics = try await fetchBenchmarksUseCase.fetchCategoryBenchmarks(since: startDate)
                    await MainActor.run {
                        self.appState.categoryBenchmarks = metrics
                        self.appState.endpointMetrics = [:]
                        self.appState.isLoadingBenchmarks = false
                    }
                } else {
                    let metrics = try await fetchBenchmarksUseCase.fetchEndpointBenchmarks(
                        since: startDate,
                        filterByUrlContains: "google"
                    )
                    await MainActor.run {
                        self.appState.endpointBenchmarks = metrics
                        self.appState.categoryMetrics = [:]
                        self.appState.isLoadingBenchmarks = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.appState.benchmarkErrorMessage = "Failed to load benchmarks: \(error.localizedDescription)"
                    self.appState.isLoadingBenchmarks = false
                }
            }
        }
    }
}
