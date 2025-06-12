//
//  App.swift
//  SnifLeaf
//
//  Created by Hg Q. on 20/4/25.
//

import SwiftUI

@main
struct MainApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) 
        }
        // ...
    }
}
