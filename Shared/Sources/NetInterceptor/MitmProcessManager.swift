//
//  MitmProcessManager.swift
//  Shared
//
//  Depends only on SnifLeafDomain; log sink injected via LogProcessor.
//

import Foundation
import Combine
import OSLog
import SnifLeafDomain

@MainActor
public final class MitmProcessManager: ObservableObject {
    private let logger = Logger(subsystem: "com.snifleaf.Shared", category: "ProxyEngine")

    @Published public private(set) var isProxyRunning: Bool = false
    @Published public private(set) var latestMitmLog: String = "Idle"

    private var process: Process?
    public let logProcessor: LogProcessor

    private var logEntryBuffer: [LogEntry] = []
    private var flushTask: Task<Void, Never>?

    private let flushInterval: TimeInterval = 1.0
    private let maxBufferCount = 100

    public init(logProcessor: LogProcessor) {
        self.logProcessor = logProcessor
    }

    // MARK: - Lifecycle

    public func startProxy() async throws {
        stopProxy()

        let pipe = Pipe()
        let newTask = Process()

        newTask.executableURL = URL(fileURLWithPath: try resolveMitmdumpPath())

        let scriptURL = Bundle.main.url(forResource: "snifleaf_inspector", withExtension: "py")

        newTask.arguments = [
            "-s", scriptURL?.path ?? "",
            "--mode", "regular",
            "--listen-host", "127.0.0.1",
            "--listen-port", "8080",
            "--set", "block_global=false"
        ]

        newTask.standardOutput = pipe
        newTask.standardError = pipe

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
            for try await line in handle.bytes.lines {
                await self.handleIncomingLine(line)
            }
        }
    }

    private func handleIncomingLine(_ line: String) async {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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
            // Ignore non-JSON output from mitmdump
        }
    }

    private func startFlushTimer() {
        flushTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await flush()
            }
        }
    }

    private func flush() async {
        guard !logEntryBuffer.isEmpty else { return }
        let batch = logEntryBuffer
        logEntryBuffer.removeAll()
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
