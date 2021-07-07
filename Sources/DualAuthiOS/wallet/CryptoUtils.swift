//
//  CryptoUtils.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 21/06/2021.
//

import Foundation

import CryptoKit
import Security





public enum JWTError: Error
{
    case notValidIssuedInFuture
    case notValidPastExpiryDate
    case malformedNotThreeParts
    case malformedEmptyHeader
    case malformedEmptyPayload
    case malformedEmptySignature
    case malformedNotBase64Url
    case malformedNotBase64
    case malformedNotUtf8
    case malformedNotDictionary
    case deserializationError(String)
    case invalidSignatureSize(Int)
    case failedToVerify
    case missingDidDocument
}

extension Data {
    func urlSafeBase64EncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func signatureSafeBase64EncodedString() -> String {
        var base64 = self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
       
        return base64
    }
}

extension String {
    
    private func base64Auth() -> String {
        var base64 = self
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        return base64
    }
    
    private func base64urlToBase64() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    func base64urlToData() -> Data? {
        Data(base64Encoded: base64urlToBase64())
    }
    
}

struct Header: Codable {
    var alg:String
    var typ: String
    
}

struct Payload: Codable {
    var aud: String
    var name: String
    var iss: String
    var iat: String
}

struct VerifiableCredentialPayload: Codable{
   
    var vp: VPPayload
    var nonce: String
    var iss: String
    
    private enum CodingKeys : String, CodingKey {
        case vp
        case nonce
        case iss
       }
    
    
    struct VPPayload : Codable{
        var context: [String]
        var type: [String]
        var verifiableCredential: [String]
        
        private enum CodingKeys : String, CodingKey {
            case context = "@context"
            case type
            case verifiableCredential
           }
    }
    
}

struct CryptoUtils{
    
    init(){
        
    }
    
    func base64urlToBase64(base64url: String) -> String {
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
func createJWT(secret: String, payload: Payload, header: Header) -> String {
    if #available(macOS 10.15, *) {
        let privateKey = CryptoKit.SymmetricKey(data: secret.data(using: .utf8)!)
        
        let headerJSONData = try! JSONEncoder().encode(header)
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()

        let payloadJSONData = try! JSONEncoder().encode(payload)
        let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()

        let toSign = (headerBase64String + "." + payloadBase64String).data(using: .utf8)!
        
        let signature = HMAC<CryptoKit.SHA256>.authenticationCode(for: toSign, using: privateKey)
        
        let signatureBase64String = Data(signature).urlSafeBase64EncodedString()

        let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
        print("Token is: \(token)")
        return token
    } else {
        // Fallback on earlier versions
        return ""
    }
    
    
    
    

   
}
    
 
    
    func createVP(secret: String, payload: VerifiableCredentialPayload, header: Header) -> String {
        
        do {
        let jsonData = try JSONEncoder().encode(payload)
            let payloadJSON = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
            let payLoadDictionary = CryptoUtils.convertStringToDictionary(text: payloadJSON as String)

            let jwt =  OpenJsonTokenJs().signToken(payload: payLoadDictionary!, privateKey: secret, algorithm: "ES256K")
            return jwt!
        }catch{
            print(error)
            return ""
        }
    }
    
    private static func convertStringToDictionary(text: String) -> [String:AnyObject]? {
       if let data = text.data(using: .utf8) {
           do {
               let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
               return json
           } catch {
               print("Something went wrong")
           }
       }
       return nil
   }
    
    
    
    func decodeJWT(token: String, secret: String)throws -> (Header, Payload, Data, Data)?{
        if #available(macOS 10.15, *) {
            let privateKey = CryptoKit.SymmetricKey(data: secret.data(using: .utf8)!)
            let jwtTokenArray = token.components(separatedBy: ".")
            
            let headerBase64String = jwtTokenArray[0]
            let header = try! JSONDecoder().decode(Header.self, from: headerBase64String.base64urlToData()!)
            
            let payloadBase64String = jwtTokenArray[1]
            let payload = try! JSONDecoder().decode(Payload.self, from: payloadBase64String.base64urlToData()!)
            let signatureBase64String = jwtTokenArray[2]
            
            let authenticating = (headerBase64String + "." + payloadBase64String).data(using: .utf8)!

            if let signature = signatureBase64String.base64urlToData() {
                if #available(iOS 13.2, *){
                    let isValid = HMAC<CryptoKit.SHA256>.isValidAuthenticationCode(signature, authenticating: authenticating, using: privateKey);
                    if isValid {
                        return (header, payload, signature, authenticating)
                    }
                }else{
                    return nil
                }
                
               
            }
            return nil
        } else {
            // Fallback on earlier versions
            return nil
        }
    

        
        
    }
    
    func decodeJWTPayload(token: String) -> VCPayload {
        let jwtTokenArray = token.components(separatedBy: ".")
        let payloadBase64String = jwtTokenArray[1]
        return try! JSONDecoder().decode(VCPayload.self, from: payloadBase64String.base64urlToData()!)
        
    }
    
 
    func verifyJWT(token: String, secret: String, serviceEndpoint: String, completionHandler: @escaping (_ payload: Payload?, _ error: Error?) -> Void){
        do {
            if let (_,payload,_,_)  = try decodeJWT(token: token, secret: secret){
                
                var resolver = UniversalDIDResolver()
                let dualDIDResolver = DualDIDResolver(issuer: payload.iss.replacingOccurrences(of: "did:dual:", with: ""), serviceEndPoint: serviceEndpoint)
                try! resolver.register(resolver: dualDIDResolver)

                
                resolver.resolveAsync(did: payload.iss)
                { (document, error) in
                    guard error == nil else
                    {
                        completionHandler(nil, error)
                        return
                    }

                    guard let document = document else
                    {
                        completionHandler(nil, JWTError.missingDidDocument)
                        return
                    }
                    
                    print(document)
                    completionHandler(payload, nil)
                }
            }else{
                completionHandler(nil, JWTError.notValidIssuedInFuture)
            }
        }catch {
            print(error)
            completionHandler(nil, error)
        }
       
        
    }
      
    
}


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}





extension String {
    /// Expanded encoding
    ///
    /// - bytesHexLiteral: Hex string of bytes
    /// - base64: Base64 string
    enum ExpandedEncoding {
        /// Hex string of bytes
        case bytesHexLiteral
        /// Base64 string
        case base64
    }

    /// Convert to `Data` with expanded encoding
    ///
    /// - Parameter encoding: Expanded encoding
    /// - Returns: data
    func data(using encoding: ExpandedEncoding) -> Data? {
        switch encoding {
        case .bytesHexLiteral:
            guard self.count % 2 == 0 else { return nil }
            var data = Data()
            var byteLiteral = ""
            for (index, character) in self.enumerated() {
                if index % 2 == 0 {
                    byteLiteral = String(character)
                } else {
                    byteLiteral.append(character)
                    guard let byte = UInt8(byteLiteral, radix: 16) else { return nil }
                    data.append(byte)
                }
            }
            return data
        case .base64:
            return Data(base64Encoded: self)
        }
    }
}



