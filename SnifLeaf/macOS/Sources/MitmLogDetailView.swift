//
//  MitmLogDetailView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 29/5/25.
//

import SwiftUI

struct MitmLogDetailView: View {
    let log: MitmLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Method: \(log.method)")
                Text("URL: \(log.url)")
                Text("Status: \(log.status_code)")

                SectionView(title: "Request Headers", json: log.headers)
                SectionView(title: "Request Body", raw: log.content)
                SectionView(title: "Response Headers", json: log.response_headers)
                SectionView(title: "Response Body", raw: log.response_content)
            }
            .padding()
        }
        .navigationTitle("Detail View")
    }
}
