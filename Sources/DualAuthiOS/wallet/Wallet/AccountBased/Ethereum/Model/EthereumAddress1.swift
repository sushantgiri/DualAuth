//
//  File.swift
//  
//
//  Created by Sushant Giri on 14/09/2021.
//

import Foundation

public struct EthereumAddress1: Codable {
    
    /// Address in data format
    public let data: Data
    
    /// Address in string format, EIP55 encoded
    public let string: String
    
    public init(data: Data, string: String) {
        self.data = data
        self.string = string
    }
    
    public init(data: Data) {
        self.data = data
        self.string = "0x" + EIP55.encode(data)
    }
    
    public init(string: String) {
        self.data = Data(hex: string.stripHexPrefix())
        self.string = string
    }
}
