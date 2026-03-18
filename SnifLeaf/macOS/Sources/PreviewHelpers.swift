//
//  PreviewHelpers.swift
//  SnifLeaf-macOS
//
//  Mocks for SwiftUI previews only.
//

#if DEBUG
import Foundation
import Combine
import Shared
import SnifLeafDomain
import SnifLeafApplication

@MainActor
enum PreviewHelpers {

    static func makeMitmProcessManager() -> MitmProcessManager {
        let mockUseCase = MockCategorizeAndStoreLogUseCase()
        let processor = LogProcessor(categorizeAndStore: mockUseCase)
        return MitmProcessManager(logProcessor: processor)
    }

    static func makeLogListInteractor() -> LogListInteractor {
        let repo = MockLogEntryRepository()
        let useCase = FetchPaginatedLogsUseCaseImpl(repository: repo)
        let publisher = Empty<SnifLeafDomain.LogEntry, Never>().eraseToAnyPublisher()
        return LogListInteractor(
            fetchPaginatedLogs: useCase,
            logRepository: repo,
            newLogPublisher: publisher
        )
    }
}

private final class MockCategorizeAndStoreLogUseCase: CategorizeAndStoreLogUseCase {
    func execute(_ log: SnifLeafDomain.LogEntry) async throws {}
}

private final class MockLogEntryRepository: LogEntryRepository, LogEntryWriter {
    func fetchLogs(limit: Int, offset: Int, searchText: String) async throws -> [SnifLeafDomain.LogEntry] {
        []
    }
    func fetchLogsCount(searchText: String) async throws -> Int { 0 }
    func insert(_ log: SnifLeafDomain.LogEntry) async throws {}
    func deleteAllLogEntries() async throws {}
    func append(_ log: SnifLeafDomain.LogEntry) async throws {}
    func appendBatch(_ logs: [SnifLeafDomain.LogEntry]) async throws {}
}
#endif
