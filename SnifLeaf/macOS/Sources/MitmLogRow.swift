//
//  MitmLogRow.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

struct MitmLogRow: View {
    let log: MitmLog
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
