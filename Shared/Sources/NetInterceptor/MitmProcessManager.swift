import Foundation
import Combine
import SnifLeafCore

public final class MitmProcessManager: ObservableObject {
    public static let shared = MitmProcessManager()

    @Published public private(set) var logs: [ProxyLog] = []
    @Published public private(set) var isProxyRunning: Bool = false
    @Published public private(set) var latestMitmLog: String = "No mitmproxy output yet."

    private var task: Process?
    private var outputBuffer = ""
    private var tempScriptURL: URL?
    public var logProcessor: LogProcessor

    private var logEntryBuffer: [LogEntry] = []
    private let logEntryBufferLock = NSLock()
    private var flushLogEntryTimer: DispatchSourceTimer?
    private let flushInterval: TimeInterval = 1.0
    private let maxBufferCount = 100

    private let parsingQueue = DispatchQueue(label: "com.snifleaf.parsing", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.snifleaf.processing", qos: .userInitiated)
    
//    private let mitmPythonScript = """
//    import json
//    import time
//    from urllib.parse import urlparse, parse_qs
//    from mitmproxy import http
//    import sys
//
//    def response(flow: http.HTTPFlow):
//        if flow.response:
//            try:
//                parsed_url = urlparse(flow.request.url)
//                host = parsed_url.netloc
//                path = parsed_url.path
//
//                query_params_dict = parse_qs(parsed_url.query)
//                simplified_query_params = {k: v[0] for k, v in query_params_dict.items()} if query_params_dict else {}
//                query_params_json_str = json.dumps(simplified_query_params, ensure_ascii=False) if simplified_query_params else None
//
//                request_body_content = None
//                if flow.request.content:
//                    try:
//                        request_body_content = flow.request.content.decode('utf-8')
//                    except UnicodeDecodeError:
//                        import base64
//                        request_body_content = base64.b64encode(flow.request.content).decode('utf-8')
//
//                response_body_content = None
//                if flow.response.content:
//                    try:
//                        response_body_content = flow.response.content.decode('utf-8')
//                    except UnicodeDecodeError:
//                        import base64
//                        response_body_content = base64.b64encode(flow.response.content).decode('utf-8')
//
//                request_headers_dict = dict(flow.request.headers)
//                request_headers_json_str = json.dumps(request_headers_dict, ensure_ascii=False)
//
//                response_headers_dict = dict(flow.response.headers)
//                response_headers_json_str = json.dumps(response_headers_dict, ensure_ascii=False)
//
//                timestamp = int(flow.request.timestamp_start)
//                latency = (flow.response.timestamp_end - flow.request.timestamp_start) if flow.response.timestamp_end and flow.request.timestamp_start else 0.0
//
//                log_entry = {
//                    "id": None,
//                    "timestamp": timestamp,
//                    "method": flow.request.method,
//                    "url": flow.request.url,
//                    "host": host,
//                    "path": path,
//                    "queryParams": query_params_json_str,
//                    "requestSize": len(flow.request.content) if flow.request.content else 0,
//                    "responseSize": len(flow.response.content) if flow.response.content else 0,
//                    "statusCode": flow.response.status_code,
//                    "latency": latency,
//                    "requestHeaders": request_headers_json_str,
//                    "responseHeaders": response_headers_json_str,
//                    "requestBodyContent": request_body_content,
//                    "responseBodyContent": response_body_content,
//                    "trafficCategory": "Unknown"
//                }
//                print(json.dumps(log_entry, ensure_ascii=False), flush=True)
//            except Exception as e:
//                print(f"Error in mitmproxy addon: {e}", file=sys.stderr, flush=True)
//
//    addons = [
//        response
//    ]
//    """

    private let mitmPythonScript = """
    import json
    import time
    from urllib.parse import urlparse, parse_qs
    from mitmproxy import http
    import sys

    def response(flow: http.HTTPFlow):
        if flow.response:
            try:
                # 1. Lọc các request không cần thiết
                #    Bỏ qua các request đến tài nguyên tĩnh (hình ảnh, font, css, js)
                #    để giảm đáng kể khối lượng dữ liệu
                content_type = flow.response.headers.get("Content-Type", "")
                if "image" in content_type or "font" in content_type or "javascript" in content_type or "css" in content_type:
                    return # Bỏ qua xử lý và không in log

                # 2. Xử lý logic tạo JSON
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
                    "responseBodyContent": "",
                    "trafficCategory": "Unknown"
                }
                
                # 3. In ra JSON cho các request đã lọc
                print(json.dumps(log_entry, ensure_ascii=False), flush=True)
            except Exception as e:
                print(f"Error in mitmproxy addon: {e}", file=sys.stderr, flush=True)

    addons = [
        response
    ]
    """
    public init(logProcessor: LogProcessor = LogProcessor(dbManager: GRDBManager.shared)) {
        self.logProcessor = logProcessor
        setupFlushTimer()
    }

    // MARK: - Proxy Management

    public func stopExistingMitmdump(timeout: TimeInterval = 1.0, completion: @escaping () -> Void) {
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killTask.arguments = ["-9", "mitmdump"]
        try? killTask.run()

        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            completion()
        }
    }

