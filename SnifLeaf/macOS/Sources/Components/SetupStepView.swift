//
//  SetupStepView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI

struct SetupStepView: View {
    let stepNumber: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(stepNumber)")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled) // Cho phép copy text hướng dẫn
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview
struct SetupStepView_Previews: PreviewProvider {
    static var previews: some View {
        SetupStepView(
            stepNumber: 1,
            title: "Install Homebrew & mitmproxy",
            description: "Open Terminal and run: `brew install python mitmproxy`"
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Setup Step View")
    }
}
