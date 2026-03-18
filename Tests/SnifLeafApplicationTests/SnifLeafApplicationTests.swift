//
//  SnifLeafApplicationTests.swift
//  SnifLeafApplicationTests
//

import XCTest
import SnifLeafDomain
@testable import SnifLeafApplication

final class SnifLeafApplicationTests: XCTestCase {

    func testTrafficCategorizationPolicy_video() {
        let policy = TrafficCategorizationPolicy()
        let log = LogEntry(
            timestamp: Date(),
            method: "GET",
            url: "https://example.com/video/stream",
            host: "example.com",
            path: nil,
            queryParams: nil,
            requestSize: 0,
            responseSize: 0,
            statusCode: 200,
            latency: 0,
            requestHeaders: nil,
            responseHeaders: nil,
            requestBodyContent: nil,
            responseBodyContent: nil,
            trafficCategory: .unknown
        )
        XCTAssertEqual(policy.category(for: log), .videoStreaming)
    }

    func testTrafficCategorizationPolicy_others() {
        let policy = TrafficCategorizationPolicy()
        let log = LogEntry(
            timestamp: Date(),
            method: "GET",
            url: "https://example.com/other",
            host: "example.com",
            path: nil,
            queryParams: nil,
            requestSize: 0,
            responseSize: 0,
            statusCode: 200,
            latency: 0,
            requestHeaders: nil,
            responseHeaders: nil,
            requestBodyContent: nil,
            responseBodyContent: nil,
            trafficCategory: .unknown
        )
        XCTAssertEqual(policy.category(for: log), .others)
    }
}
