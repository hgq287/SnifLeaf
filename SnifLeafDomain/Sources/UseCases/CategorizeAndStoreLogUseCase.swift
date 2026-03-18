//
//  CategorizeAndStoreLogUseCase.swift
//  SnifLeafDomain
//
//  Use case protocol: categorize a log and persist it.
//

import Foundation

public protocol CategorizeAndStoreLogUseCase: AnyObject {
    func execute(_ log: LogEntry) async throws
}
