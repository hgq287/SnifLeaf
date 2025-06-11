//
//  LogEntry.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 3/6/25.
//

import Foundation
import GRDB

public struct LogEntry: Codable, Identifiable {
    public var id: Int?
    public let timestamp: Date
    public let method: String
    public let url: String
    public let host: String
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

    public init(id: Int? = nil, timestamp: Date, method: String, url: String, host: String, path: String?, queryParams: String?, requestSize: Int, responseSize: Int, statusCode: Int, latency: Double, requestHeaders: String?, responseHeaders: String?, requestBodyContent: Data?, responseBodyContent: Data?) {
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
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, method, url, host, path, queryParams, requestSize, responseSize, statusCode, latency
        case requestHeaders
        case responseHeaders
        case requestBodyContent
        case responseBodyContent
    }

    // MARK: - Init from Decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        method = try container.decode(String.self, forKey: .method)
        url = try container.decode(String.self, forKey: .url)
        host = try container.decode(String.self, forKey: .host)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        queryParams = try container.decodeIfPresent(String.self, forKey: .queryParams)
        requestSize = try container.decode(Int.self, forKey: .requestSize)
        responseSize = try container.decode(Int.self, forKey: .responseSize)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        latency = try container.decode(Double.self, forKey: .latency)
        requestHeaders = try container.decodeIfPresent(String.self, forKey: .requestHeaders)
        responseHeaders = try container.decodeIfPresent(String.self, forKey: .responseHeaders)

        if let bodyString = try container.decodeIfPresent(String.self, forKey: .requestBodyContent) {
            if let data = Data(base64Encoded: bodyString) {
                requestBodyContent = data
            } else {
                requestBodyContent = bodyString.data(using: .utf8)
            }
        } else {
            requestBodyContent = nil
        }
        
        if let bodyString = try container.decodeIfPresent(String.self, forKey: .responseBodyContent) {
            if let data = Data(base64Encoded: bodyString) {
                responseBodyContent = data
            } else {
                responseBodyContent = bodyString.data(using: .utf8)
            }
        } else {
            responseBodyContent = nil
        }
    }
}

// MARK: - GRDB Protocols

extension LogEntry: FetchableRecord, PersistableRecord {

    public static var databaseTableName: String { "log_entries" }

    public enum Columns {
        static let id = Column("id")
        static let timestamp = Column("timestamp")
        static let method = Column("method")
        static let url = Column("url")
        static let host = Column("host")
        static let path = Column("path")
        static let queryParams = Column("queryParams")
        static let requestSize = Column("requestSize")
        static let responseSize = Column("responseSize")
        static let statusCode = Column("statusCode")
        static let latency = Column("latency")
        static let requestHeaders = Column("request_headers")
        static let responseHeaders = Column("response_headers")
        static let requestBodyContent = Column("request_body_content")
        static let responseBodyContent = Column("response_body_content")
    }
    
    // MARK: - init
    public init(row: Row) throws {
        id = row[Columns.id]
        timestamp = row[Columns.timestamp]
        method = row[Columns.method]
        url = row[Columns.url]
        host = row[Columns.host]
        path = row[Columns.path]
        queryParams = row[Columns.queryParams]
        requestSize = row[Columns.requestSize]
        responseSize = row[Columns.responseSize]
        statusCode = row[Columns.statusCode]
        latency = row[Columns.latency]
        requestHeaders = row[Columns.requestHeaders]
        responseHeaders = row[Columns.responseHeaders]
        requestBodyContent = row[Columns.requestBodyContent]
        responseBodyContent = row[Columns.responseBodyContent]
    }

    // MARK: - encode
    public func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.timestamp] = timestamp
        container[Columns.method] = method
        container[Columns.url] = url
        container[Columns.host] = host
        container[Columns.path] = path
        container[Columns.queryParams] = queryParams
        container[Columns.requestSize] = requestSize
        container[Columns.responseSize] = responseSize
        container[Columns.statusCode] = statusCode
        container[Columns.latency] = latency
        container[Columns.requestHeaders] = requestHeaders
        container[Columns.responseHeaders] = responseHeaders
        container[Columns.requestBodyContent] = requestBodyContent
        container[Columns.responseBodyContent] = responseBodyContent
    }
}
