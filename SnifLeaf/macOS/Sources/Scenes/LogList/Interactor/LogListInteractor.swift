//
//  LogListInteractor.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 30/5/25.
//

import Foundation
import SwiftUI
import Combine
import GRDB
import SnifLeafCore

public final class LogListInteractor: ObservableObject {

    // MARK: - Dependencies
    private let dbManager: GRDBManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties
    @Published public var logs: [LogEntry] = []
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false
    
    @Published public var hasMoreLogs: Bool = true
    @Published public var totalLogsCount: Int = 0
    
    private var itemsPerPage: Int = 50
    private var loadedOffset: Int = 0

    // MARK: - Init
    public init(dbManager: GRDBManager) {
        self.dbManager = dbManager
        
        // Observe the change of `searchText` to filter automatically
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter {
                $0.isEmpty || $0.count > 1
            }
            .sink { [weak self] _ in
                self?.resetAndLoadLogs()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .GRDBDidUpdate)
            .sink { [weak self] _ in
                self?.resetAndLoadLogs()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .GRDBSavedNewLog)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let newLog = notification.userInfo?[NotificationKeys.newLogEntry] as? LogEntry {
                    if !self.logs.contains(where: { $0.id == newLog.id }) {
                    
                    withAnimation(.interpolatingSpring(stiffness: 250, damping: 25)) {
                        self.logs.insert(newLog, at: 0)
                        self.totalLogsCount += 1
                        self.loadedOffset += 1
                        self.updateHasMoreLogsState()
                    }
//                        self.logs.insert(newLog, at: 0)
//                        self.totalLogsCount += 1
//
//                        self.loadedOffset += 1
//                        self.updateHasMoreLogsState()
                    }
                } 
            }
            .store(in: &cancellables)
        
        // load initial logs
        resetAndLoadLogs()
    }

    // MARK: - Business Logic Methods
    
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
                let fetchedLogs = try await dbManager.fetchLogs(limit: itemsPerPage, offset: offset, searchText: searchText)
                
                await MainActor.run {
                    
                    if clearExisting {
                        self.logs = fetchedLogs
                    } else {
                        let existingLogIds = Set(self.logs.compactMap { $0.id })
                        let uniqueNewLogs = fetchedLogs.filter { newLog in
                            guard let newId = newLog.id else { return false }
                            return !existingLogIds.contains(newId)
                        }
                        self.logs.append(contentsOf: uniqueNewLogs)
                    }
                    
                    self.loadedOffset = offset + fetchedLogs.count
                    self.updateHasMoreLogsState()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("LogListInteractor: Failed to load logs from offset \(offset): \(error.localizedDescription)")
                    self.hasMoreLogs = false
                    isLoading = false
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
                self.totalLogsCount = try await dbManager.fetchLogsCount(searchText: searchText)
                self.updateHasMoreLogsState()
            } catch {
                print("LogListInteractor: Failed to fetch total logs count: \(error.localizedDescription)")
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
                try  await dbManager.deleteAllLogEntries()
                print("LogListInteractor: All log entries deleted successfully.")
            } catch {
                print("LogListInteractor: Failed to delete all log entries: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
