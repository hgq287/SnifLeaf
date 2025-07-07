//
//  LogDetailView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI
import SnifLeafCore

struct LogDetailView: View {
    let log: LogEntry

    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: DetailTab = .summary

    enum DetailTab: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case request = "Request"
        case response = "Response"

        var id: String { self.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header với tiêu đề và nút đóng
            HStack {
                Text("Log Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 10)

            Divider()

            // Tab Bar
            Picker("Detail Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content dựa trên Tab được chọn
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    switch selectedTab {
                    case .summary:
                        SummaryDetailView(log: log)
                    case .request:
                        RequestDetailView(log: log)
                    case .response:
                        ResponseDetailView(log: log)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Sub-Views for LogDetailView Tabs

struct SummaryDetailView: View {
    let log: LogEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General Information")
                .font(.headline)
                .padding(.bottom, 5)
            
            detailRow(title: "URL", value: log.url)
            detailRow(title: "Method", value: log.method)
            detailRow(title: "Status Code", value: "\(log.statusCode)")
            detailRow(title: "Host", value: log.host ?? "N/A")
            detailRow(title: "Path", value: log.path ?? "N/A")
            detailRow(title: "Timestamp", value: log.timestamp, formatter: fullDateFormatter)
            detailRow(title: "Latency", value: "\(String(format: "%.2f", log.latency * 1000)) ms")
            detailRow(title: "Request Size", value: formatBytes(log.requestSize))
            detailRow(title: "Response Size", value: formatBytes(log.responseSize))

            if let queryParamsString = log.queryParams,
               let queryParams = parseJsonString(queryParamsString) as? [String: String],
               !queryParams.isEmpty {
                Divider()
                Text("Query Parameters")
                    .font(.headline)
                JSONDisplayView(jsonDict: queryParams)
            }
        }
    }
}

struct RequestDetailView: View {
    let log: LogEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let requestHeadersString = log.requestHeaders,
               let headers = parseJsonString(requestHeadersString) as? [String: String],
               !headers.isEmpty {
                Text("Request Headers")
                    .font(.headline)
                    .padding(.bottom, 5)
                JSONDisplayView(jsonDict: headers)
            }
            
            if let requestBodyData = log.requestBodyContent {
                Divider()
                Text("Request Body Content")
                    .font(.headline)
                    .padding(.bottom, 5)
                CodeDisplayView(content: displayContent(for: requestBodyData))
            } else {
                Text("No Request Body Content")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ResponseDetailView: View {
    let log: LogEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let responseHeadersString = log.responseHeaders,
               let headers = parseJsonString(responseHeadersString) as? [String: String],
               !headers.isEmpty {
                Text("Response Headers")
                    .font(.headline)
                    .padding(.bottom, 5)
                JSONDisplayView(jsonDict: headers)
            }
            
            if let responseBodyData = log.responseBodyContent {
                Divider()
                Text("Response Body Content")
                    .font(.headline)
                    .padding(.bottom, 5)
                CodeDisplayView(content: displayContent(for: responseBodyData))
            } else {
                Text("No Response Body Content")
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Reusable Helper Views for Detail Display

struct detailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .trailing)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    init(title: String, value: Date, formatter: DateFormatter) {
        self.title = title
        self.value = formatter.string(from: value)
    }
}

// MARK: - Global Helper Functions (can be moved to a Utility file)

private func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

private var fullDateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter
}

private func displayContent(for data: Data) -> String {
    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
       let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
       let prettyJsonString = String(data: prettyJsonData, encoding: .utf8) {
        return prettyJsonString
    }
    if let utf8String = String(data: data, encoding: .utf8) {
        return utf8String // Thử giải mã là UTF-8
    }
    return data.base64EncodedString() // Fallback về Base64
}

private func parseJsonString(_ jsonString: String) -> Any? {
    guard let data = jsonString.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
}

// MARK: - Preview Provider
//struct LogDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LogDetailView(log: LogEntry(id: 1, timestamp: Date(), method: "POST", url: "https://api.example.com/data/submit?user=test&token=abc", host: "api.example.com", path: "/data/submit", queryParams: "{\"user\":\"test\",\"token\":\"abc\"}", requestSize: 500, responseSize: 200, statusCode: 200, latency: 0.123, requestHeaders: "{\"Content-Type\":\"application/json\",\"Authorization\":\"Bearer xyz\"}", responseHeaders: "{\"Server\":\"Nginx\",\"X-Cache\":\"HIT\"}", requestBodyContent: "{\"name\":\"test\", \"value\":123}".data(using: .utf8), responseBodyContent: "{\"status\":\"success\",\"data\":{\"id\":123}}".data(using: .utf8)))
//            .previewDisplayName("Log Detail View - Pro")
//    }
//}
