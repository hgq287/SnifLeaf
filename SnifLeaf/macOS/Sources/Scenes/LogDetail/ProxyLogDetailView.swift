//
//  MitmLogDetailView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared

struct MitmLogDetailView: View {
    var log: ProxyLog
    var regex: NSRegularExpression?
    @StateObject var manager = MitmProcessManager()
    
    @State private var editableRequestBody: String
    @State private var editableRequestHeaders: [String: String]

    init(log: ProxyLog, regex: NSRegularExpression? = nil) {
        self.log = log
        self.regex = regex
        _editableRequestBody = State(initialValue: log.content ?? "")
        _editableRequestHeaders = State(initialValue: log.headers)
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Method: \(log.method)")
                Text("URL: \(log.url)")
                Text("Status: \(log.status_code)")
                
                // MARK: - Request Headers
                SectionView(title: "Request Headers", json: log.headers, regex: regex)
//                Section(header: Text("Request Headers").bold().font(.title3)) {
//                    ForEach(Array(editableRequestHeaders.keys), id: \.self) { key in
//                        HStack(alignment: .top) {
//                            Text(key)
//                                .font(.system(.body, design: .monospaced))
//                                .frame(width: 160, alignment: .leading)
//                                .foregroundColor(.secondary)
//                            TextField("Value", text: Binding(
//                                get: { editableRequestHeaders[key] ?? "" },
//                                set: { editableRequestHeaders[key] = $0 }
//                            ))
//                            .textFieldStyle(.roundedBorder)
//                        }
//                    }
//                }
                
                // MARK: - Request Body
                SectionView(title: "Request Body", raw: log.content, regex: regex)

//                Section(header: Text("Request Body").bold().font(.title3)) {
//                    ScrollView {
//                        TextEditor(text: log.content)
//                            .font(.system(.body, design: .monospaced))
//                            .padding(6)
//                            .frame(minHeight: 140, maxHeight: 300)
//                            .background(Color(NSColor.textBackgroundColor))
//                            .cornerRadius(8)
//                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
//                    }
//                }
                SectionView(title: "Response Headers", json: log.response_headers, regex: regex)
                SectionView(title: "Response Body", raw: log.response_content, regex: regex)
                // MARK: - Action Buttons
//                     HStack(spacing: 16) {
//                         Button(action: {
//                             var updatedLog = log
//                             updatedLog.headers = editableRequestHeaders
//                             updatedLog.content = editableRequestBody
//                             manager.replay(log: updatedLog)
//                         }) {
//                             Label("Replay Request", systemImage: "arrow.clockwise")
//                                 .font(.body)
//                                 .padding(.horizontal)
//                                 .padding(.vertical, 6)
//                                 .background(Color.accentColor.opacity(0.1))
//                                 .cornerRadius(8)
//                         }
//
//                         Button(action: {
//                             manager.exportToFile(log)
//                         }) {
//                             Label("Export HAR", systemImage: "square.and.arrow.up")
//                                 .font(.body)
//                                 .padding(.horizontal)
//                                 .padding(.vertical, 6)
//                                 .background(Color.accentColor.opacity(0.1))
//                                 .cornerRadius(8)
//                         }
//                     }
//                     .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Detail")
        .onAppear {
            updateEditableFields()
        }
        .onChange(of: log) { _ in
            updateEditableFields()
        }
    }
    
    private func updateEditableFields() {
        editableRequestBody = log.content ?? ""
        editableRequestHeaders = log.headers
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
