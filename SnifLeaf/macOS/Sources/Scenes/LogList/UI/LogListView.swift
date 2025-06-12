//
//  LogListView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared
import SnifLeafCore

struct LogListView: View {
    @EnvironmentObject var logListInteractor: LogListInteractor

    @State private var selectedLog: LogEntry?
    @State private var showingDetailSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search logs...", text: $logListInteractor.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Spacer()
                
                Button("Clear All Logs") {
                    logListInteractor.deleteAllLogs()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            Divider()

            if logListInteractor.isLoading {
                ProgressView("Loading Logs...")
                    .padding()
            } else if logListInteractor.logs.isEmpty && logListInteractor.searchText.isEmpty {
                ContentUnavailableView(
                    "No Logs Captured",
                    systemImage: "network.slash",
                    description: Text("Start the proxy to begin capturing network traffic.")
                )
            } else if logListInteractor.logs.isEmpty && !logListInteractor.searchText.isEmpty {
                 ContentUnavailableView(
                    "No Matching Logs",
                    systemImage: "magnifyingglass",
                    description: Text("No logs found for your search query.")
                )
            } else {
                List {
                    ForEach(logListInteractor.logs) { log in
                        LogRowFancyView(log: log)
                            .onTapGesture {
                                selectedLog = log
                                showingDetailSheet = true
                            }
                            .background(selectedLog?.id == log.id ? Color.accentColor.opacity(0.1) : Color.clear)
                            .cornerRadius(5)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let log = selectedLog {
//                LogDetailView(log: log)
//                    .frame(minWidth: 600, minHeight: 700)
            }
        }
        .navigationTitle("Live Network Logs")
        .onAppear {
            logListInteractor.loadLogs()
        }
    }
}

// MARK: - Preview Provider
struct LogListView_Previews: PreviewProvider {
    static var previews: some View {
        LogListView()
            .environmentObject(LogListInteractor(dbManager: GRDBManager.shared))
            .previewDisplayName("Log List View - No GRDBQuery")
    }
}
