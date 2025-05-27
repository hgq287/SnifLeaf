//
//  IDatabase.swift
//  CyberLeafXCore
//
//  Created by Dat T. on 10/12/19.
//

import Foundation

public protocol IDatabase {
    associatedtype T
    
    func create(_ object: T) -> Void
    func update(_ object: T) -> Void
    func delete(_ object: T) -> Void
}
