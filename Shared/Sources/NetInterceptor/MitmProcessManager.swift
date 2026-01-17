import Foundation
import Combine
import OSLog
import SnifLeafCore

@MainActor
public final class MitmProcessManager: ObservableObject {
    public static let shared = MitmProcessManager()
    private let logger = Logger(subsystem: "com.snifleaf.Shared", category: "ProxyEngine")
    
    @Published public private(set) var isProxyRunning: Bool = false
    @Published public private(set) var latestMitmLog: String = "Idle"
    
    private var process: Process?
    public var logProcessor: LogProcessor
    
    // Concurrency: Thread-safe buffer for batching
    private var logEntryBuffer: [LogEntry] = []
    private var flushTask: Task<Void, Never>?
    
    private let flushInterval: TimeInterval = 1.0
    private let maxBufferCount = 100

    public init(logProcessor: LogProcessor = LogProcessor(dbManager: GRDBManager.shared)) {
        self.logProcessor = logProcessor
    }
    
    // MARK: - Lifecycle

    public func startProxy() async throws {
        stopProxy()

        let pipe = Pipe()
        let newTask = Process()
        
        newTask.executableURL = URL(fileURLWithPath: try resolveMitmdumpPath())
        
        // Lead Tip: Use Bundled Python Script for environment consistency
        let scriptURL = Bundle.main.url(forResource: "snifleaf_inspector", withExtension: "py")
        
//        newTask.arguments = [
//            "-s", scriptURL?.path ?? "",
//            "--listen-port", "8080",
//            "--set", "termlog_verbosity=error"
//        ]
//        
        newTask.arguments = [
            "-s", scriptURL?.path ?? "",
            "--mode", "regular",
            "--listen-host", "127.0.0.1",
            "--listen-port", "8080",
            "--set", "block_global=false"
        ]

        
        newTask.standardOutput = pipe
        newTask.standardError = pipe

        // 2. Modern Ingestion: Stream bytes asynchronously
        listenToStream(pipe)
        
        newTask.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.isProxyRunning = false
                self?.flushTask?.cancel()
            }
        }

        try newTask.run()
        self.process = newTask
        self.isProxyRunning = true
        
        startFlushTimer()
        logger.info("Proxy Engine started.")
    }

    public func stopProxy() {
        process?.terminate()
        process = nil
        isProxyRunning = false
        flushTask?.cancel()
    }
    
    // MARK: - Ingestion Pipeline

    private func listenToStream(_ pipe: Pipe) {
        let handle = pipe.fileHandleForReading
        Task(priority: .userInitiated) {
            // Zero-copy line reading from the process pipe
            for try await line in handle.bytes.lines {
                await self.handleIncomingLine(line)
            }
        }
    }

    private func handleIncomingLine(_ line: String) async {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Update UI Status
        self.latestMitmLog = String(trimmed.prefix(100))

        guard let data = trimmed.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let entry = try decoder.decode(LogEntry.self, from: data)
            
            logEntryBuffer.append(entry)
            
            if logEntryBuffer.count >= maxBufferCount {
                await flush()
            }
        } catch {
            // Ignore non-JSON output noise from mitmdump
        }
    }

    private func startFlushTimer() {
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await flush()
            }
        }
    }

    private func flush() async {
        guard !logEntryBuffer.isEmpty else { return }
        let batch = logEntryBuffer
        logEntryBuffer.removeAll()
        
        // Offload DB I/O to background via LogProcessor
        Task.detached(priority: .background) {
            await self.logProcessor.processBatchNewLogs(batch)
        }
    }

    private func resolveMitmdumpPath() throws -> String {
        if let bundlePath = Bundle.main.path(forResource: "mitmproxy.app", ofType: nil) {
            return bundlePath + "/Contents/MacOS/mitmdump"
        }
        throw NSError(domain: "SnifLeaf", code: 404, userInfo: [NSLocalizedDescriptionKey: "mitmdump missing"])
    }
}
