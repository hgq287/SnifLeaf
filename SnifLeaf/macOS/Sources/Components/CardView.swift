//
//  CardView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI

struct CardView<Content: View>: View {
    let title: String?
    let icon: String?
    let content: Content

    init(title: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let title = title {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                Divider()
            }
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 5) // Padding nhẹ để shadow không bị cắt
    }
}

// MARK: - Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(title: "Example Card", icon: "info.circle.fill") {
            Text("This is some content inside the card.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Card View with Title")

        CardView {
            Text("This is a simple card without a title or icon.")
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .previewDisplayName("Card View Simple")
    }
}
