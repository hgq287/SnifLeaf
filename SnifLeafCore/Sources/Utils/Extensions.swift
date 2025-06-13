//
//  Extensions.swift
//  SnifLeafCore
//
//  Created by Hg Q. on 13/6/25.
//

import Foundation

extension Notification.Name {
    public static let GRDBDidUpdate = Notification.Name("GRDBDidUpdateNotification")
    public static let GRDBSavedNewLog = Notification.Name("GRDBSavedNewLogNotification")
}

public struct NotificationKeys {
    public static let newLogEntry = "newLogEntry"
}
