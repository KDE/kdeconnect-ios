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

OSStatus generateSecIdentityForUUID(NSString *uuid)
{
    // Force to remove the old identity, otherwise the new identity cannot be stored
    NSDictionary *spec = @{(__bridge id)kSecClass: (id)kSecClassIdentity};
    SecItemDelete((__bridge CFDictionaryRef)spec);

    // Generate a private key
    EVP_PKEY * pkey;
    pkey = EVP_PKEY_new();
    
    RSA * rsa = RSA_new();
    BIGNUM* bignum_exponent = BN_new();
    BN_set_word(bignum_exponent, (unsigned long) RSA_F4);
    RSA_generate_key_ex(rsa, 2048, bignum_exponent, NULL);

    EVP_PKEY_assign_RSA(pkey, rsa);

    // Generate an X.509 cert
    X509 *x509;
    x509 = X509_new();

    ASN1_INTEGER_set(X509_get_serialNumber(x509), 10);

    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 31536000L);

    X509_set_pubkey(x509, pkey);

    X509_NAME *name;
    name = X509_get_subject_name(x509);

    X509_NAME_add_entry_by_txt(name, "OU", MBSTRING_ASC,    // OU = organisational unit
            (unsigned char *)"Kde connect", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O",  MBSTRING_ASC,    // O = organization
            (unsigned char *)"KDE", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC,    // CN = common name is UUID
            (unsigned char *)[uuid UTF8String], -1, -1, 0);

    X509_set_issuer_name(x509, name);
    
    if (!X509_sign(x509, pkey, EVP_md5())) {
        @throw [[NSException alloc] initWithName:@"Fail sign cert" reason:@"Error" userInfo:nil];
    }

    if (!X509_check_private_key(x509, pkey)) {
        @throw [[NSException alloc] initWithName:@"Fail validate cert" reason:@"Error" userInfo:nil];
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
        NSLog(@"Error creating file for P12");
        @throw [[NSException alloc] initWithName:@"Fail getP12File" reason:@"Fail Error creating file for P12" userInfo:nil];
    }

    // Get a FILE struct for the P12 file
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:p12FilePath];
    FILE *p12File = fdopen([outputFileHandle fileDescriptor], "w");

    i2d_PKCS12_fp(p12File, p12);
    PKCS12_free(p12);
    fclose(p12File);
    [outputFileHandle closeFile];
    
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
            NSLog(@"Error");
            return 1;
        }
        // Release finished CF Objects
        CFRelease(identityDict);
    }

    // Delete the temp file
    [[NSFileManager defaultManager] removeItemAtPath:p12FilePath error:nil];

    return noErr;
}
