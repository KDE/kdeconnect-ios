/*
 * SPDX-FileCopyrightText: 2021 Weixuan Xiao <veyx.shaw@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#import <Foundation/Foundation.h>

#import <Security/Security.h>
#import <Security/SecItem.h>
#import <Security/SecTrust.h>
#import <Security/CipherSuite.h>
#import <Security/SecIdentity.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/x509.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>

#import "KDE_Connect-Swift.h"

@import os.log;

NSString* getSslError(void) {
    char buf[256];
    ERR_error_string_n(ERR_get_error(), buf, sizeof(buf));
    return [NSString stringWithUTF8String:buf];
}

OSStatus generateSecIdentityForUUID(NSString *uuid)
{
    os_log_t logger = os_log_create([NSString kdeConnectOSLogSubsystem].UTF8String,
                                    "CertificateService");
    
    // Force to remove the old identity, otherwise the new identity cannot be stored
    NSDictionary *spec = @{(__bridge id)kSecClass: (id)kSecClassIdentity};
    SecItemDelete((__bridge CFDictionaryRef)spec);


    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (!pctx) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Generate EC Private Key failed to allocate context");
        return errSecAllocate;
    }
    
    if (EVP_PKEY_keygen_init(pctx) <= 0) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Generate EC Private Key failed to initialize context");
        EVP_PKEY_CTX_free(pctx);
        return errSecParam;
    }
    
    if (EVP_PKEY_CTX_set_ec_paramgen_curve_nid(pctx, NID_X9_62_prime256v1) <= 0) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Generate EC Private Key failed to set curve");
        EVP_PKEY_CTX_free(pctx);
        return errSecParam;
    }

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (!pkey) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Generate EC Private Key failed to allocate private key");
        return errSecAllocate;
    }

    if (EVP_PKEY_keygen(pctx, &pkey) <= 0) {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Generate EC Private Key failed to generate private key");
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return errSecParam;
    }

    EVP_PKEY_CTX_free(pctx);
    
    // Generate an X.509 cert
    X509 *x509;
    x509 = X509_new();

    const int x509version = 3;
    X509_set_version(x509, x509version - 1); // version is 0-indexed
    
    ASN1_INTEGER_set(X509_get_serialNumber(x509), 10);

    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 31536000L);

    if (!X509_set_pubkey(x509, pkey)) {
        EVP_PKEY_free(pkey);
        @throw [[NSException alloc] initWithName:@"Fail set cert key" reason:getSslError() userInfo:nil];
    }

    X509_NAME *name;
    name = X509_get_subject_name(x509);

    X509_NAME_add_entry_by_txt(name, "OU", MBSTRING_ASC,    // OU = organisational unit
            (unsigned char *)"Kde connect", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O",  MBSTRING_ASC,    // O = organization
            (unsigned char *)"KDE", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC,    // CN = common name is UUID
            (unsigned char *)[uuid UTF8String], -1, -1, 0);

    X509_set_subject_name(x509, name);
    X509_set_issuer_name(x509, name);
    
    if (!X509_sign(x509, pkey, EVP_sha512())) {
        EVP_PKEY_free(pkey);
        @throw [[NSException alloc] initWithName:@"Fail sign cert" reason:getSslError() userInfo:nil];
    }

    if (!X509_check_private_key(x509, pkey)) {
        EVP_PKEY_free(pkey);
        @throw [[NSException alloc] initWithName:@"Fail validate cert" reason:getSslError() userInfo:nil];
    }

    // Load algo and encryption components
    OpenSSL_add_all_algorithms();
    OpenSSL_add_all_ciphers();
    OpenSSL_add_all_digests();
    ERR_load_crypto_strings();

    // Create p12 format data
    PKCS12 *p12 = NULL;
    p12 = PKCS12_create(/* password */ "", /* name */ "KDE Connect", pkey, x509,
                        /* ca */ NULL, /* nid_key */ 0, /* nid_cert */ 0,
                        /* iter */ 0, /* mac_iter */ PKCS12_DEFAULT_ITER, /* keytype */ 0);
    if(!p12) {
        @throw [[NSException alloc] initWithName:@"Fail getP12File" reason:@"Error creating PKCS#12 structure" userInfo:nil];
    }

    // Write into `tmp/rsaPrivate.p12`
    NSString *tempDictionary = NSTemporaryDirectory();
    NSString *p12FilePath = NULL;
    p12FilePath = [tempDictionary stringByAppendingString:@"/rsaPrivate.p12"];
    if (![[NSFileManager defaultManager] createFileAtPath:p12FilePath contents:nil attributes:nil])
    {
        os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Error creating file for P12");
        EVP_PKEY_free(pkey);
        @throw [[NSException alloc] initWithName:@"Fail getP12File" reason:@"Fail Error creating file for P12" userInfo:nil];
    }

    // Get a FILE struct for the P12 file
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:p12FilePath];
    FILE *p12File = fdopen([outputFileHandle fileDescriptor], "w");

    i2d_PKCS12_fp(p12File, p12);
    PKCS12_free(p12);
    fclose(p12File);
    [outputFileHandle closeFile];
    
    EVP_PKEY_free(pkey);
    
    // Read as NSData
    NSData *p12Data = [NSData dataWithContentsOfFile:p12FilePath];
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    [options setObject:@"" forKey:(id)kSecImportExportPassphrase];  // No password

    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import((CFDataRef) p12Data,
                                             (CFDictionaryRef)options, &items);
    SecIdentityRef identityApp;
    if (securityError == noErr && CFArrayGetCount(items) > 0) {
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);

        identityApp = (SecIdentityRef)CFDictionaryGetValue(identityDict,
                                                           kSecImportItemIdentity);

        NSDictionary* addQuery = @{
            (id)kSecValueRef:   (__bridge id)identityApp,
            // Do not use the sec class when adding, adding an identity will add key, cert and the identity
            // (id)kSecClass:      (id)kSecClassIdentity,
            (id)kSecAttrLabel:  (id)uuid,
        };
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
        if (status != errSecSuccess) {
            // Handle the error
            os_log_with_type(logger, OS_LOG_TYPE_FAULT, "Error %d", status);
            return 1;
        }
    }

    // Delete the temp file
    [[NSFileManager defaultManager] removeItemAtPath:p12FilePath error:nil];

    return noErr;
}

NSData* getPublicKeyDERFromCertificate(SecCertificateRef certificate) {
    CFDataRef certificateData = SecCertificateCopyData(certificate);
    const uint8_t *certBytes = CFDataGetBytePtr(certificateData);
    long certLength = CFDataGetLength(certificateData);

    const unsigned char *p = certBytes;
    X509 *x509 = d2i_X509(NULL, &p, certLength);
    CFRelease(certificateData);

    if (x509 == NULL) {
        return nil;
    }

    EVP_PKEY *pkey = X509_get_pubkey(x509);
    if (pkey == NULL) {
        X509_free(x509);
        return nil;
    }
    
    unsigned char *spkiDataPointer = NULL;
    int spkiLength = i2d_PUBKEY(pkey, &spkiDataPointer);

    NSData *spkiData = nil;
    if (spkiLength > 0 && spkiDataPointer != NULL) {
        spkiData = [NSData dataWithBytes:spkiDataPointer length:spkiLength];
        OPENSSL_free(spkiDataPointer);
    }

    X509_free(x509);
    EVP_PKEY_free(pkey);
    
    return spkiData;
}
