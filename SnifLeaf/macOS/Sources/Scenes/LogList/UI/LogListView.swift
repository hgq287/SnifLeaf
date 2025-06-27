//
//  LogListView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI
import Shared
import SnifLeafCore

struct LogListView: View {
    @EnvironmentObject var logListInteractor: LogListInteractor

    @State private var selectedLog: LogEntry?
    @State private var showingDetailSheet: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
           VStack(spacing: 0) {
               CustomToolbarView()
                   .frame(maxWidth: .infinity)
                   .background(Color.gray.opacity(0.1))
                   .padding(.bottom, 1)

               LogListHeaderView(logListInteractor: logListInteractor)
                   .frame(maxWidth: .infinity)

               Divider()

               HSplitView {
                   LogListBodyView(
                       logListInteractor: logListInteractor,
                       selectedLog: $selectedLog
                   )
                   .frame(minWidth: 450)
                   .layoutPriority(1)

  
                   Group {
                       if let log = selectedLog {
                           LogDetailView(log: log)
                               .frame(minWidth: 300)
                       } else {
                           EmptyDetailView()
                               .frame(maxWidth: 300, maxHeight: .infinity)
                               .foregroundColor(.secondary)
                               .padding()
                               .multilineTextAlignment(.center)
                               .overlay(
                                   Text("Select a log to view details")
                                       .font(.headline)
                                       .foregroundColor(.gray)
                               )
                           
                       }
                   }
               }
               .frame(maxWidth: .infinity, maxHeight: .infinity)
           }

           .frame(maxWidth: .infinity, maxHeight: .infinity)
           
           .ignoresSafeArea(.container, edges: [])
           .navigationTitle("Live Network Logs")
           .sheet(isPresented: $showingDetailSheet) {
               if let log = selectedLog {
                   LogDetailView(log: log)
                       .frame(minWidth: 600, minHeight: 700)
               }
           }
       }
}

// MARK: - Preview Provider
struct LogListView_Previews: PreviewProvider {
    static var previews: some View {
        LogListView()
            .environmentObject(LogListInteractor(dbManager: GRDBManager.shared))
            .previewDisplayName("Log List View - No GRDBQuery")
    }
}
