//
//  AppState.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 30/5/25.
//

import Foundation
import SwiftUI
import Shared
import SnifLeafCore
import UserNotifications
import Combine

@MainActor
public final class AppState: ObservableObject {

    // MARK: - Core Managers & Models
    @Published public var dbManager: GRDBManager
    @Published public var logProcessor: LogProcessor
    @Published public var proxyManager: MitmProcessManager

    // MARK: - Interactors (Feature-specific logic)
    @Published public var logListInteractor: LogListInteractor
    @Published public var amomaliesInteractor: AnomaliesInteractor
    
    // MARK: - Benchmarks
   @Published public var categoryBenchmarks: [BenchmarkMetrics] = []
   @Published public var endpointBenchmarks: [BenchmarkMetrics] = []
   
   @Published public var selectedDimension: BenchmarkDimension = .category
    @Published public var selectedTimeRange: TimeRange = .last7Days
    
    @Published var categoryMetrics: [SnifLeafCore.TrafficCategory: SnifLeafCore.BenchmarkMetrics] = [:]
    @Published var endpointMetrics: [String: SnifLeafCore.BenchmarkMetrics] = [:]
    @Published var isLoadingBenchmarks: Bool = false
    @Published var benchmarkErrorMessage: String?

    // MARK: - Benchmark Interactor
    private var benchmarkService: SnifLeafCore.BenchmarkService!
    private var benchmarkInteractor: BenchmarkInteractor!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    public init() {
        let _sharedDBManager = GRDBManager.shared
        let dbURL = AppConfig.databaseURL!
        _sharedDBManager.openDatabase(databaseURL: dbURL)
        _sharedDBManager.migrateDatabase()
        self.dbManager = _sharedDBManager
        
        let sharedLogProcessor = LogProcessor(dbManager: _sharedDBManager)
        self.logProcessor = sharedLogProcessor

        self.proxyManager = MitmProcessManager(logProcessor: sharedLogProcessor)
        
        self.logListInteractor = LogListInteractor(dbManager: _sharedDBManager)
        self.amomaliesInteractor = AnomaliesInteractor(dbManager: _sharedDBManager)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AppState: Notification permissions granted.")
            } else if let error = error {
                print("AppState: Error requesting notification permissions: \(error.localizedDescription)")
            }
        }

        self.benchmarkService = SnifLeafCore
            .BenchmarkService(
                dbPool: GRDBManager.shared.dbPool
            )


       self.benchmarkInteractor = BenchmarkInteractor(appState: self, benchmarkService: self.benchmarkService)
       $selectedTimeRange
           .combineLatest($selectedDimension)
           .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
           .sink { [weak self] _, _ in
               self?.benchmarkInteractor.fetchBenchmarks()
           }
           .store(in: &cancellables)

        print("AppState: All core components and interactors initialized.")
    }
    
    public func fetchBenchmarks() {
        Task {
            let startDate = selectedTimeRange.startDate() ?? Date(timeIntervalSince1970: 0)
            do {
                if selectedDimension == .category {
                    let bm = try await benchmarkService
                        .fetchCategoryBenchmarks(since: startDate)
                    await MainActor.run {
                        self.categoryBenchmarks = bm
                    }
                } else {
                    let bm = try await benchmarkService.fetchEndpointBenchmarks(
                        since: startDate,
                        filterByUrlContains: "google" // Example filter, adjust as needed
                    )
                    await MainActor.run {
                        self.endpointBenchmarks = bm
                    }
                }
            } catch {
                print("Error fetching benchmarks: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - App Lifecycle Methods
    public func startup() {
        Task {
            do {
                try await proxyManager.startProxy()
                print("AppState: Proxy started successfully.")
            } catch {
                print("AppState Error: Failed to start proxy: \(error)")
            }
        }
    }
    
    public func shutdown() {
        print("AppState: Shutdown sequence initiated, stopping proxy...")
        proxyManager.stopProxy()
    }
}


