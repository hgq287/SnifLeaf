//
//  CustomToolbarView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 27/6/25.
//

import SwiftUI

struct CustomToolbarView: View {
    var body: some View {
        HStack {
            Button { print("Replay") } label: { Label("Replay", systemImage: "arrow.counterclockwise") }
            Button { print("Duplicate") } label: { Label("Duplicate", systemImage: "doc.on.doc") }
            Button { print("Revert") } label: { Label("Revert", systemImage: "arrow.uturn.backward") }
            Button { print("Delete") } label: { Label("Delete", systemImage: "trash") }

            Spacer()

            Button { print("Download") } label: { Label("Download", systemImage: "arrow.down.doc") }
            Button { print("Resume") } label: { Label("Resume", systemImage: "play.fill") }
            Button { print("Abort") } label: { Label("Abort", systemImage: "xmark.circle.fill") }
        }
        .buttonStyle(.borderless)
        .padding(8)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.gray.opacity(0.3)), alignment: .bottom)
    }
}

#Preview {
    CustomToolbarView()
}
