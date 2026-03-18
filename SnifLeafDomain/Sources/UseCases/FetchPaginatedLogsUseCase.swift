//
//  FetchPaginatedLogsUseCase.swift
//  SnifLeafDomain
//
//  Use case protocol: fetch paginated logs and total count.
//

import Foundation

public protocol FetchPaginatedLogsUseCase: AnyObject {
    func loadPage(offset: Int, limit: Int, searchText: String) async throws -> (logs: [LogEntry], totalCount: Int)
}
