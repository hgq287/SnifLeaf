//
//  LogListView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

struct LogListView: View {
    let logs: [MitmLog]
    @ObservedObject var filter: FilterModel

    var body: some View {
        let filtered = filter.apply(to: logs)
        List(filtered) { log in
            NavigationLink(value: log) {
                MitmLogRow(log: log)
            }
        }
        .navigationTitle("Logs \(filtered.count)")
    }
}
