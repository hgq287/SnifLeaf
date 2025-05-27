//
//  NetworkingFactory.swift
//  CyberLeafXCore
//
//  Created by Dat T. on 10/15/19.
//

import Foundation

open class NetworkingFactory: INetworkingFactory {
    
    public init() {
        print("Initialize \(self)")
    }
    
    public func alamofireManager() -> IHTTPManager {
        return AlamofireManager()
    }
    
    public func afnetworkingManager() -> IHTTPManager {
        return AFNetworkingManager()
    }
    
}
