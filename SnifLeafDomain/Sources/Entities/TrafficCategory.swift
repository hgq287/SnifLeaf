//
//  TrafficCategory.swift
//  SnifLeafDomain
//
//  Domain entity – framework-agnostic.
//

import Foundation

public enum TrafficCategory: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case others = "Others"
    case sortsEndpoints = "Sorts Endpoints"
    case floAgileOrders = "Flo Agile Orders"
    case googleServices = "Google Services"
    case socialMedia = "Social Media"
    case videoStreaming = "Video Streaming"
    case gaming = "Gaming"
    case apiCallJson = "API Call (JSON)"
    case newsAndInformation = "News & Information"
    case email = "Email"
    case productivity = "Productivity"
    case shopping = "Shopping"
    case callChat = "Call/Chat"
    case security = "Security/VPN"
    case analytics = "Analytics"
    case socket = "Socket"
    case fileTransfer = "File Transfer"
    case p2p = "Peer-to-Peer"
    case systemUpdates = "System Updates"
    case advertisement = "Advertisement"
    case iotDevice = "IoT Device"
    case calendars = "Calendars"
    case floWeb = "Flo Web"
    case floApp = "Flo App"

    public static func fromString(_ string: String) -> TrafficCategory {
        TrafficCategory(rawValue: string) ?? .unknown
    }
}
