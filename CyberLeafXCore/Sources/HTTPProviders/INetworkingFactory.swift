//
//  INetworkingFactory.swift
//  CyberLeafXCore
//
//  Created by Dat T. on 10/12/19.
//

import Foundation

public protocol INetworkingFactory {
    func alamofireManager() -> IHTTPManager
    func afnetworkingManager() -> IHTTPManager
}
