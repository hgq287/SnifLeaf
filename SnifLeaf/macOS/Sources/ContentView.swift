//
//  ContentView.swift
//  SnifLeaf
//
//  Created by Hg Q. on 20/4/25.
//

import SwiftUI
import Shared

class PacketLogger: ObservableObject {
    @Published var logs: [String] = []

    private var task: Process?
    private var pipe: Pipe?

    func startMITMProxy() {
        let pipe = Pipe()
        self.pipe = pipe

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["mitmproxy", "--mode", "regular", "--set", "console_eventlog_verbosity=debug"]
        task.standardOutput = pipe
        task.standardError = pipe

        let handle = pipe.fileHandleForReading

        handle.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                DispatchQueue.main.async {
                    self?.logs.insert(line.trimmingCharacters(in: .whitespacesAndNewlines), at: 0)
                }
            }
        }

        self.task = task
        task.launch()
    }

    func stopMITMProxy() {
        task?.terminate()
        pipe?.fileHandleForReading.readabilityHandler = nil
    }
}

struct ContentView: View {
    @StateObject var logger = PacketLogger()
    var body: some View {
        VStack(alignment: .leading) {
            Text("HTTP/HTTPS Traffic Log")
                .font(.headline)
                .padding()
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            logger.startMITMProxy()
        }
        .onDisappear {
            logger.stopMITMProxy()
        }
    }
}

#Preview {
    ContentView()
}
