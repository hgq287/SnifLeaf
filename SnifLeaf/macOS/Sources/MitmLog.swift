//
//  MitmLog.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import Foundation

struct MitmLog: Identifiable, Decodable, Hashable {
    let id = UUID()
    let type: String
    let method: String
    let url: String
    var headers: [String: String]
    var content: String
    let status_code: Int
    let response_headers: [String: String]
    let response_content: String

    var host: String { URL(string: url)?.host ?? "" }
    var isJSON: Bool {
        response_headers["Content-Type"]?.contains("application/json") == true
    }
}
