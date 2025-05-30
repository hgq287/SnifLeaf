//
//  ProxyLog.swift
//  Shared
//
//  Created by Hung Q. on 30/5/25.
//

import Foundation

public struct ProxyLog: Identifiable, Decodable, Hashable {
    public var id = UUID()
    public let type: String
    public let method: String
    public let url: String
    public var headers: [String: String]
    public var content: String
    public let status_code: Int
    public let response_headers: [String: String]
    public let response_content: String

    public var host: String { URL(string: url)?.host ?? "" }
    public var isJSON: Bool {
        response_headers["Content-Type"]?.contains("application/json") == true
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case method
        case url
        case headers
        case content
        case status_code
        case response_headers
        case response_content
    }
}
