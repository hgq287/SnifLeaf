//
//  ContentView.swift
//  SnifLeaf
//
//  Created by Hg Q. on 20/4/25.
//

import SwiftUI
import SnifLeafCore

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: SidebarTab = .liveLogs

    enum SidebarTab: String, CaseIterable, Identifiable {
        case liveLogs = "Live Logs"
        case benchmarks = "Benchmarks"
        case anomalies = "AI Anomous Detection"
        case proxyControl = "Proxy Control"
        case settings = "Settings"

        var id: String { self.rawValue }

        var systemImage: String {
            switch self {
            case .liveLogs: return "network"
            case .benchmarks: return "chart.bar.fill"
            case .anomalies: return "exclamationmark.triangle.fill"
            case .proxyControl: return "hammer.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            List(selection: $selectedTab) {
                ForEach(SidebarTab.allCases) { tab in
                    NavigationLink(destination: destinationView(for: tab)) {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                    .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .navigationTitle("SnifLeaf")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.leading")
                    }
                }
            }

            destinationView(for: selectedTab)
        }
        
        .onAppear {
            // Initialize the app state and start necessary processes
            appState.startup()
        }
        .onDisappear() {
            // Clean up resources if needed
            appState.shutdown()
        }
    }
       

    @ViewBuilder
    private func destinationView(for tab: SidebarTab) -> some View {
        switch tab {
        case .liveLogs:
            LogListView()
                .environmentObject(appState.logListInteractor)
            // Tab mới cho Benchmarks
        case .benchmarks:
            BenchmarkView()
                .tabItem { Label("Benchmarks", systemImage: "chart.bar.fill") }
        case .anomalies:
//            AnomalyView()
//                .environmentObject(appState.anomalyDetectionViewModel)
            LogListView()
                .environmentObject(appState.logListInteractor)
        case .proxyControl:
            ProxyControlView()
                .environmentObject(appState.mitmProcessManager)
        case .settings:
            SettingsView()
        }
    }
    
    private func toggleSidebar() {
        #if os(macOS)
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
}

// MARK: - Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
