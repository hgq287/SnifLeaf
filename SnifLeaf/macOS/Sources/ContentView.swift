//
//  ContentView.swift
//  SnifLeaf
//
//  Created by Hg Q. on 20/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = MitmProxyManager()
    @State private var filterHost = ""
    @State private var filterMethod = ""
    @State private var filterStatus = ""

    var filteredLogs: [MitmLog] {
        manager.logs.filter { log in
            (filterHost.isEmpty || log.host.contains(filterHost)) &&
            (filterMethod.isEmpty || log.method.localizedCaseInsensitiveContains(filterMethod)) &&
            (filterStatus.isEmpty || String(log.status_code).contains(filterStatus))
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                HStack {
                    TextField("Host", text: $filterHost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Method", text: $filterMethod)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Status", text: $filterStatus)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                List(filteredLogs) { log in
                    NavigationLink(destination: MitmLogDetailView(log: log)) {
                        MitmLogRow(log: log)
                    }
                }
            }
            .navigationTitle("Inspector")
        }
        .onAppear {
            manager.startProxy()
        }
        .onDisappear {
            manager.stopProxy()
        }
    }
}

#Preview {
    ContentView()
}
