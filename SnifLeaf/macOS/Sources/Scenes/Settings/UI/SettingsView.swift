//
//  SettingsView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("General Settings")) {
                Toggle(isOn: .constant(true)) {
                    Text("Enable Notifications")
                }
            }

            Section(header: Text("About SnifLeaf")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                }
                Link("Visit GitHub Repository", destination: URL(string: "https://github.com/hgq287/SnifLeaf")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewDisplayName("Settings View")
    }
}
