//
//  FetchPaginatedLogsUseCaseImpl.swift
//  SnifLeafApplication
//

import Foundation
import SnifLeafDomain

public final class FetchPaginatedLogsUseCaseImpl: FetchPaginatedLogsUseCase {
    private let repository: LogEntryRepository

    public init(repository: LogEntryRepository) {
        self.repository = repository
    }

    public func loadPage(offset: Int, limit: Int, searchText: String) async throws -> (logs: [LogEntry], totalCount: Int) {
        async let logsTask = repository.fetchLogs(limit: limit, offset: offset, searchText: searchText)
        async let countTask = repository.fetchLogsCount(searchText: searchText)
        let (logs, totalCount) = try await (logsTask, countTask)
        return (logs, totalCount)
    }
}
