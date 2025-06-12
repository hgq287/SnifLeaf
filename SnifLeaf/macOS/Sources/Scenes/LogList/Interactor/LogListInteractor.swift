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

    // MARK: - Published Properties (Dữ liệu và UI State mà View sẽ theo dõi)
    @Published public var logs: [LogEntry] = []
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false

    // MARK: - Init
    public init(dbManager: GRDBManager) {
        self.dbManager = dbManager
        
        // Observe the change of `searchText` to filter automatically
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.loadLogs()
            }
            .store(in: &cancellables)
        
        // Listen for database updates to reload logs
        NotificationCenter.default.publisher(for: .GRDBDidUpdate)
            .sink { [weak self] _ in
                self?.loadLogs()
            }
            .store(in: &cancellables)
        
        // load initial logs
        loadLogs()
    }

    // MARK: - Business Logic Methods

    public func loadLogs() {
        Task { @MainActor in
            isLoading = true
            do {
                let fetchedLogs = try await dbManager.filterLogs(searchText: searchText)
                self.logs = fetchedLogs
            } catch {
                print("LogListInteractor: Failed to load logs: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    public func deleteAllLogs() {
        Task { @MainActor in
            isLoading = true
            do {
                try await dbManager.deleteAllLogEntries()
                print("LogListInteractor: All log entries deleted successfully.")
            } catch {
                print("LogListInteractor: Failed to delete all log entries: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

extension Notification.Name {
    public static let GRDBDidUpdate = Notification.Name("GRDBDidUpdate")
}
