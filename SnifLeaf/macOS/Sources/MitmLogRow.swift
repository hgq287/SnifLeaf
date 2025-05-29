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
        VStack(alignment: .leading) {
            Text("[\(log.method)] \(log.url)")
                .font(.subheadline)
                .lineLimit(1)
            HStack {
                Text("Status: \(log.status_code)")
                    .foregroundColor(.green)
                Spacer()
                Text("Host: \(log.host)")
                    .foregroundColor(.gray)
            }
            .font(.caption)
        }
        .padding(4)
    }
}

