//
//  WalletUtils.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 07/07/2021.
//

import Foundation




public class WalletUtils {
    private var userMnemonics: String = ""
    private var userPrivateKey: String = ""
    private var userAddress: String  = ""
    private var dataKey: String =  ""
    private var userData: UserData = UserData()
    
    init() {
    }
    
   public  func did(password: String, completionHandler: @escaping (_ payload: UserData?, _ error: Error?) -> Void){
        address()

        let dualDID = DualDID(privateKey: userPrivateKey.replacingOccurrences(of: "0x", with: ""), userAddress:userAddress, serviceEndPoint: "Dualauth.com(change later)")
        
        dualDID.createDID { jwtToken in
            print("JWT Token \(jwtToken)")
            dualDID.verifyDID(token: jwtToken) { (payload, error) in
                if(error != nil) {
                    completionHandler(nil, error)
                }
                self.userData = UserData(userMnemonics: self.userMnemonics, userPrivateKey: self.userPrivateKey,
                                        userAddress: self.userAddress,
                                        dataKey: self.dataKey,
                                        password: password);
                completionHandler(self.userData, nil)
                
                
            }
        }
        
        
    }
    
   public func createVP(jcwtArray: [String], userData: UserData, nonce: String, completionHandler: @escaping (_ jwt: String) -> Void) {
        let dualDID = DualDID(privateKey: userData.userPrivateKey.replacingOccurrences(of: "0x", with: ""), userAddress:userData.userAddress, serviceEndPoint: "Dualauth.com(change later)")
        dualDID.createVP(vcJwtArray: jcwtArray, nonce: nonce) { jwt in
            completionHandler(jwt)
        }

    }
    
    public func getUserData() -> UserData {
        return userData
    }
    
    func generateRandomBytes(count: Int) -> String? {

        var keyData = Data(count: count)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData.base64EncodedString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    private func address(){
        let entropy = Data.randomBytes(length: 32)
        let mnemonic = Mnemonic.create(entropy: entropy)
        userMnemonics = mnemonic
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let privateKey = PrivateKey(seed: seed, coin: .ethereum)

        // BIP44 key derivation
        // m/44'
        let purpose = privateKey.derived(at: .hardened(44))

        // m/44'/60'
        let coinType = purpose.derived(at: .hardened(60))

        // m/44'/60'/0'
        let account = coinType.derived(at: .hardened(0))

        // m/44'/60'/0'/0
        let change = account.derived(at: .notHardened(0))

        // m/44'/60'/0'/0/0
        let firstPrivateKey = change.derived(at: .notHardened(0))
        
        
        let firstPrivateKeyString = firstPrivateKey.get().addHexPrefix()
        userPrivateKey = firstPrivateKeyString
        
        userAddress = "did:dual:\(firstPrivateKey.publicKey.address.lowercased())"
        print("Private Key \(firstPrivateKeyString)")
        print("Address: \(firstPrivateKey.publicKey.address)")
        
         dataKey = Data.randomBytes(length: 16).toHexString()
        
    }
    


   public struct Wallet {
        let address: String
        let data: Data
        let name: String
        let isHD: Bool
    }

   public struct HDKey {
        let name: String?
        let address: String
    }
    
    public struct UserData: Codable {
         var userMnemonics: String = ""
         var userPrivateKey: String = ""
         var userAddress: String = ""
         var dataKey: String = ""
         var password: String = ""
         var cardList: Array<VCPayload>?
        var vcJwtData: Array<String>?
        
    }
}



