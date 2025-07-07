//
//  CategoryBenchmarkTableView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 7/7/25.
//

import SwiftUI
import Charts
import SnifLeafCore

struct CategoryBenchmarkTableView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            if appState.categoryBenchmarks.isEmpty {
                ContentUnavailableView(
                    "No Data for Selected Range",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text("Try adjusting the time range or ensuring the proxy is running to generate traffic logs.")
                )
            } else {
                CategoryLatencyChart(metrics: appState.categoryBenchmarks)
                    .frame(height: 300)
                    .padding(.bottom)
                
                Table(appState.categoryBenchmarks) {
                    TableColumn("Category") { metric in
                        HStack {
                            Image(systemName: iconForCategory(metric.dimension))
                            Text(metric.dimension)
                        }
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
            // Fetch data when the time range changes or when the view appears
//            appState.fetchBenchmarks()
        }
    }
    
    func iconForCategory(_ category: String) -> String {
        switch TrafficCategory.fromString(category) {
        case .other: return "ellipsis.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Chart for Category Benchmarks
struct CategoryLatencyChart: View {
    var metrics: [BenchmarkMetrics]
    
    var body: some View {
        Chart {
            ForEach(metrics.sorted(by: { $0.avgLatency > $1.avgLatency })) { metric in
                BarMark(
                    x: .value("Category", metric.dimension),
                    y: .value("Avg Latency (ms)", metric.avgLatency)
                )
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.1f", metric.avgLatency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(by: .value("Category", metric.dimension))
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
        .chartForegroundStyleScale(domain: TrafficCategory.allCases.map { $0.rawValue })
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
    }
}
