//
//  EndpointBenchmarkTableView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 7/7/25.
//

import SwiftUI
import Charts
import SnifLeafCore

struct EndpointBenchmarkTableView: View {
    @EnvironmentObject var appState: AppState
    
    private let displayLimit = 20
    
    var body: some View {
        VStack {
            if appState.endpointBenchmarks.isEmpty {
                ContentUnavailableView(
                    "No Data for Selected Range",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Try adjusting the time range or ensuring the proxy is running to generate traffic logs.")
                )
            } else {
                EndpointLatencyChart(metrics: Array(appState.endpointBenchmarks.prefix(displayLimit)))
                    .frame(height: 300)
                    .padding(.bottom)

                Table(Array(appState.endpointBenchmarks.prefix(displayLimit))) {
                    TableColumn("Endpoint") { metric in
                        Text(metric.dimension)
                            .lineLimit(1)
                            .font(.subheadline)
                            .help(metric.dimension)
                    }
                    TableColumn("Requests") { metric in
                        Text("\(metric.requestCount)")
                    }
                    TableColumn("Avg Latency (ms)") { metric in
                        Text(String(format: "%.2f", metric.avgLatency))
                    }
                    TableColumn("P95 Latency (ms)") { metric in
                        Text(String(format: "%.2f", metric.p95Latency))
                    }
                    TableColumn("Error Rate (%)") { metric in
                        Text(String(format: "%.2f%%", metric.errorRate * 100))
                            .foregroundStyle(metric.errorRate > 0 ? .red : .primary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .task(id: appState.selectedTimeRange) {
            appState.fetchBenchmarks()
        }
    }
}

// MARK: - Chart for Endpoint Latency
struct EndpointLatencyChart: View {
    var metrics: [BenchmarkMetrics]
    
    private func cleanUrl(_ url: String) -> String {
        if let range = url.range(of: "://") {
            let schemeRemoved = String(url[range.upperBound...])

            if let wwwRange = schemeRemoved.range(of: "www.") {
                return String(schemeRemoved[wwwRange.upperBound...])
            }
            return schemeRemoved
        }
        return url
    }
    
    var body: some View {
        Chart {
            ForEach(metrics.sorted(by: { $0.avgLatency > $1.avgLatency })) { metric in
                BarMark(
                    x: .value("Endpoint", cleanUrl(metric.dimension)), // SỬA ĐỔI Ở ĐÂY
                    y: .value("Avg Latency (ms)", metric.avgLatency)
                )
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.1f", metric.avgLatency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartXScale(domain: .automatic)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
    }
}

