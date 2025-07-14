//
//  MitmProcessManager.swift
//  Shared
//
//  Created by Hg Q. on 2/6/25.
//

import Foundation
import SnifLeafCore
import Combine

public class MitmProcessManager: ObservableObject {
    @Published public var logs: [ProxyLog] = []
    public static let shared = MitmProcessManager()

    private var task: Process?
    private var outputBuffer = ""
    private var tempScriptURL: URL?

    public var logProcessor: LogProcessor!

    @Published public var isProxyRunning: Bool = false
    @Published public var latestMitmLog: String = "No mitmproxy output yet."

    // For buffering and batching log entries
    private var logEntryBuffer: [LogEntry] = []
    private let logEntryBufferLock = NSLock()
    private var flushLogEntryTimer: Timer?
    private let flushInterval: TimeInterval = 1.0
    private let maxBufferCount: Int = 100

    private let parsingQueue = DispatchQueue(label: "com.yourapp.mitmParsing", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.yourapp.logProcessing", qos: .userInitiated)


    public init(logProcessor: LogProcessor? = nil) {
        self.logProcessor = logProcessor ?? LogProcessor(dbManager: GRDBManager.shared)
        setupFlushTimer()
    }

    // MARK: - Proxy Management

    public func stopExistingMitmdump(
        timeout: TimeInterval = 1.0,
        completion: @escaping () -> Void
    ) {
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killTask.arguments = ["-9", "mitmdump"] // Force kill to ensure no lingering processes
        try? killTask.run()

        // Wait a bit to ensure the process is terminated
        DispatchQueue.global().async {
            let start = Date()
            while Date().timeIntervalSince(start) < timeout {
                Thread.sleep(forTimeInterval: 0.1)
            }
            completion()
        }
    }

    private func cleanupTempScript() {
        if let url = tempScriptURL {
            do {
                try FileManager.default.removeItem(at: url)
                print("Cleaned up temporary mitmdump script at \(url.path)")
            } catch {
                print("Error cleaning up temporary script: \(error)")
            }
            tempScriptURL = nil
        }
    }

    public func startProxy(
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        stopExistingMitmdump { [self] in
            guard task == nil else {
                print("mitmdump task is already running.")
                completion(false)
                return
            }

            // The mitmproxy Python script to capture and print flow data as JSON
            let script = """
            import json
            import time
            from urllib.parse import urlparse, parse_qs
            from mitmproxy import http
            import sys

            def response(flow: http.HTTPFlow):
                if flow.response: # Only process flows with valid responses.
                    try:
                        parsed_url = urlparse(flow.request.url)
                        host = parsed_url.netloc
                        path = parsed_url.path

                        query_params_dict = parse_qs(parsed_url.query)
                        simplified_query_params = {k: v[0] for k, v in query_params_dict.items()} if query_params_dict else {}
                        query_params_json_str = json.dumps(simplified_query_params, ensure_ascii=False) if simplified_query_params else None

                        request_body_content = None
                        if flow.request.content:
                            try:
                                request_body_content = flow.request.content.decode('utf-8')
                            except UnicodeDecodeError:
                                import base64
                                request_body_content = base64.b64encode(flow.request.content).decode('utf-8')

                        response_body_content = None
                        if flow.response.content:
                            try:
                                response_body_content = flow.response.content.decode('utf-8')
                            except UnicodeDecodeError:
                                import base64
                                response_body_content = base64.b64encode(flow.response.content).decode('utf-8')

                        request_headers_dict = dict(flow.request.headers)
                        request_headers_json_str = json.dumps(request_headers_dict, ensure_ascii=False)

                        response_headers_dict = dict(flow.response.headers)
                        response_headers_json_str = json.dumps(response_headers_dict, ensure_ascii=False)

                        timestamp = int(flow.request.timestamp_start)
                        latency = (flow.response.timestamp_end - flow.request.timestamp_start) if flow.response.timestamp_end and flow.request.timestamp_start else 0.0

                        log_entry = {
                            "id": None,
                            "timestamp": timestamp,
                            "method": flow.request.method,
                            "url": flow.request.url,
                            "host": host,
                            "path": path,
                            "queryParams": query_params_json_str,
                            "requestSize": len(flow.request.content) if flow.request.content else 0,
                            "responseSize": len(flow.response.content) if flow.response.content else 0,
                            "statusCode": flow.response.status_code,
                            "latency": latency,
                            "requestHeaders": request_headers_json_str,
                            "responseHeaders": response_headers_json_str,
                            "requestBodyContent": request_body_content,
                            "responseBodyContent": response_body_content,
                            "trafficCategory": "Unknown"
                        }
                        print(json.dumps(log_entry, ensure_ascii=False), flush=True)
                    except Exception as e:
                        print(f"Error in mitmproxy addon: {e}", file=sys.stderr, flush=True)

            addons = [
                response
            ]
            """

            do {
                let tempDir = FileManager.default.temporaryDirectory
                let scriptURL = tempDir.appendingPathComponent("dump_log_\(UUID().uuidString).py")
                try script.write(to: scriptURL, atomically: true, encoding: .utf8)
                self.tempScriptURL = scriptURL

                let mitmdumpPath: String
                let homebrewMitmPath = "/opt/homebrew/bin/mitmdump" // Standard Homebrew path on Apple Silicon
                let homebrewMitmPathIntel = "/usr/local/bin/mitmdump" // Standard Homebrew path on Intel Macs

                if let mitmproxyAppPath = Bundle.main.path(forResource: "mitmproxy.app", ofType: nil) {
                    mitmdumpPath = mitmproxyAppPath + "/Contents/MacOS/mitmdump"
                    print("Using mitmdump from bundled mitmproxy.app: \(mitmdumpPath)")
                } else if FileManager.default.fileExists(atPath: homebrewMitmPath) {
                    mitmdumpPath = homebrewMitmPath
                    print("Using mitmdump from Homebrew (Apple Silicon): \(mitmdumpPath)")
                } else if FileManager.default.fileExists(atPath: homebrewMitmPathIntel) {
                    mitmdumpPath = homebrewMitmPathIntel
                    print("Using mitmdump from Homebrew (Intel): \(mitmdumpPath)")
                }
                else {
                    throw MitmProcessError.mitmdumpNotFound
                }

                task = Process()
                task?.executableURL = URL(fileURLWithPath: mitmdumpPath)
                task?.arguments = [
                    "-s", scriptURL.path,
                    "--mode", "regular",
                    "--listen-host", "127.0.0.1",
                    "--listen-port", "8080",
                    "--set", "block_global=false"
                ]

                let pipe = Pipe()
                task?.standardOutput = pipe
                task?.standardError = pipe // Redirect standard error to standard output

                // MARK: - Readability Handler (Optimized)
                pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                    guard let self else { return }
                    let data = handle.availableData
                    guard !data.isEmpty else { return }

                    if let newString = String(data: data, encoding: .utf8) {
                        self.outputBuffer.append(newString)
                    } else {
                        // This should ideally not happen if data is valid UTF-8
                        DispatchQueue.main.async {
                            self.latestMitmLog = "MitmProxy Output Error: Could not decode available data as UTF-8."
                        }
                        print(self.latestMitmLog)
                        return
                    }

                    // Process all available lines from the buffer
                    while let newlineRange = self.outputBuffer.range(of: "\n") {
                        let line = String(self.outputBuffer[..<newlineRange.lowerBound])
                        self.outputBuffer.removeSubrange(..<newlineRange.upperBound) // Efficiently remove processed part

                        guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

                        DispatchQueue.main.async {
                            self.latestMitmLog = line
                        }

                        // Dispatch JSON decoding and buffering to the parsingQueue
                        self.parsingQueue.async { [weak self] in
                            guard let self = self else { return }
                            guard let jsonData = line.data(using: .utf8) else {
                                print("MitmProxy Output: Could not convert line to Data: \(line)")
                                return
                            }

                            do {
                                let decoder = JSONDecoder()
                                // Custom date decoding for Unix timestamp
                                decoder.dateDecodingStrategy = .custom { decoder in
                                    let container = try decoder.singleValueContainer()
                                    let timestamp = try container.decode(TimeInterval.self)
                                    return Date(timeIntervalSince1970: timestamp)
                                }

                                var logEntry = try decoder.decode(LogEntry.self, from: jsonData)
                                logEntry.id = nil

                                self.logEntryBufferLock.lock()
                                self.logEntryBuffer.append(logEntry)
                                
                                // If buffer reaches capacity, trigger an immediate flush
                                if self.logEntryBuffer.count >= self.maxBufferCount {
                                    self.logEntryBufferLock.unlock() // Unlock before flushing as flush will re-lock
                                    self.flushLogBuffer()
                                } else {
                                    self.logEntryBufferLock.unlock()
                                }
                            } catch {
                                print("JSON Decode Error: \(error.localizedDescription) for line: \(line)")
                            }
                        }
                    }
                }

                try task?.run()
                
                DispatchQueue.main.async {
                    self.isProxyRunning = true
                    completion(true)
                    print("mitmdump process started successfully!")
                }

                task?.terminationHandler = { [weak self] _ in
                    print("mitmdump process terminated.")
                    DispatchQueue.main.async {
                        self?.isProxyRunning = false
                        self?.cleanupTempScript()
                        self?.flushLogEntryTimer?.invalidate()
                        self?.flushLogEntryTimer = nil
                    }
                }

            } catch {
                print("Proxy start error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isProxyRunning = false
                    self.latestMitmLog = "Proxy start error: \(error.localizedDescription)"
                    completion(false)
                }
                self.cleanupTempScript()
            }
        }
    }

