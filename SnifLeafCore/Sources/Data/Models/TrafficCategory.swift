//
//  TrafficCategory.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 7/7/25.
//

import Foundation

// MARK: - TrafficCategory Enum
public enum TrafficCategory: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case other = "Other"

    public static func fromString(_ string: String) -> TrafficCategory {
        return TrafficCategory(rawValue: string) ?? .unknown
    }
}
