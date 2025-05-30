//
//  LogListView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared

struct LogListView: View {
    let logs: [ProxyLog]
    @ObservedObject var filter: LogFilter

    var body: some View {
        let filtered = filter.apply(to: logs)
        List(filtered) { log in
            NavigationLink(value: log) {
                ProxyLogRow(log: log)
            }
        }
        .navigationTitle("Logs \(filtered.count)")
    }
}
