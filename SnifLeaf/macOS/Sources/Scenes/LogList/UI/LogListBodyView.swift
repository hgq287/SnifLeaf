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
            if logListInteractor.logs.isEmpty && logListInteractor.searchText.isEmpty {
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
                ScrollViewReader { proxy in
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
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .id(log.id)
                        }

                        if logListInteractor.hasMoreLogs {
                            ProgressView("Loading next page...")
                                .onAppear {
                                    logListInteractor.loadNextPage()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.bottom, 24)
                        } else if !logListInteractor.isLoading && !logListInteractor.logs.isEmpty {
                            Text("End of Logs")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .listStyle(.plain)
                    .animation(.interpolatingSpring(stiffness: 250, damping: 25), value: logListInteractor.logs)
                    .onChange(of: logListInteractor.logs.first?.id) { firstID in
                        guard let firstID = firstID else { return }
                        withAnimation {
                            proxy.scrollTo(firstID, anchor: .top)
                        }
                    }
                }
            }
        }
    }
}


