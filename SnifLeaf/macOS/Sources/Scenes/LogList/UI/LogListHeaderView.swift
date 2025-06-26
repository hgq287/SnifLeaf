//
//  LogListHeaderView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 27/6/25.
//

import SwiftUI

struct LogListHeaderView: View {
    @ObservedObject var logListInteractor: LogListInteractor

    var body: some View {
        HStack {

            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search logs...", text: $logListInteractor.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 300)

            Spacer()

            Button("Clear All Logs") {
                logListInteractor.deleteAllLogs()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(0)
    }
}
