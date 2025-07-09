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
    case others = "Others"
    case googleServices = "Google Services"
    case socialMedia = "Social Media"
    case videoStreaming = "Video Streaming"
    case gaming = "Gaming"
    case apiCallJson = "API Call (JSON)"
    case newsAndInformation = "News & Information"
    case email = "Email"
    case productivity = "Productivity"
    case shopping = "Shopping"
    case security = "Security/VPN"
    case fileTransfer = "File Transfer"
    case p2p = "Peer-to-Peer"
    case systemUpdates = "System Updates"
    case advertisement = "Advertisement"
    case iotDevice = "IoT Device"

    public static func fromString(_ string: String) -> TrafficCategory {
        return TrafficCategory(rawValue: string) ?? .unknown
    }
}
