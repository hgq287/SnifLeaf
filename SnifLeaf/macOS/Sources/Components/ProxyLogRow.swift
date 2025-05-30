//
//  ProxyLogRow.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared

struct ProxyLogRow: View {
    let log: ProxyLog
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("[\(log.method)] \(log.url)")
                .lineLimit(1)
            HStack {
                Text("Status: \(log.status_code)").foregroundColor(.green)
                Spacer()
                Text(log.host).foregroundColor(.gray)
            }.font(.caption)
        }
    }
}
