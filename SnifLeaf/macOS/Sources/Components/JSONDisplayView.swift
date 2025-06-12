//
//  JSONDisplayView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI

struct JSONDisplayView: View {
    let jsonDict: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(jsonDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack(alignment: .top) {
                    Text(key + ":")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .trailing)
                    Text(value)
                        .font(.footnote)
                        .monospaced()
                        .textSelection(.enabled)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(5)
    }
}

// MARK: - Preview
struct JSONDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        JSONDisplayView(jsonDict: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer some_long_token_string_here_for_testing_purposes"
        ])
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("JSON Display View")
    }
}
