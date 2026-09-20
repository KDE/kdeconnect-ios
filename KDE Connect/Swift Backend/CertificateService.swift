/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import Foundation
import Security
import CryptoKit

@objc class CertificateService: NSObject {
    // Certificate Service provider, to be used for all certificate and Keychain operations
    @objc static let shared: CertificateService = CertificateService()
    
    @objc let hostIdentity: SecIdentity
    private let logger = Logger()
    
    override init() {
        hostIdentity = Self.loadIdentityFromKeychain()
        super.init()
    }
    
    static func loadIdentityFromKeychain() -> SecIdentity {
        // ref: https://developer.apple.com/documentation/network/creating_an_identity_for_local_network_tls
#if !os(macOS)
        let keychainItemQuery: CFDictionary = [
            kSecClass: kSecClassIdentity,
            kSecAttrLabel: KdeConnectSettings.getUUID() as Any,
            kSecReturnRef: true,
        ] as CFDictionary
        var identityApp: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(keychainItemQuery, &identityApp)
        Logger().info("getIdentityFromKeychain completed with \(status)")
#else
        var identityApp: SecIdentity? = nil
        let getquery = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: KdeConnectSettings.getUUID() as Any,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ] as NSDictionary
        var item: CFTypeRef?
        func macFetchIdentity() {
            // normally will print error -25300 at the first launch as there is no identity
            let status = SecItemCopyMatching(getquery as CFDictionary, &item)
            guard status == errSecSuccess else {
                print("getHostIdentityFromKeychain status failed with \(status)")
                return
            }
            print("loadIdentityFromKeychain status failed with \(status)")
            let certificate = item as! SecCertificate
            let identityStatus = SecIdentityCreateWithCertificate(nil, certificate, &identityApp)
            guard identityStatus == errSecSuccess else {
                print("loadIdentityFromKeychain identityStatus failed with \(identityStatus)")
                return
            }
        }
        macFetchIdentity()
#endif
        if (identityApp == nil) {
            Logger().info("generateSecIdentity")
#if !os(macOS)
            if generateSecIdentityForUUID(KdeConnectSettings.getUUID()) == noErr {
                SecItemCopyMatching(keychainItemQuery, &identityApp)
            }
#else
            // remove old identity on macOS
            // normally will print error -25300 at the first launch as there is no identity
            deleteHostCertificateFromKeychain()
            if (generateSecIdentityForUUID(KdeConnectSettings.getUUID()) == noErr) {
                // Refetch
                macFetchIdentity()
            }
#endif
        }
        return (identityApp as! SecIdentity)
    }
    
    func getHostCertificate() -> SecCertificate {
        var secCert: SecCertificate? = nil
        let status: OSStatus = SecIdentityCopyCertificate(hostIdentity, &secCert)
        if (status != 0) {
            logger.info("SecIdentityCopyCertificate completed with \(status)")
        }
        return secCert!
    }
    
    func getHostCertificateSHA256HashFormattedString() -> String {
        return Self.getCertHash(cert: getHostCertificate())
    }
    
    func getRemoteCertificateSHA256HashFormattedString(deviceId: String) -> String {
        let cert = backgroundService._devices[deviceId]!._deviceInfo.cert
        return Self.getCertHash(cert: cert)
    }
    
    static func getCertHash(cert: SecCertificate) -> String {
        let certData = SecCertificateCopyData(cert) as Data
        let certHash = SHA256.hash(data: certData)
        return sha256AsStringWithDividers(hash: certHash)
    }
    
    func getVerificationKey(deviceId: String) -> String {
        let device = backgroundService.devices[deviceId]!
    
        let remoteCert = device._deviceInfo.cert
        let remoteData = getPublicKeyDERFromCertificate(remoteCert)!
        
        let localCert = getHostCertificate()
        let localData = getPublicKeyDERFromCertificate(localCert)!
        
        var combinedData = if (remoteData.lexicographicallyPrecedes(localData)) {
            localData + remoteData
        } else {
            remoteData + localData
        }

        if (device._deviceInfo.protocolVersion >= 8) {
            combinedData += String(device._pairingTimestamp).utf8
        }
        
        return Self.sha256AsString(hash: SHA256.hash(data: combinedData)).prefix(8).uppercased()
    }
    
    static func dataToHexString(data: Data) -> String {
        let hexString = NSMutableString(capacity: data.count*2)
        data.forEach { byte in
            hexString.appendFormat("%02x", byte)
        }
        return hexString as String
    }

    static func sha256AsString(hash: SHA256.Digest) -> String {
        // hash description looks like: "SHA256 digest: xxxxxxyyyyyyssssssyyyysysss", so the third element of the split separated by " " is just the hash string
        return (hash.description.components(separatedBy: " "))[2]
    }
    
    // Given a standard, no-space SHA256 hash, insert : dividers every 2 characters
    static func sha256AsStringWithDividers(hash: SHA256.Digest) -> String {
        var justTheHashString = sha256AsString(hash: hash)
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
    
    // @discardableResult
    @objc static func deleteHostCertificateFromKeychain() -> OSStatus {
#if !os(macOS)
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: KdeConnectSettings.getUUID() as Any,
            kSecClass: kSecClassIdentity,
        ] as CFDictionary
        return SecItemDelete(keychainItemQuery)
#else
        let deleteCertQuery: NSDictionary = [
            kSecAttrLabel: KdeConnectSettings.getUUID() as Any,
            kSecClass: kSecClassCertificate,
        ] as NSDictionary
        let deleteCertStatus = SecItemDelete(deleteCertQuery)
        guard deleteCertStatus == errSecSuccess else {
            print("deleteHostCertificateFromKeychain deleteCert failed with status \(deleteCertStatus)")
            return deleteCertStatus
        }
        let deleteKeyQuery: NSDictionary = [
            kSecAttrLabel: "KDE Connect" as Any,
            kSecClass: kSecClassKey,
        ] as NSDictionary
        let deleteKeyStatus = SecItemDelete(deleteKeyQuery)
        guard deleteKeyStatus == errSecSuccess else {
            print("deleteHostCertificateFromKeychain deleteKey failed with status \(deleteKeyStatus)")
            return deleteKeyStatus
        }
        return errSecSuccess
#endif
    }
    
    // This function is called by LanLink and LanLinkProvider's didReceiveTrust
    @objc func verifyCertificateEquality(trust: SecTrust, fromRemoteDeviceWithDeviceID deviceId: String) -> Bool {
        if let remoteCert: SecCertificate = extractRemoteCertFromTrust(trust: trust) {
            if let storedRemoteCert: SecCertificate = extractSavedCertOfRemoteDevice(deviceId: deviceId) {
                logger.debug("Both remote cert and stored cert exist, checking them for equality")
                if ((SecCertificateCopyData(remoteCert) as Data) == (SecCertificateCopyData(storedRemoteCert) as Data)) {
                    return true
                } else {
                    logger.error("reject remote device for having a different certificate from the stored certificate")
                    return false
                }
            } else {
                logger.debug("remote cert exists, but nothing stored, setting up for new remote device")
                return true
            }
        } else {
            logger.fault("Unable to extract remote certificate")
            return false
        }
    }
    
    @objc func extractRemoteCertFromTrust(trust: SecTrust) -> SecCertificate? {
        let numOfCerts: Int = SecTrustGetCertificateCount(trust)
        if (numOfCerts != 1) {
            logger.error("Number of cert received \(numOfCerts) != 1, something is wrong about the remote device")
            return nil
        }
        if #available(iOS 15.0, *) {
            let certificateChain: [SecCertificate]? = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
            if (certificateChain != nil) {
                return certificateChain!.first
            } else {
                logger.fault("Unable to get certificate chain")
                return nil
            }
        } else {
            // Fallback on earlier versions
            let certificateChain = SecTrustGetCertificateAtIndex(trust, 0)
            // FIXME: Certificate list can be not large enough
            return certificateChain
        }
    }
    
    @objc func extractSavedCertOfRemoteDevice(deviceId: String) -> SecCertificate? {
        let keychainItemQuery: CFDictionary = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: deviceId as Any,
            kSecReturnRef: true,
        ] as CFDictionary
        var remoteSavedCert: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(keychainItemQuery, &remoteSavedCert)
        logger.info("extractSavedCertOfRemoteDevice completed with \(status)")
        return (remoteSavedCert as! SecCertificate?)
    }
    
    @objc func saveRemoteDeviceCertToKeychain(cert: SecCertificate, deviceId: String) -> Bool {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: deviceId as Any,
            kSecClass: kSecClassCertificate,
            kSecValueRef: cert,
        ] as CFDictionary
        let status: OSStatus = SecItemAdd(keychainItemQuery, nil)
        return (status == 0)
    }
    
    @objc func deleteRemoteDeviceSavedCert(deviceId: String) -> Bool {
        let keychainItemQuery: CFDictionary = [
            kSecAttrLabel: deviceId as Any,
            kSecClass: kSecClassCertificate,
        ] as CFDictionary
        // NOTE: cannot remove from tempRemoteCerts
        return (SecItemDelete(keychainItemQuery) == 0)
    }
    
    @objc func deleteAllItemsFromKeychain() -> Bool {
#if !os(macOS)
        let allSecItemClasses: [CFString] = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in allSecItemClasses {
            let keychainItemQuery: CFDictionary = [kSecClass: itemClass] as CFDictionary
            let status: OSStatus = SecItemDelete(keychainItemQuery)
            if (status != errSecSuccess) {
                print("Failed to remove 1 certificate in \(itemClass) keychain with error code \(status), continuing to attempt to remove all")
            }
        }
#else
        print("deleteAllItemsFromKeychain - host cert")
        let deleteHostCertificateFromKeychainStatus = Self.deleteHostCertificateFromKeychain()
        if deleteHostCertificateFromKeychainStatus != errSecSuccess {
            print("deleteAllItemsFromKeychain failed to remove host cert with status \(deleteHostCertificateFromKeychainStatus)")
        }
        print("deleteAllItemsFromKeychain - other certs")
        let getCertsQuery: NSDictionary = [
            kSecClass: kSecClassCertificate,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitAll,
        ] as NSDictionary
        var certs: AnyObject? = nil
        let getCertsQueryStatus: OSStatus = SecItemCopyMatching(getCertsQuery, &certs)
        guard getCertsQueryStatus == errSecSuccess else {
            print("deleteAllItemsFromKeychain getCertsQueryStatus failed with status \(getCertsQueryStatus)")
            return (getCertsQueryStatus != 0)
        }
        let numCerts = (certs as! NSArray).count
        for certIndex in 0...(numCerts - 1) {
            let cert: SecCertificate = (certs as! NSArray)[certIndex] as! SecCertificate
            let digest: String = extractSecCertificateDigest(cert)
            if (digest.contains("/OU=Kde connect") && digest.contains("/O=KDE")) {
                print("deleteAllItemsFromKeychain to remove cert with digest \(digest)")
                let removeCertQuery: NSDictionary = [
                    kSecClass: kSecClassCertificate,
                    kSecValueRef: cert,
                    kSecMatchLimit: kSecMatchLimitOne,
                ] as NSDictionary
                let removeCertQueryStatus: OSStatus = SecItemDelete(removeCertQuery)
                if removeCertQueryStatus != errSecSuccess {
                    print("deleteAllItemsFromKeychain failed to remove this cert with status \(removeCertQueryStatus)")
                }
            }
        }
        print("deleteAllItemsFromKeychain - UUID")
        let removeUUIDQuery: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrLabel: "kdeconnect-uuid",
        ] as NSDictionary
        let removeUUIDQueryStatus: OSStatus = SecItemDelete(removeUUIDQuery)
        if removeUUIDQueryStatus != errSecSuccess {
            print("deleteAllItemsFromKeychain failed to remove UUID with status \(removeUUIDQueryStatus)")
        }
#endif
        return (errSecSuccess != 0)
    }

    // FIXME: the temp remote cert functions are here because I dind't find a way to do this from Objective-C inside LanLink.
    var tempRemoteCerts: [String: SecCertificate] = [:]

    @objc func storeTempRemoteCert(fromTrust: SecTrust, deviceId: String) {
        let remoteCert: SecCertificate = extractRemoteCertFromTrust(trust: fromTrust)!
        tempRemoteCerts[deviceId] = remoteCert
    }

    @objc func getTempRemoteCert(deviceId: String) -> SecCertificate {
        return tempRemoteCerts[deviceId]!
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
