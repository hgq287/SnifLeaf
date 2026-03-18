//
//  LogEntry.swift
//  SnifLeafDomain
//
//  Domain entity – framework-agnostic; no GRDB or persistence coupling.
//

import Foundation

public struct LogEntry: Equatable, Identifiable, Codable {
    public var id: Int64?
    public let timestamp: Date
    public let method: String
    public let url: String
    public let host: String?
    public let path: String?
    public let queryParams: String?
    public let requestSize: Int
    public let responseSize: Int
    public let statusCode: Int
    public let latency: Double
    public let requestHeaders: String?
    public let responseHeaders: String?
    public let requestBodyContent: Data?
    public let responseBodyContent: Data?
    public var trafficCategory: TrafficCategory

    public init(
        id: Int64? = nil,
        timestamp: Date,
        method: String,
        url: String,
        host: String?,
        path: String?,
        queryParams: String?,
        requestSize: Int,
        responseSize: Int,
        statusCode: Int,
        latency: Double,
        requestHeaders: String?,
        responseHeaders: String?,
        requestBodyContent: Data?,
        responseBodyContent: Data?,
        trafficCategory: TrafficCategory
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.url = url
        self.host = host
        self.path = path
        self.queryParams = queryParams
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.statusCode = statusCode
        self.latency = latency
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
        self.requestBodyContent = requestBodyContent
        self.responseBodyContent = responseBodyContent
        self.trafficCategory = trafficCategory
    }

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, method, url, host, path, queryParams, requestSize, responseSize, statusCode, latency
        case requestHeaders, responseHeaders, requestBodyContent, responseBodyContent, trafficCategory
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        method = try container.decode(String.self, forKey: .method)
        url = try container.decode(String.self, forKey: .url)
        host = try container.decodeIfPresent(String.self, forKey: .host)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        queryParams = try container.decodeIfPresent(String.self, forKey: .queryParams)
        requestSize = try container.decode(Int.self, forKey: .requestSize)
        responseSize = try container.decode(Int.self, forKey: .responseSize)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        latency = try container.decode(Double.self, forKey: .latency)
        requestHeaders = try container.decodeIfPresent(String.self, forKey: .requestHeaders)
        responseHeaders = try container.decodeIfPresent(String.self, forKey: .responseHeaders)

        if let bodyString = try container.decodeIfPresent(String.self, forKey: .requestBodyContent) {
            requestBodyContent = Data(base64Encoded: bodyString) ?? bodyString.data(using: .utf8)
        } else {
            requestBodyContent = nil
        }
        if let bodyString = try container.decodeIfPresent(String.self, forKey: .responseBodyContent) {
            responseBodyContent = Data(base64Encoded: bodyString) ?? bodyString.data(using: .utf8)
        } else {
            responseBodyContent = nil
        }
        let categoryString = try container.decodeIfPresent(String.self, forKey: .trafficCategory) ?? TrafficCategory.unknown.rawValue
        trafficCategory = TrafficCategory.fromString(categoryString)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(method, forKey: .method)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(host, forKey: .host)
        try container.encodeIfPresent(path, forKey: .path)
        try container.encodeIfPresent(queryParams, forKey: .queryParams)
        try container.encode(requestSize, forKey: .requestSize)
        try container.encode(responseSize, forKey: .responseSize)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(latency, forKey: .latency)
        try container.encodeIfPresent(requestHeaders, forKey: .requestHeaders)
        try container.encodeIfPresent(responseHeaders, forKey: .responseHeaders)
        try container.encodeIfPresent(requestBodyContent?.base64EncodedString(), forKey: .requestBodyContent)
        try container.encodeIfPresent(responseBodyContent?.base64EncodedString(), forKey: .responseBodyContent)
        try container.encode(trafficCategory.rawValue, forKey: .trafficCategory)
    }
}
