//
//  LogFilter.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 30/5/25.
//

import Foundation
import Shared

class LogFilter: ObservableObject {
    @Published var host: String = ""
    @Published var method: String = ""
    @Published var status: String = ""
    @Published var regexText: String = "" { didSet { compileRegex() } }
    @Published var isRegexValid: Bool = true
    private(set) var regex: NSRegularExpression?

    private func compileRegex() {
        guard !regexText.isEmpty else { regex = nil; isRegexValid = true; return }
        do {
            regex = try NSRegularExpression(pattern: regexText, options: .caseInsensitive)
            isRegexValid = true
        } catch {
            regex = nil
            isRegexValid = false
        }
    }

    func apply(to logs: [ProxyLog]) -> [ProxyLog] {
        logs.filter { log in
            (host.isEmpty || log.host.contains(host)) &&
            (method.isEmpty || log.method.localizedCaseInsensitiveContains(method)) &&
            (status.isEmpty || String(log.status_code).contains(status)) &&
            matchesRegex(in: log)
        }
    }

    private func matchesRegex(in log: ProxyLog) -> Bool {
        guard let regex else { return true }
        let haystack = "\(log.method) \(log.url) \(log.content) \(log.response_content)"
        let range = NSRange(haystack.startIndex..., in: haystack)
        return regex.firstMatch(in: haystack, options: [], range: range) != nil
    }
}

