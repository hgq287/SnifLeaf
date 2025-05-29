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
                if let log = try? JSONDecoder().decode(MitmLog.self, from: jsonData) {
                    DispatchQueue.main.async { self.logs.insert(log, at: 0) }
                }
            }
            try task?.run()
        } catch {
            print("Proxy start error", error)
        }
    }

    deinit {
        task?.terminate(); task = nil
        if let url = tempScriptURL { try? FileManager.default.removeItem(at: url) }
    }
}
