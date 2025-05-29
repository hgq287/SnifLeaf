//
//  MitmLogDetailView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

struct MitmLogDetailView: View {
    let log: MitmLog
    var regex: NSRegularExpression?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Method: \(log.method)")
                Text("URL: \(log.url)")
                Text("Status: \(log.status_code)")
                SectionView(title: "Request Headers", json: log.headers, regex: regex)
                SectionView(title: "Request Body", raw: log.content, regex: regex)
                SectionView(title: "Response Headers", json: log.response_headers, regex: regex)
                SectionView(title: "Response Body", raw: log.response_content, regex: regex)
            }
            .padding()
        }
        .navigationTitle("Detail")
    }
}

struct JSONNode: Identifiable {
    let id = UUID(); let key: String; let value: JSONValue
}

enum JSONValue { case string(String), number(Double), bool(Bool), object([JSONNode]), array([JSONValue]), null }



struct JSONNodeView: View {
    let node: JSONNode
    var regex: NSRegularExpression?
    @State private var open = false

    var body: some View {
        switch node.value {
        case .object(let children):
            DisclosureGroup(isExpanded: $open) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(children) { JSONNodeView(node: $0, regex: regex) }
                }.padding(.leading, 6)
            } label: { label("{…}") }
        case .array(let arr):
            DisclosureGroup(isExpanded: $open) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(arr.indices, id: \ .self) { i in
                        Text("- \(string(arr[i]))").foregroundColor(color(for: arr[i]))
                    }
                }.padding(.leading, 6)
            } label: { label("[…]") }
        default:
            label(string(node.value))
        }
    }

    @ViewBuilder private func label(_ valueDesc: String) -> some View {
        HStack {
            Text(node.key + ":").fontWeight(.semibold)
            Text(valueDesc).foregroundColor(color(for: node.value))
        }.font(.system(.caption, design: .monospaced))
    }

    private func string(_ val: JSONValue) -> String {
        switch val {
        case .string(let s): return "\"\(s)\""
        case .number(let n): return "\(n)"
        case .bool(let b): return b ? "true" : "false"
        case .object: return "{…}"
        case .array: return "[…]"
        case .null: return "null"
        }
    }

    private func color(for val: JSONValue) -> Color {
        switch val {
        case .string(let s): return regexMatch(s) ? .red : .secondary
        default: return .secondary
        }
    }

    private func regexMatch(_ text: String) -> Bool {
        guard let regex else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
