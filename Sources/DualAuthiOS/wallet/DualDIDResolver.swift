//
//  DualDIDResolver.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 21/06/2021.
//

import Foundation

public enum DualDIDResolverError: Error {

case invalidIdentity
case invalidRPCResponse
case invalidRegexResult
case invalidDelegateType
case invalidServiceEndpoint
}

public struct DualDIDResolver: DIDResolver {

    
    let issuer: String
    let serviceEndPoint: String

    public init(issuer: String, serviceEndPoint: String)
    {
        self.issuer = issuer
        self.serviceEndPoint = serviceEndPoint
    }

    // MARK: - Resolver Implementation

    public var method: String
    {
        return "dual"
    }

    public func canResolve(did: String) -> Bool
    {
        return !NormalizedEthrDID(didCandidate: did).value.isEmpty
    }

    public func resolveSync(did: String) throws -> DIDDocument
    {
        let normalizedDidObject = NormalizedEthrDID(didCandidate: did)
        guard normalizedDidObject.error == nil else
        {
            throw normalizedDidObject.error!
        }
                
        
        var ddo: DIDDocument?
        do
        {
            ddo = try self.wrapDidDocument(normalizedDid: normalizedDidObject.value, owner: issuer, serviceEndPoint: serviceEndPoint)
        }
        catch
        {
            throw error
        }
    
        return ddo!
    }
    
    
    func wrapDidDocument(normalizedDid: String, owner: String, serviceEndPoint: String) throws -> DIDDocument
    {
        
        let owner = PublicKeyEntry(id: "\(normalizedDid)#controller",
                                   type: .Secp256k1VerificationKey2018,
                                   owner: normalizedDid,
                                   ethereumAddress: owner)
        let pkEntries = ["owner": owner]
        
        let serviceEntry = ServiceEntry(type: "estorm", serviceEndpoint: "\(serviceEndPoint)/\(normalizedDid)")
        let serviceEntries = ["service": serviceEntry]
        
        return DIDDocument(id: normalizedDid,
                           publicKey: Array(pkEntries.values),
                           service: Array(serviceEntries.values))
    }
    
    

    
    
}
