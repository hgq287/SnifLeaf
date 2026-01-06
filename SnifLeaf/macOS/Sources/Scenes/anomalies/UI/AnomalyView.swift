//
//  AnomalyView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 26/12/25.
//

import SwiftUI
import SnifLeafCore

struct AnomalyView: View {
    @EnvironmentObject var interactor: AnomaliesInteractor
    
    var body: some View {
        List {
            Section(header: Text("System Status")) {
                HStack {
                    Circle()
                        .fill(interactor.isSystemHealthy ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(interactor.isSystemHealthy ? "Performance Optimal" : "Anomalies Detected")
                        .font(.headline)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Detected Anomalies (\(interactor.anomalies.count))")) {
                if interactor.anomalies.isEmpty {
                    Text("No unusual activity found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(interactor.anomalies) { entry in
                        AnomalyRow(entry: entry)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("SnifLeaf AI")
        .onAppear {
            // Sample test data for demonstration
//            let testData = [
//                LogEntry(id: 1, method: "PUT", path: "/chat", latency: 0.28, requestSize: 129, responseSize: 99, statusCode: 200),
//                LogEntry(id: 2, method: "PUT", path: "/chat", latency: 4500.0, requestSize: 5000, responseSize: 99, statusCode: 500)
//            ]
//            interactor.analyzeEntries(testData)
        }
    }
}

struct AnomalyRow: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.method)
                    .font(.caption).bold()
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                Text(entry.path ?? "/")
                    .font(.system(.subheadline, design: .monospaced))
            }
            
            HStack {
                Label("\(Int(entry.latency))ms", systemImage: "timer")
                Spacer()
                Label("\(entry.requestSize)b", systemImage: "arrow.up.circle")
                Spacer()
                Text("Code: \(entry.statusCode)")
                    .foregroundColor(entry.statusCode >= 400 ? .red : .primary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