    public func startProxy(completion: @escaping (Bool) -> Void = { _ in }) {
        stopExistingMitmdump { [weak self] in
            guard let self else { return }

            guard task == nil else {
                print("mitmdump already running.")
                completion(false)
                return
            }

            do {
                let scriptURL = try self.writeMitmScriptToTemp()
                self.tempScriptURL = scriptURL

                let mitmdumpPath = try self.resolveMitmdumpPath()

                let pipe = Pipe()
                let newTask = Process()
                newTask.executableURL = URL(fileURLWithPath: mitmdumpPath)
                newTask.arguments = [
                    "-s", scriptURL.path,
                    "--mode", "regular",
                    "--listen-host", "127.0.0.1",
                    "--listen-port", "8080",
                    "--set", "block_global=false"
                ]
                newTask.standardOutput = pipe
                newTask.standardError = pipe

                pipe.fileHandleForReading.readabilityHandler = self.makeReadabilityHandler()
                newTask.terminationHandler = self.makeTerminationHandler()

                try newTask.run()
                self.task = newTask

                DispatchQueue.main.async {
                    self.isProxyRunning = true
                    completion(true)
                    print("mitmdump started.")
                }
            } catch {
                self.cleanupTempScript()
                DispatchQueue.main.async {
                    self.isProxyRunning = false
                    self.latestMitmLog = "Proxy start error: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }

    private func resolveMitmdumpPath() throws -> String {
        if let bundlePath = Bundle.main.path(forResource: "mitmproxy.app", ofType: nil) {
            return bundlePath + "/Contents/MacOS/mitmdump"
        }

        let paths = ["/opt/homebrew/bin/mitmdump", "/usr/local/bin/mitmdump"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        throw MitmProcessError.mitmdumpNotFound
    }

    private func writeMitmScriptToTemp() throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dump_log_\(UUID().uuidString).py")
        try mitmPythonScript.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    private func cleanupTempScript() {
        if let url = tempScriptURL {
            try? FileManager.default.removeItem(at: url)
            tempScriptURL = nil
        }
    }

    // MARK: - Output Handling

    private func makeReadabilityHandler() -> (FileHandle) -> Void {
        return { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            guard !data.isEmpty else { return }

            guard let newString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.latestMitmLog = "MitmProxy output decode error."
                }
                return
            }

            self.outputBuffer.append(newString)
            
            while let newlineRange = self.outputBuffer.range(of: "\n") {
                let line = String(self.outputBuffer[..<newlineRange.lowerBound])
                self.outputBuffer.removeSubrange(..<newlineRange.upperBound)

                guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("Empty line received, skipping.")
                    continue
                }
                DispatchQueue.main.async { self.latestMitmLog = line }

                self.parsingQueue.async {
                    self.parseLogLine(line)
                }
            }
        }
    }

    private func parseLogLine(_ line: String) {
        guard let data = line.data(using: .utf8) else {
            print("Invalid UTF-8 line: \(line)")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(TimeInterval.self)
            return Date(timeIntervalSince1970: timestamp)
        }

        do {
            var logEntry = try decoder.decode(LogEntry.self, from: data)
            logEntry.id = nil

            logEntryBufferLock.lock()
            logEntryBuffer.append(logEntry)

            if logEntryBuffer.count >= maxBufferCount {
                logEntryBufferLock.unlock()
                flushLogBuffer()
            } else {
                logEntryBufferLock.unlock()
            }
        } catch {
//            if let decodingError = error as? DecodingError {
//                print("DecodingError: \(decodingError)")
//            } else {
//                print("JSON Decode Error: \(error.localizedDescription)")
//            }
        }
    }

    private func makeTerminationHandler() -> (Process) -> Void {
        return { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isProxyRunning = false
                self.cleanupTempScript()
                self.flushLogEntryTimer?.cancel()
                self.flushLogEntryTimer = nil
                self.task = nil
                print("mitmdump terminated.")
            }
        }
    }

    // MARK: - Log Flushing

    private func setupFlushTimer() {
        let timer = DispatchSource.makeTimerSource(queue: processingQueue)
        timer.schedule(deadline: .now() + flushInterval, repeating: flushInterval)
        timer.setEventHandler { [weak self] in
            self?.flushLogBuffer()
        }
        timer.resume()
        flushLogEntryTimer = timer
    }

    private func flushLogBuffer() {
        logEntryBufferLock.lock()
        let logsToFlush = logEntryBuffer
        logEntryBuffer.removeAll()
        logEntryBufferLock.unlock()

        guard !logsToFlush.isEmpty else { return }

        processingQueue.async { [weak self] in
            self?.logProcessor.processBatchNewLogs(logsToFlush)
        }
    }

    // MARK: - Deinit

    deinit {
        task?.terminate()
        task = nil
        flushLogEntryTimer?.cancel()
        cleanupTempScript()
        print("MitmProcessManager deinit.")
    }

    // MARK: - Errors

    enum MitmProcessError: LocalizedError {
        case mitmdumpNotFound
        case scriptWriteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .mitmdumpNotFound:
                return "Could not find mitmdump in standard locations or bundle."
            case .scriptWriteFailed(let err):
                return "Failed to write mitmdump script: \(err.localizedDescription)"
            }
        }
    }
}
