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
    let headers: [String: String]
    let content: String
    let status_code: Int
    let response_headers: [String: String]
    let response_content: String

    var host: String { URL(string: url)?.host ?? "" }
}
