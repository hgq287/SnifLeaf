//
//  LogListInteractor.swift
//  SnifLeaf-macOS
//

import Foundation
import SwiftUI
import Combine
import SnifLeafDomain
import SnifLeafApplication
import SnifLeafCore

public final class LogListInteractor: ObservableObject {

    private let fetchPaginatedLogs: FetchPaginatedLogsUseCase
    private let logRepository: LogEntryRepository
    private let newLogPublisher: AnyPublisher<SnifLeafDomain.LogEntry, Never>
    private var cancellables = Set<AnyCancellable>()

    @Published public var logs: [SnifLeafDomain.LogEntry] = []
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false
    @Published public var hasMoreLogs: Bool = true
    @Published public var totalLogsCount: Int = 0

    private var itemsPerPage: Int = 50
    private var loadedOffset: Int = 0

    public init(
        fetchPaginatedLogs: FetchPaginatedLogsUseCase,
        logRepository: LogEntryRepository,
        newLogPublisher: AnyPublisher<SnifLeafDomain.LogEntry, Never>
    ) {
        self.fetchPaginatedLogs = fetchPaginatedLogs
        self.logRepository = logRepository
        self.newLogPublisher = newLogPublisher

        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { $0.isEmpty || $0.count > 1 }
            .sink { [weak self] _ in self?.resetAndLoadLogs() }
            .store(in: &cancellables)

        newLogPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLog in
                guard let self = self else { return }
                if !self.logs.contains(where: { $0.id == newLog.id }) {
                    self.logs.insert(newLog, at: 0)
                    self.totalLogsCount += 1
                    self.loadedOffset += 1
                    self.updateHasMoreLogsState()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .GRDBDidUpdate)
            .sink { [weak self] _ in self?.resetAndLoadLogs() }
            .store(in: &cancellables)

        resetAndLoadLogs()
    }

    private func resetAndLoadLogs() {
        loadedOffset = 0
        logs = []
        hasMoreLogs = true
        loadPage(offset: 0, clearExisting: true)
        fetchTotalLogsCount()
    }

    private func loadPage(offset: Int, clearExisting: Bool) {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let (fetchedLogs, totalCount) = try await fetchPaginatedLogs.loadPage(
                    offset: offset,
                    limit: itemsPerPage,
                    searchText: searchText
                )
                await MainActor.run {
                    if clearExisting {
                        self.logs = fetchedLogs
                    } else {
                        let existingIds = Set(self.logs.compactMap { $0.id })
                        let unique = fetchedLogs.filter { log in
                            guard let id = log.id else { return false }
                            return !existingIds.contains(id)
                        }
                        self.logs.append(contentsOf: unique)
                    }
                    self.loadedOffset = offset + fetchedLogs.count
                    self.totalLogsCount = totalCount
                    self.updateHasMoreLogsState()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("LogListInteractor: Failed to load logs: \(error.localizedDescription)")
                    self.hasMoreLogs = false
                    self.isLoading = false
                }
            }
        }
    }

    public func loadNextPage() {
        guard !isLoading && hasMoreLogs else { return }
        loadPage(offset: loadedOffset, clearExisting: false)
    }

    private func fetchTotalLogsCount() {
        Task { @MainActor in
            do {
                self.totalLogsCount = try await logRepository.fetchLogsCount(searchText: searchText)
                self.updateHasMoreLogsState()
            } catch {
                self.totalLogsCount = self.logs.count
            }
        }
    }

    private func updateHasMoreLogsState() {
        hasMoreLogs = logs.count < totalLogsCount
    }

    public func deleteAllLogs() {
        Task { @MainActor in
            isLoading = true
            do {
                try await logRepository.deleteAllLogEntries()
                print("LogListInteractor: All log entries deleted successfully.")
            } catch {
                print("LogListInteractor: Failed to delete all log entries: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
