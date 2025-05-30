//
//  SidebarFilterView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared

struct SidebarFilterView: View {
    @ObservedObject var filter: LogFilter
    let logs: [ProxyLog]

    var body: some View {
        List {
            Section("Host") {
                TextField("floware.com", text: $filter.host)
            }
            Section("Method") {
                TextField("GET/PUT/DELETE, ...", text: $filter.method)
            }
            Section("Status") {
                TextField("200/404, ... ", text: $filter.status)
            }
//            Section("Regex") {
//                TextField("pattern", text: $filter.regexText)
//                    .foregroundColor(filter.isRegexValid ? .primary : .red)
//            }
            Section("Summary") {
                Text("Total logs: \(logs.count)")
                Text("Filtered logs: \(filter.apply(to: logs).count)")
            }
        }
        .listStyle(SidebarListStyle())
    }
}
