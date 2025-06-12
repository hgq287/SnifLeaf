//
//  CodeDisplayView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI

struct CodeDisplayView: View {
    let content: String

    var body: some View {
        Text(content)
            .font(.footnote)
            .monospaced()
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.05))
            .cornerRadius(5)
            .textSelection(.enabled)
            .minimumScaleFactor(0.8) 
    }
}

// MARK: - Preview
struct CodeDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        CodeDisplayView(content: """
        {
            "status": "success",
            "data": {
                "user_id": 12345,
                "username": "example_user",
                ""email": "user@example.com",
                "roles": ["admin", "user"]
            },
            "message": "User data retrieved successfully."
        }
        """)
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Code Display View")
    }
}
