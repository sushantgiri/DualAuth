//
//  DualDID.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 21/06/2021.
//

import Foundation

struct DualDID {
    
    let privateKey: String
    let userAddress: String
    let serviceEndPoint: String
    private let cryptoUtils: CryptoUtils
    
    
    
    init(privateKey: String, userAddress: String, serviceEndPoint: String){
         self.privateKey = privateKey
         self.userAddress = userAddress;
        self.serviceEndPoint = serviceEndPoint
        
         
         cryptoUtils = CryptoUtils()
         
     }
    
    private func getDID() -> String {
        "did:dual:\(self.userAddress)".lowercased()
    }
    
    
    
    func createDID(completionHandler: @escaping (_ jwt: String) -> Void){
        let header = Header(alg: "ES256K-R", typ: "JWT")
        let value =  String(Int(floor(Date().toMilliseconds()/1000.0)))
        let payload = Payload(aud: userAddress, name: "estorem did",iss: userAddress,iat: value)
        let jwt = cryptoUtils.createJWT(secret: privateKey, payload: payload, header: header)
        completionHandler(jwt)
    }
    
    func verifyDID(token: String, completionHandler: @escaping (_ payload: Payload?, _ error: Error?) -> Void) {
        cryptoUtils.verifyJWT(token: token, secret: privateKey, serviceEndpoint:serviceEndPoint, completionHandler: completionHandler)
    }
    
    func createVP(vcJwtArray: [String], nonce: String, completionHandler: @escaping (_ jwt: String) -> Void){
        let header = Header(alg: "ES256K", typ: "JWT")
        let vp = VerifiableCredentialPayload.VPPayload(context: ["https://www.w3.org/2018/credentials/v1"], type: ["VerifiablePresentation"], verifiableCredential: vcJwtArray)
        let payload = VerifiableCredentialPayload(vp: vp, nonce: nonce, iss: userAddress)
        let  jwt = cryptoUtils.createVP(secret: privateKey, payload: payload, header: header)
        completionHandler(jwt)
    }
}

extension Date {
    
    func toMilliseconds() -> Double {
        Double(self.timeIntervalSince1970 * 1000)
    }

    init(milliseconds:Int) {
        if #available(macOS 10.15, *) {
            self = Date().advanced(by: TimeInterval(integerLiteral: Int64(milliseconds / 1000)))
        } else {
            self = Date()
            // Fallback on earlier versions
        }
    }
}
