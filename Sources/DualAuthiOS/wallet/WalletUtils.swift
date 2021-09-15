//
//  WalletUtils.swift
//  Smart ID Card
//
//  Created by Sushant Giri on 07/07/2021.
//

import Foundation

import Web3
import Web3PromiseKit
import Web3ContractABI
import CommonCrypto






public class WalletUtils {

    public var userMnemonics: String = ""
    public var userPrivateKey: String = ""
    public var userAddress: String  = ""
    public var dataKey: String =  ""
    public var userData: UserData = UserData()
    public var contract: DynamicContract?

    
    public init() {
        
        initializeContract()
        
    }
    
    func initializeContract(){
        do{

        let web3 = Web3(rpcURL: "http://182.162.89.51:4313")
            let contractAddress = try EthereumAddress(hex: "0x3CF0CB3cD457b959F6027676dF79200C8EF19907", eip55: true)
            if let url = Bundle.main.url(forResource: "abi", withExtension: "json") {
                let contractJsonABI = try Data(contentsOf: url)
                contract = try web3.eth.Contract(json: contractJsonABI, abiKey: nil, address: contractAddress)
            }
        }catch {
            print(error.localizedDescription)
        }

    }

//    func sha256(data : Data) -> Data {
//
//        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
//        }
//        return Data(hash)
//    }


    public func getRevokeCodeVC(vc: String, issuer: String, hash: Data, completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {

        let modifiedIssuer = issuer.replacingOccurrences(of: "did:dual:", with: "")

        firstly {
            contract!["GetRevokeCodeVC"]!(hash,modifiedIssuer).call()
        }.done { outputs in
            completionHandler(true, nil)
        }.catch { error in
            completionHandler(false,error)
        }
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
    public   let address: String
    public   let data: Data
    public   let name: String
    public   let isHD: Bool
    }

   public struct HDKey {
    public     let name: String?
    public    let address: String
    }
    
    public struct UserData: Codable {
        public    var userMnemonics: String = ""
        public    var userPrivateKey: String = ""
        public  var userAddress: String = ""
        public  var dataKey: String = ""
        public  var password: String = ""
        public  var cardList: Array<VCPayload>?
        public var vcJwtData: Array<String>?
        
    }
}



