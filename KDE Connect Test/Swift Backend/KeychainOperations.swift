//
//  KeychainOperations.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-17.
//

import Foundation
import Security
import CryptoKit
//import OpenSSL
//import CommonCrypto

@objc class KeychainOperations: NSObject {
    
    @objc static func getHostSHA256HashFullyFormatted() -> String {
        return SHA256HashDividedAndFormatted(hashDescription: getHostCertificateSHA256HexDescriptionString())
    }
    
    @objc static func getHostIdentityFromKeychain() -> SecIdentity? {
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
    
    // Run the description given by this func through SHA256HashDividedAndFormatted() to have it fromatted in xx:yy:zz:ww:ee HEX format
    @objc static func getHostCertificateSHA256HexDescriptionString() -> String {
        if let hostIdentity: SecIdentity = getHostIdentityFromKeychain() {
            var secCert: SecCertificate? = nil
            let status: OSStatus = SecIdentityCopyCertificate(hostIdentity, &secCert)
            print("SecIdentityCopyCertificate completed with \(status)")
            if (secCert != nil) {
                return SHA256.hash(data: SecCertificateCopyData(secCert!) as Data).description
            } else {
                return "ERROR getting SHA256 from host's certificate"
            }
        } else {
            return "ERROR getting SHA256 from host's certificate"
        }
    }
    
    @objc static func deleteHostCertificateFromKeychain() -> OSStatus {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: NetworkPackage.getUUID() as Any,
            kSecClass: kSecClassIdentity,
        ] as CFDictionary
        return SecItemDelete(keychainItemQuery)
    }
    
    @objc static func deleteAllItemsFromKeychain() -> Bool {
        let allSecItemClasses: [CFString] = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in allSecItemClasses {
            let keychainItemQuery: CFDictionary = [kSecClass: itemClass] as CFDictionary
            let status: OSStatus = SecItemDelete(keychainItemQuery)
            if (status != 0) {
                return false
            }
        }
        return true
    }
    
    // Given a standard, no-space SHA256 hash, insert : dividers every 2 characters
    // It isn't terribly efficient to convert Subtring to String like this but it works?
    @objc static func SHA256HashDividedAndFormatted(hashDescription: String) -> String {
        // hashDescription looks like: "SHA256 digest: xxxxxxyyyyyyssssssyyyysysss", so the third element of the split separated by " " is just the hash string
        var justTheHashString: String = (hashDescription.components(separatedBy: " "))[2]
        var arrayOf2CharStrings: [String] = []
        while (!justTheHashString.isEmpty) {
            let firstString: String = String(justTheHashString.first!)
            justTheHashString.removeFirst()
            var secondString: String = ""
            if (!justTheHashString.isEmpty) {
                secondString = String(justTheHashString.first!)
                justTheHashString.removeFirst()
            }
            arrayOf2CharStrings.append(firstString + secondString)
        }
        return arrayOf2CharStrings.joined(separator: ":")
    }
    
    @objc static func verifyRemoteCertificate(trust: SecTrust) -> Void {
        //SecTrustSetAnchorCertificates(trust, CFArray of certs)
        // do we need to fetch these?????
        
        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(trust, DispatchQueue.global()) { trust, result, error in
                if result {
                    // get remote device's public key??????
                } else {
                    print("Remote certificate verification failed with \(error!.localizedDescription)")
                }
            }
        }
    }
    
//    @objc static func addCertificateDataToKeychain(certData: Data) -> OSStatus {
//        let keychainItemQuery: CFDictionary = [
//            kSecValueData: certData,
//            kSecAttrLabel: "kdeconnect.certificate",
//            kSecClass: kSecClassCertificate,
//        ] as CFDictionary
//        return SecItemAdd(keychainItemQuery, nil)
//    }
//
//    @objc static func getCertificateDataFromKeychain() -> Data? {
//        let keychainItemQuery: CFDictionary = [
//            kSecAttrLabel: "kdeconnect.certificate",
//            kSecClass: kSecClassCertificate,
//            kSecReturnData: true
//        ] as CFDictionary
//        var result: AnyObject?
//        let status: OSStatus = SecItemCopyMatching(keychainItemQuery, &result)
//        print("getCertificateDataFromKeyChain completed with \(status)")
//        return result as? Data
//    }
//
//    @objc static func updateCertificateDataInKeychain(newCertData: Data) -> OSStatus {
//        let keychainItemQuery: CFDictionary = [
//            kSecAttrLabel: "kdeconnect.certificate",
//            kSecClass: kSecClassCertificate,
//        ] as CFDictionary
//        let updateItemQuery: CFDictionary = [
//            kSecValueData: newCertData
//        ] as CFDictionary
//        return SecItemUpdate(keychainItemQuery, updateItemQuery)
//    }
//
}
