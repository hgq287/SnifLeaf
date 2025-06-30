//
//  AppState.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 30/5/25.
//

import Foundation
import SwiftUI
import Shared
import SnifLeafCore
import UserNotifications

public final class AppState: ObservableObject {

    // MARK: - Core Managers & Models
    @Published public var dbManager: GRDBManager
    @Published public var logProcessor: LogProcessor
    @Published public var mitmProcessManager: MitmProcessManager

    // MARK: - Interactors (Feature-specific logic)
    @Published public var logListInteractor: LogListInteractor

    // MARK: - Initializer
    public init() {
        let _sharedDBManager = GRDBManager.shared
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbURL = URL(fileURLWithPath: path).appendingPathComponent("snifleaf.sqlite3")
        _sharedDBManager.openDatabase(databaseURL: dbURL)
        self.dbManager = _sharedDBManager
        
        let _logProcessor = LogProcessor(dbManager: _sharedDBManager)
        self.logProcessor = _logProcessor

        let _mitmProcessManager = MitmProcessManager.shared
        _mitmProcessManager.logProcessor = _logProcessor
        self.mitmProcessManager = _mitmProcessManager
        
        self.logListInteractor = LogListInteractor(dbManager: _sharedDBManager)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("AppState: Notification permissions granted.")
            } else if let error = error {
                print("AppState: Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
        
        print("AppState: All core components and interactors initialized.")
    }

    // MARK: - App Lifecycle Methods
    public func startup() {
        print("AppState: Startup sequence initiated, starting proxy...")
        mitmProcessManager.startProxy { success in
            if success {
                print("AppState: Proxy started successfully.")
            } else {
                print("AppState: Failed to start proxy.")
            }
        }
    }
    
    public func shutdown() {
        print("AppState: Shutdown sequence initiated, stopping proxy...")
        mitmProcessManager.stopExistingMitmdump {}
    }
}


