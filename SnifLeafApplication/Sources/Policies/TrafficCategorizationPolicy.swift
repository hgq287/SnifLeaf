//
//  TrafficCategorizationPolicy.swift
//  SnifLeafApplication
//
//  Maps URL/content to TrafficCategory (extracted from legacy LogProcessor rules).
//

import Foundation
import SnifLeafDomain

public struct TrafficCategorizationPolicy {
    public init() {}

    public func category(for log: LogEntry) -> TrafficCategory {
        let url = log.url
        if url.contains("video") { return .videoStreaming }
        if url.contains("/order") {
            return url.contains("agile/order") ? .floAgileOrders : .sortsEndpoints
        }
        if url.contains("domailsvr") { return .floWeb }
        if url.contains("v41-api") { return .floApp }
        if url.contains("chime") { return .callChat }
        if url.contains("socket") { return .socket }
        if url.contains("news") { return .newsAndInformation }
        if url.contains("imap") { return .email }
        if url.contains("flodav") { return .calendars }
        if url.contains("api-last-modified") { return .analytics }
        return .others
    }
}
