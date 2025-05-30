//
//  ProxyMan.swift
//  Shared
//
//  Created by Hg Q. on 30/5/25.
//

import Foundation
import UniformTypeIdentifiers

public class ProxyMan: ObservableObject {
    @Published public var logs: [ProxyLog] = []
    private var task: Process?
    private var tempScriptURL: URL?
    
    public init () {
        
    }

    public func startProxy() {
        guard task == nil else { return }
        let script = """
        import json
        def response(flow):
            data = {
                "type": "http",
                "method": flow.request.method,
                "url": flow.request.pretty_url,
                "headers": dict(flow.request.headers),
                "content": flow.request.get_text(),
                "status_code": flow.response.status_code,
                "response_headers": dict(flow.response.headers),
                "response_content": flow.response.get_text(),
            }
            print(json.dumps(data), flush=True)
        """
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let scriptURL = tempDir.appendingPathComponent("dump_log.py")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            tempScriptURL = scriptURL

            let pipe = Pipe()
            let mitmPath = "/opt/homebrew/bin/mitmdump" // update path if different
            task = Process()
            task?.executableURL = URL(fileURLWithPath: mitmPath)
            task?.arguments = ["-s", scriptURL.path, "--listen-port", "8080"]
            task?.standardOutput = pipe
            task?.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard let self, !data.isEmpty,
                      let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let jsonData = str.data(using: .utf8) else { return }
                 
                if let log = try? JSONDecoder().decode(ProxyLog.self, from: jsonData) {
                    DispatchQueue.main.async { self.logs.insert(log, at: 0) }
                }
            }
            try task?.run()
        } catch {
            print("Proxy start error", error)
        }
    }
    
    
    public func exportLogAsHAR(_ log: ProxyLog) -> String {
        let har = [
            "log": [
                "version": "1.2",
                "creator": ["name": "MitmSwiftUIApp", "version": "1.0"],
                "entries": [[
                    "request": [
                        "method": log.method,
                        "url": log.url,
                        "headers": log.headers.map { ["name": $0.key, "value": $0.value] },
                        "postData": ["text": log.content],
                    ],
                    "response": [
                        "status": log.status_code,
                        "headers": log.response_headers.map { ["name": $0.key, "value": $0.value] },
                        "content": ["text": log.response_content],
                    ]
                ]]
            ]
        ]
        if let data = try? JSONSerialization.data(withJSONObject: har, options: .prettyPrinted),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

    public func replay(log: ProxyLog) {
        guard let url = URL(string: log.url) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = log.method
        log.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if !log.content.isEmpty {
            request.httpBody = log.content.data(using: .utf8)
        }
        URLSession.shared.dataTask(with: request).resume()
    }

    public func exportToFile(_ log: ProxyLog) {
//        let panel = NSSavePanel()
//        panel.title = "Export HAR Log"
//        panel.allowedContentTypes = [UTType.json]
//        panel.nameFieldStringValue = "request.har.json"
//
//        if panel.runModal() == .OK, let url = panel.url {
//            let data = exportLogAsHAR(log).data(using: .utf8)
//            try? data?.write(to: url)
//        }
    }

    deinit {
        task?.terminate(); task = nil
        if let url = tempScriptURL { try? FileManager.default.removeItem(at: url) }
    }
}
