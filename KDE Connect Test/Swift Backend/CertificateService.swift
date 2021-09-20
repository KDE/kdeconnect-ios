//
//  CertificateService.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-09-17.
//

import Foundation
import Security
import CryptoKit
//import OpenSSL
//import CommonCrypto

@objc class CertificateService: NSObject {
    @objc var hostIdentity: SecIdentity?
    @objc var hostCertificateSHA256HashFormattedString: String?
    
    override init() {
        super.init()
        hostIdentity = getHostIdentityFromKeychain()
        hostCertificateSHA256HashFormattedString = getHostSHA256HashFullyFormatted()
    }
    
    @objc func getHostSHA256HashFullyFormatted() -> String {
        return SHA256HashDividedAndFormatted(hashDescription: getHostCertificateSHA256HexDescriptionString())
    }
    
    @objc func getHostIdentityFromKeychain() -> SecIdentity? {
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
    @objc func getHostCertificateSHA256HexDescriptionString() -> String {
        if let hostIdentity: SecIdentity = hostIdentity {
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
    
    @objc func deleteAllItemsFromKeychain() -> Bool {
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
    @objc func SHA256HashDividedAndFormatted(hashDescription: String) -> String {
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
    
    @objc func deleteHostCertificateFromKeychain() -> OSStatus {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: NetworkPackage.getUUID() as Any,
            kSecClass: kSecClassIdentity,
        ] as CFDictionary
        return SecItemDelete(keychainItemQuery)
    }
    
    @objc func verifyCertificateEqualityFromRemoteDeviceWithDeviceID(trust: SecTrust, deviceId: String) -> Bool {
        return true
    }
    
    @objc func verifyCertificateEqualityFromRemoteDevice(trust: SecTrust) -> Bool {
        return true
    }


    // Unused and reference functions
//    @objc static func verifyRemoteCertificate(trust: SecTrust) -> Bool {
//
//        // Debug code
//        let numOfCerts: NSInteger = SecTrustGetCertificateCount(trust);
//        print("\(numOfCerts) certs in trust received from remote device")
//        for i in 0..<numOfCerts {
//            let secCert: SecCertificate = SecTrustGetCertificateAtIndex(trust, i)!
//            var commonName: CFString? = nil
//            SecCertificateCopyCommonName(secCert, &commonName)
//            print("Common Name is: \(String(describing: commonName))")
//
//            var email: CFArray? = nil
//            SecCertificateCopyEmailAddresses(secCert, &email)
//            print("Email is: \(String(describing: email))")
//
//            print("Cert summary is: \(String(describing: SecCertificateCopySubjectSummary(secCert)))")
//
//            print("Key is: \(String(describing: SecCertificateCopyKey(secCert)))")
//        }
//
//
//        let basicX509Policy: SecPolicy = SecPolicyCreateBasicX509()
//        let secTrustSetPolicyStatus: OSStatus = SecTrustSetPolicies(trust, basicX509Policy)
//        if (secTrustSetPolicyStatus != 0) {
//            print("Failed to set basic X509 policy for trust")
//            return false
//        }
//
//        //SecTrustSetAnchorCertificates(trust, CFArray of certs)
//        // do we need to fetch these?????
////        if let hostCert: SecCertificate = getHostCertificateFromKeychain() {
////            let certArray: CFArray = [hostCert] as CFArray
////            let status: OSStatus = SecTrustSetAnchorCertificates(trust, certArray)
////            print("SecTrustSetAnchorCertificates completed with code \(status)")
////        } else {
////            print("wtf")
////        }
//
//        var evalError: CFError? = nil
//        let status: Bool = SecTrustEvaluateWithError(trust, &evalError) // this returns Bool, NOT OSStatus!!
//        if status {
//            print("SecTrustEvaluateWithError succeeded")
//        } else {
//            // If failed then we check if new device or middle attack? Or do we check for new device first? (latter is probably safer)
//            print("SecTrustEvaluateWithError failed with error: \(String(describing: evalError?.localizedDescription))")
//        }
//
//        print("Properties after evaluation are: \(String(describing: SecTrustCopyProperties(trust)))")
//
//        return status
//    }
    
//    @objc static func getHostCertificateFromKeychain() -> SecCertificate? {
//        if let hostIdentity: SecIdentity = getHostIdentityFromKeychain() {
//            var hostCert: SecCertificate? = nil
//            let status: OSStatus = SecIdentityCopyCertificate(hostIdentity, &hostCert)
//            print("SecIdentityCopyCertificate completed with \(status)")
//            if (hostCert != nil) {
//                return hostCert
//            } else {
//                print("Unable to get host certificate")
//                return nil
//            }
//        } else {
//            print("Unable to get host Identity")
//            return nil
//        }
//    }
    
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
