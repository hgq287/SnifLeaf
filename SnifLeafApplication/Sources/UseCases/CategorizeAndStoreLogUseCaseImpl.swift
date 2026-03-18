//
//  CategorizeAndStoreLogUseCaseImpl.swift
//  SnifLeafApplication
//

import Foundation
import SnifLeafDomain

public final class CategorizeAndStoreLogUseCaseImpl: CategorizeAndStoreLogUseCase {
    private let writer: LogEntryWriter
    private let policy: TrafficCategorizationPolicy

    public init(writer: LogEntryWriter, policy: TrafficCategorizationPolicy = TrafficCategorizationPolicy()) {
        self.writer = writer
        self.policy = policy
    }

    public func execute(_ log: LogEntry) async throws {
        var categorized = log
        categorized.trafficCategory = policy.category(for: log)
        try await writer.append(categorized)
    }
}
