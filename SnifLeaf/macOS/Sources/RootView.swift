//
//  RootView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared
import SnifLeafCore

struct RootView: View {
    @StateObject private var filter = LogFilter()
    @State private var selectedLog: ProxyLog? = nil
    
    private let dbManager: GRDBManager
    private let logProcessor: LogProcessor
    @StateObject private var proxyManager: MitmProcessManager

    init() {
        let dbManager = GRDBManager.shared
        let logProcessor = LogProcessor(dbManager: dbManager)
        let proxyManager = MitmProcessManager(logProcessor: logProcessor)

        self.dbManager = dbManager
        self.logProcessor = logProcessor
        _proxyManager = StateObject(wrappedValue: proxyManager)
    }

    var body: some View {
        NavigationSplitView {
            SidebarFilterView(filter: filter, logs: proxyManager.logs)
                .frame(minWidth: 220)
        } content: {
            List(filter.apply(to:  proxyManager.logs)) { log in
                NavigationLink(value: log) {
                    ProxyLogRow(log: log)
                }
            }
            .navigationTitle("Logs \(filter.apply(to:  proxyManager.logs).count)")
            .navigationDestination(for: ProxyLog.self) { log in
                MitmLogDetailView(log: log, regex: filter.regex)
            }
        } detail: {
            Text("Chọn log để xem chi tiết")
                .foregroundColor(.secondary)
                .font(.headline)
        }
        .onAppear {
            proxyManager.startProxy()
        }
    }
}
