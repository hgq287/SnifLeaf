//
//  LogListBodyView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 27/6/25.
//

import SwiftUI
import SnifLeafCore

struct LogListBodyView: View {
    @ObservedObject var logListInteractor: LogListInteractor
    @Binding var selectedLog: LogEntry?

    var body: some View {
        Group {
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
                            }
                            .background(
                                selectedLog?.id == log.id ?
                                    Color.accentColor.opacity(0.1) :
                                    Color.clear
                            )
                            .cornerRadius(5)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                    }

                    if logListInteractor.hasMoreLogs {
                        ProgressView()
                            .onAppear {
                                print("Loading next page...")
                                logListInteractor.loadNextPage()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !logListInteractor.isLoading && !logListInteractor.logs.isEmpty {
                        Text("End of Logs")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
