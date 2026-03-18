//
//  AppState.swift
//  SnifLeaf-macOS
//
//  Composition root: builds repositories, use cases, and interactors.
//

import Foundation
import SwiftUI
import Shared
import SnifLeafCore
import SnifLeafApplication
import SnifLeafDomain
import UserNotifications
import Combine

@MainActor
public final class AppState: ObservableObject {

    // MARK: - Injected to views
    @Published public var logProcessor: LogProcessor
    @Published public var proxyManager: MitmProcessManager
    @Published public var logListInteractor: LogListInteractor
    @Published public var amomaliesInteractor: AnomaliesInteractor

    // MARK: - Benchmark state
    @Published public var categoryBenchmarks: [SnifLeafDomain.BenchmarkMetrics] = []
    @Published public var endpointBenchmarks: [SnifLeafDomain.BenchmarkMetrics] = []
    @Published public var selectedDimension: BenchmarkDimension = .category
    @Published public var selectedTimeRange: TimeRange = .last7Days
    @Published public var categoryMetrics: [SnifLeafDomain.TrafficCategory: SnifLeafDomain.BenchmarkMetrics] = [:]
    @Published public var endpointMetrics: [String: SnifLeafDomain.BenchmarkMetrics] = [:]
    @Published public var isLoadingBenchmarks: Bool = false
    @Published public var benchmarkErrorMessage: String?

    private var benchmarkInteractor: BenchmarkInteractor!
    private var cancellables = Set<AnyCancellable>()

    public init() {
        let dbManager = GRDBManager.shared
        let dbURL = AppConfig.databaseURL!
        dbManager.openDatabase(databaseURL: dbURL)
        dbManager.migrateDatabase()

        let logRepository = GRDBLogEntryRepository(manager: dbManager)
        let newLogSubject = PassthroughSubject<SnifLeafDomain.LogEntry, Never>()
        logRepository.onLogInserted = { newLogSubject.send($0) }

        let benchmarkService = SnifLeafCore.BenchmarkService(dbPool: dbManager.dbPool)
        let benchmarkRepository = GRDBBenchmarkRepository(benchmarkService: benchmarkService)

        let fetchPaginatedLogsUseCase = FetchPaginatedLogsUseCaseImpl(repository: logRepository)
        let categorizeAndStoreUseCase = CategorizeAndStoreLogUseCaseImpl(writer: logRepository)
        let fetchBenchmarksUseCase = FetchBenchmarksUseCaseImpl(repository: benchmarkRepository)

        let categorizeAndStore = categorizeAndStoreUseCase
        let lp = LogProcessor(categorizeAndStore: categorizeAndStore)
        let pm = MitmProcessManager(logProcessor: lp)
        logProcessor = lp
        proxyManager = pm

        logListInteractor = LogListInteractor(
            fetchPaginatedLogs: fetchPaginatedLogsUseCase,
            logRepository: logRepository,
            newLogPublisher: newLogSubject.eraseToAnyPublisher()
        )
        amomaliesInteractor = AnomaliesInteractor(fetchPaginatedLogs: fetchPaginatedLogsUseCase)

        benchmarkInteractor = BenchmarkInteractor(
            appState: self,
            fetchBenchmarksUseCase: fetchBenchmarksUseCase
        )

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AppState: Notification permissions granted.")
            } else if let error = error {
                print("AppState: Error requesting notification permissions: \(error.localizedDescription)")
            }
        }

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
        benchmarkInteractor.fetchBenchmarks()
    }

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
