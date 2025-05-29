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
    var regex: NSRegularExpression? = nil

    @State private var nodes: [JSONNode] = []
    @State private var expanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) { content } label: {
            Text(title).font(.headline)
        }
        .onAppear {
            if let json { nodes = json.map { JSONNode(key: $0.key, value: .string($0.value)) } }
        }
    }

    @ViewBuilder private var content: some View {
        if let json {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(nodes) { JSONNodeView(node: $0, regex: regex) }
            }.padding(.leading, 6)
        } else if let raw, !raw.isEmpty {
            ScrollView(.horizontal) {
                Text(raw)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(colorFor(raw))
            }
        } else { Text("No data").foregroundColor(.secondary) }
    }

    private func colorFor(_ text: String) -> Color { regexMatch(text) ? .red : .primary }
    private func regexMatch(_ text: String) -> Bool {
        guard let regex else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
