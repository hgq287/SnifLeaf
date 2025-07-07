//
//  BenchmarkView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 7/7/25.
//

import SwiftUI
import Charts
import SnifLeafCore

public enum BenchmarkDimension: String, CaseIterable, Identifiable {
    case category = "Category"
    case endpoint = "Endpoint"
    
    public var id: String { self.rawValue }
}

public enum TimeRange: String, CaseIterable, Identifiable {
    case last1Hour = "Last Hour"
    case last6Hours = "Last 6 Hours"
    case last24Hours = "Last 24 Hours"
    case last7Days = "Last 7 Days"
    case allTime = "All Time"
    
    public var id: String { self.rawValue }
    
    func startDate() -> Date? {
        let now = Date()
        switch self {
        case .last1Hour:
            return Calendar.current.date(byAdding: .hour, value: -1, to: now)
        case .last6Hours:
            return Calendar.current.date(byAdding: .hour, value: -6, to: now)
        case .last24Hours:
            return Calendar.current.date(byAdding: .hour, value: -24, to: now)
        case .last7Days:
            return Calendar.current.date(byAdding: .day, value: -7, to: now)
        case .allTime:
            return nil
        }
    }
}

struct BenchmarkView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedDimension: BenchmarkDimension = .category
    @State private var selectedTimeRange: TimeRange = .last1Hour
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Benchmarks")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            Picker("Analyze By", selection: $selectedDimension) {
                ForEach(BenchmarkDimension.allCases) { dimension in
                    Text(dimension.rawValue).tag(dimension)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedDimension) { oldVal, newVal in
                appState.selectedDimension = newVal
            }

            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .onChange(of: selectedTimeRange) { oldVal, newVal in
                appState.selectedTimeRange = newVal
            }
            
            if selectedDimension == .category {
                CategoryBenchmarkTableView()
                    .environmentObject(appState)
            } else {
                EndpointBenchmarkTableView()
                    .environmentObject(appState)
            }
        }
        .padding()
        .onAppear {
            appState.selectedDimension = selectedDimension
            appState.selectedTimeRange = selectedTimeRange
            appState.fetchBenchmarks()
        }
    }
}
