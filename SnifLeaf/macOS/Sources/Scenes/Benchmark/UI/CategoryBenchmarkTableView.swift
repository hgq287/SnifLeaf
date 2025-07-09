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
        case .googleServices: return "magnifyingglass"
        case .socialMedia: return "person.3.fill"
        case .videoStreaming: return "play.rectangle.fill"
        case .gaming: return "gamecontroller.fill"
        case .apiCallJson: return "cloud.fill"
        case .newsAndInformation: return "newspaper.fill"
        case .email: return "envelope.fill"
        case .productivity: return "text.book_closed.fill"
        case .shopping: return "cart.fill"
        case .security: return "lock.fill"
        case .fileTransfer: return "arrow.up.arrow.down.square.fill"
        case .p2p: return "bolt.fill"
        case .systemUpdates: return "arrow.clockwise.icloud.fill"
        case .advertisement: return "megaphone.fill"
        case .iotDevice: return "lightbulb.fill"
        case .unknown: return "questionmark.circle.fill"
        case .others: return "ellipsis.circle.fill"
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
