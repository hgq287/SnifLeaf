//
//  EmptyDetailView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 27/6/25.
//

import SwiftUI

struct EmptyDetailView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 80)) // Larger icon
                .foregroundColor(.accentColor.opacity(0.6))
                .padding(.bottom, 20)
            
            Text("No Log Selected")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            Text("Select a network log from the list on the left to view its details (request, response, etc.).")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    EmptyDetailView()
}
