//
//  SnifLeafDomainTests.swift
//  SnifLeafDomainTests
//

import XCTest
import SnifLeafDomain

final class SnifLeafDomainTests: XCTestCase {

    func testTrafficCategoryFromString() {
        XCTAssertEqual(TrafficCategory.fromString("Unknown"), .unknown)
        XCTAssertEqual(TrafficCategory.fromString("Others"), .others)
        XCTAssertEqual(TrafficCategory.fromString("Video Streaming"), .videoStreaming)
        XCTAssertEqual(TrafficCategory.fromString("invalid"), .unknown)
    }

    func testBenchmarkMetricsInit() {
        let m = BenchmarkMetrics(
            dimension: "test",
            requestCount: 10,
            avgLatency: 1.5,
            p95Latency: 2.0,
            errorRate: 0.1
        )
        XCTAssertEqual(m.dimension, "test")
        XCTAssertEqual(m.requestCount, 10)
        XCTAssertEqual(m.avgLatency, 1.5)
        XCTAssertEqual(m.errorRate, 0.1)
    }

    func testLogEntryEquatable() {
        let date = Date()
        let a = LogEntry(
            id: 1,
            timestamp: date,
            method: "GET",
            url: "https://example.com",
            host: "example.com",
            path: "/",
            queryParams: nil,
            requestSize: 0,
            responseSize: 100,
            statusCode: 200,
            latency: 0.5,
            requestHeaders: nil,
            responseHeaders: nil,
            requestBodyContent: nil,
            responseBodyContent: nil,
            trafficCategory: .others
        )
        let b = LogEntry(
            id: 1,
            timestamp: date,
            method: "GET",
            url: "https://example.com",
            host: "example.com",
            path: "/",
            queryParams: nil,
            requestSize: 0,
            responseSize: 100,
            statusCode: 200,
            latency: 0.5,
            requestHeaders: nil,
            responseHeaders: nil,
            requestBodyContent: nil,
            responseBodyContent: nil,
            trafficCategory: .others
        )
        XCTAssertEqual(a, b)
    }
}
