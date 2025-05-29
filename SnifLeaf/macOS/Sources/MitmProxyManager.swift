//
//  MitmProxyManager.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import Foundation

class MitmProxyManager: ObservableObject {
    @Published var logs: [MitmLog] = []
    private var task: Process?
    private var tempScriptURL: URL?

    func startProxy() {
        do {
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

            let tempDir = FileManager.default.temporaryDirectory
            let scriptURL = tempDir.appendingPathComponent("dump_log.py")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            self.tempScriptURL = scriptURL

            let pipe = Pipe()
            let mitmPath = "/opt/homebrew/bin/mitmdump" // chỉnh lại nếu khác

            task = Process()
            task?.executableURL = URL(fileURLWithPath: mitmPath)
            task?.arguments = ["-s", scriptURL.path, "--listen-port", "8080"]
            task?.standardOutput = pipe
            task?.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let jsonData = line.data(using: .utf8) else {
                    return
                }

                do {
                    let log = try JSONDecoder().decode(MitmLog.self, from: jsonData)
                    DispatchQueue.main.async {
                        self.logs.insert(log, at: 0)
                    }
                } catch {
                    print("Parse error:", error)
                }
            }

            try task?.run()
        } catch {
            print("Failed to start proxy:", error)
        }
    }

    func stopProxy() {
        task?.terminate()
        task = nil

        if let scriptURL = tempScriptURL {
            try? FileManager.default.removeItem(at: scriptURL)
        }
    }
}
