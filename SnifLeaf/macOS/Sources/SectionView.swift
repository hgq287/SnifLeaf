//
//  SectionView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

struct SectionView: View {
    let title: String
    var json: [String: String]? = nil
    var raw: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let json = json {
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(json.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                            Text("\(key): \(value)")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            } else if let raw = raw, !raw.isEmpty {
                ScrollView(.horizontal) {
                    Text(raw)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color(.systemGray.withAlphaComponent(0.5)))
                        .cornerRadius(4)
                }
            } else {
                Text("No data")
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(Color(.systemGray.withAlphaComponent(0.5)))
        .cornerRadius(8)
    }
}
