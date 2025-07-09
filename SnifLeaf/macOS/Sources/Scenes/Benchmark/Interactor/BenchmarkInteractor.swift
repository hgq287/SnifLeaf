//
//  BenchmarkInteractor.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 7/7/25.
//

import Foundation
import Combine
import SnifLeafCore

// MARK: - BenchmarkInteractor
final class BenchmarkInteractor {
    private unowned let appState: AppState
    private let benchmarkService: SnifLeafCore.BenchmarkService

    init(appState: AppState, benchmarkService: SnifLeafCore.BenchmarkService) {
        self.appState = appState
        self.benchmarkService = benchmarkService
    }

    func fetchBenchmarks() {
        appState.isLoadingBenchmarks = true
        appState.benchmarkErrorMessage = nil
        
        Task {
            do {
                if appState.selectedDimension == .category {
                    let metrics = try await benchmarkService.fetchCategoryBenchmarks(
                        since: appState.selectedTimeRange.startDate() ?? Date(timeIntervalSince1970: 0)
                    )
                    await MainActor.run {
//                        self.appState.categoryMetrics = metrics
                        self.appState.endpointMetrics = [:]
                        self.appState.isLoadingBenchmarks = false
                    }
                } else { // "Endpoint"
                    /// Fetch endpoint benchmarks
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
