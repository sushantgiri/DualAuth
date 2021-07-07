//
//  VCPayload.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 24/06/2021.
//

import Foundation

public struct VCPayload: Codable,Hashable,Equatable {
    public  let exp: Double
    public let sub: String
    public let iss: String
    public let vc: VC
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(exp)
    }
    
    public static func ==(lhs: VCPayload, rhs: VCPayload) -> Bool {
        return lhs.exp == rhs.exp
    }
    
    private enum CodingKeys : String, CodingKey {
        case exp
        case sub
        case iss
        case vc
        
       }
  
    
    public struct VC: Codable {
        public  let context: Array<String>
        public let id: String
        public let type: Array<String>
        public let issuer: Issuer
        public let issuanceDate: String
        public let credentialSubject: CredentialSubject
        public let credentialStatus: CrendentialStatus
        
        private enum CodingKeys : String, CodingKey {
            case context = "@context"
            case id
            case type
            case issuer
            case issuanceDate
            case credentialSubject
            case credentialStatus
            
           }
        
    
    }
    
   public struct Issuer: Codable {
    public  let id: String
        private enum CodingKeys : String, CodingKey {
            case id
    
            
           }
    }
    
   public struct CredentialSubject: Codable {
    public  let birthday: String
    public   let gender: String
    public   let phone: String
    public    let name: String
    public    let email: String
    public    let address: String?
        
        private enum CodingKeys : String, CodingKey {
            case birthday
            case gender
            case phone
            case name
            case email
            case address
            
           }
        
    }
    
    public struct CrendentialStatus: Codable{
        public   let type: String
        private enum CodingKeys : String, CodingKey {
            case type
           }
    }
    
}

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

extension String {
    
    public func getFormattedDate() -> String{
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let date: Date? = dateFormatterGet.date(from: self)
        if let dateText = date {
            return dateFormatter.string(from: dateText)
        }
       return self
    }
    
   public  func dateFormatter() -> String {
            
      let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return  dateFormatter.string(from: date!)

            
    }
}

