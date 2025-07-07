//
//  LogRowFancyView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import SnifLeafCore

struct LogRowFancyView: View {
    let log: LogEntry

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Timestamp (left aligned)
            Text(log.timestamp, formatter: dateFormatter)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)

            // Method & Status Code
            VStack(alignment: .leading, spacing: 2) {
                Text(log.method)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(methodColor(for: log.method).opacity(0.8))
                    .cornerRadius(4)
                    .foregroundColor(.white)
                
                Text("\(log.statusCode)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(statusColor(for: log.statusCode).opacity(0.8))
                    .cornerRadius(4)
                    .foregroundColor(.white)
            }
            .frame(width: 70)

            // URL & Host
            VStack(alignment: .leading) {
                Text(log.url)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let host = log.host, !host.isEmpty {
                    Text(host)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()

            // Latency
            Text("\(String(format: "%.0f", log.latency * 1000)) ms")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Sizes
            HStack(spacing: 4) {
                Text(formatBytes(log.requestSize))
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(3)
                Text(formatBytes(log.responseSize))
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(3)
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .background(Color.clear)
    }

    private func methodColor(for method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .gray
        }
    }

    private func statusColor(for statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300: return .green
        case 300..<400: return .orange
        case 400..<500: return .red
        case 500..<600: return .purple
        default: return .gray
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}

// MARK: - Preview
//struct LogRowFancyView_Previews: PreviewProvider {
//    static var previews: some View {
//        LogRowFancyView(log: LogEntry(id: 1, timestamp: Date().addingTimeInterval(-10), method: "GET", url: "https://api.example.com/data/users?id=123", host: "api.example.com", path: "/data/users", queryParams: "{\"id\":\"123\"}", requestSize: 100, responseSize: 500, statusCode: 200, latency: 0.15, requestHeaders: "{\"Content-Type\":\"application/json\"}", responseHeaders: "{\"Content-Type\":\"application/json\"}", requestBodyContent: nil, responseBodyContent: "{\"user\":\"example\"}".data(using: .utf8), trafficCategory: "API"))
//            .previewLayout(.sizeThatFits)
//            .padding()
//            .previewDisplayName("Log Row Fancy")
//    }
//}
