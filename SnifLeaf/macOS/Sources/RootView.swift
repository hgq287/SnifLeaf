//
//  RootView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

//struct RootView: View {
//    @StateObject private var proxy = MitmProxyManager()
//    @StateObject private var filter = FilterModel()
//
//    var body: some View {
//        NavigationSplitView {
//            SidebarFilterView(filter: filter, logs: proxy.logs)
//                .frame(minWidth: 220)
//        } detail: {
//            LogListView(logs: proxy.logs, filter: filter)
//        }
//        .navigationDestination(for: MitmLog.self) { log in
//            MitmLogDetailView(log: log, regex: filter.regex)
//        }
//        .onAppear {
//            proxy.startProxy()
//        }
//    }
//}

//struct RootView: View {
//    @StateObject private var proxy = MitmProxyManager()
//    @StateObject private var filter = FilterModel()
//
//    var body: some View {
//        NavigationSplitView {
//            SidebarFilterView(filter: filter, logs: proxy.logs)
//                .frame(minWidth: 220)
//        } content: {
//            LogListView(logs: proxy.logs, filter: filter)
//        } detail: {
//            Text("Chọn một log để xem chi tiết") // placeholder nếu chưa chọn log
//        }
//        // ⬇️ GẮN trực tiếp ở đây!
//        .navigationDestination(for: MitmLog.self) { log in
//            MitmLogDetailView(log: log, regex: filter.regex)
//        }
//        .onAppear {
//            proxy.startProxy()
//        }
//    }
//}

struct RootView: View {
    @StateObject private var proxy = MitmProxyManager()
    @StateObject private var filter = FilterModel()
    @State private var selectedLog: MitmLog? = nil

    var body: some View {
        NavigationSplitView {
            SidebarFilterView(filter: filter, logs: proxy.logs)
                .frame(minWidth: 220)
        } content: {
            List(filter.apply(to: proxy.logs)) { log in
                NavigationLink(value: log) {
                    MitmLogRow(log: log)
                }
            }
            .navigationTitle("Logs \(filter.apply(to: proxy.logs).count)")
            .navigationDestination(for: MitmLog.self) { log in
                MitmLogDetailView(log: log, regex: filter.regex)
            }
        } detail: {
            Text("Chọn một log để xem chi tiết")
        }
        .onAppear {
            proxy.startProxy()
        }
    }
}
