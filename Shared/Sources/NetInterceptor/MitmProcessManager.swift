//
//  MitmProcessManager.swift
//  Shared
//
//  Created by Hg Q. on 2/6/25.
//

import Foundation

class MitmProcessManager {
    static let shared = MitmProcessManager()

    func stopExistingMitmdump(timeout: TimeInterval = 1.0, completion: @escaping () -> Void) {
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killTask.arguments = ["-9", "mitmdump"]
        try? killTask.run()

        DispatchQueue.global().async {
            let start = Date()
            while Date().timeIntervalSince(start) < timeout {
                Thread.sleep(forTimeInterval: 0.1)
            }

            completion()
        }
    }
}
  
