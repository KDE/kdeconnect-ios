//
//  KeychainOperations.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-17.
//

import Foundation
import Security
//import OpenSSL
//import CommonCrypto

@objc class KeychainOperations: NSObject {
    //@objc static func P12CertificateToData(p12Cert: )
    
    @objc static func getIdentityFromKeychain() -> SecIdentity? {
        let keychainItemQuery: CFDictionary = [
            kSecClass: kSecClassIdentity,
            kSecAttrLabel: NetworkPackage.getUUID() as Any,
            kSecReturnRef: true
        ] as CFDictionary
        var identityApp: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(keychainItemQuery, &identityApp)
        print("getIdentityFromKeychain completed with \(status)")
        if (identityApp == nil) {
            return nil
        } else {
            return (identityApp as! SecIdentity)
        }
    }
    
    @objc static func addCertificateDataToKeychain(certData: Data) -> OSStatus {
        let keychainItemQuery: CFDictionary = [
            kSecValueData: certData,
            kSecAttrLabel: "kdeconnect.certificate",
            kSecClass: kSecClassCertificate,
        ] as CFDictionary
        return SecItemAdd(keychainItemQuery, nil)
    }
    
    @objc static func getCertificateDataFromKeychain() -> Data? {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: "kdeconnect.certificate",
            kSecClass: kSecClassCertificate,
            kSecReturnData: true
        ] as CFDictionary
        var result: AnyObject?
        let status: OSStatus = SecItemCopyMatching(keychainItemQuery, &result)
        print("getCertificateDataFromKeyChain completed with \(status)")
        return result as? Data
    }
    
    @objc static func updateCertificateDataInKeychain(newCertData: Data) -> OSStatus {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: "kdeconnect.certificate",
            kSecClass: kSecClassCertificate,
        ] as CFDictionary
        let updateItemQuery: CFDictionary = [
            kSecValueData: newCertData
        ] as CFDictionary
        return SecItemUpdate(keychainItemQuery, updateItemQuery)
    }
    
    @objc static func deleteCertificateDataFromKeychain() -> OSStatus {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: "kdeconnect.certificate",
            kSecClass: kSecClassCertificate,
        ] as CFDictionary
        return SecItemDelete(keychainItemQuery)
    }
}
