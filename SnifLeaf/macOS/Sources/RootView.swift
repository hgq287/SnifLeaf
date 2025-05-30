//
//  RootView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared

struct RootView: View {
    @StateObject var proxy = ProxyMan()
    @StateObject private var filter = LogFilter()
    @State private var selectedLog: ProxyLog? = nil

    var body: some View {
        NavigationSplitView {
            SidebarFilterView(filter: filter, logs: proxy.logs)
                .frame(minWidth: 220)
        } content: {
            List(filter.apply(to: proxy.logs)) { log in
                NavigationLink(value: log) {
                    ProxyLogRow(log: log)
                }
            }
            .navigationTitle("Logs \(filter.apply(to: proxy.logs).count)")
            .navigationDestination(for: ProxyLog.self) { log in
                MitmLogDetailView(log: log, regex: filter.regex)
            }
        } detail: {
            Text("Chọn log để xem chi tiết")
                .foregroundColor(.secondary)
                .font(.headline)
        }
        .onAppear {
            proxy.startProxy()
        }
    }
}