    // MARK: - Log Buffering and Flushing

    private func setupFlushTimer() {
        flushLogEntryTimer?.invalidate()
        flushLogEntryTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushLogBuffer()
        }

        RunLoop.main.add(flushLogEntryTimer!, forMode: .common)
    }

    private func flushLogBuffer() {
        logEntryBufferLock.lock()
        let logsToProcess = logEntryBuffer
        logEntryBuffer.removeAll()
        logEntryBufferLock.unlock()

        guard !logsToProcess.isEmpty else { return }

        // Process logs in a batch on the processingQueue 
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            logProcessor.processBatchNewLogs(logsToProcess)
        }
    }

    // MARK: - Error Handling

    enum MitmProcessError: LocalizedError {
        case mitmdumpNotFound
        case scriptWriteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .mitmdumpNotFound:
                return "mitmdump executable not found. Please ensure mitmproxy is installed via Homebrew or bundled correctly. Checked paths: /opt/homebrew/bin/mitmdump, /usr/local/bin/mitmdump, and bundled mitmproxy.app."
            case .scriptWriteFailed(let error):
                return "Failed to write mitmproxy script: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Deinitialization

    deinit {
        task?.terminate(); task = nil
        flushLogEntryTimer?.invalidate()
        if let url = tempScriptURL { try? FileManager.default.removeItem(at: url) }
        print("MitmProcessManager deinitialized.")
    }
}
  
