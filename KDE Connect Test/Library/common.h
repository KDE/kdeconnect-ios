//Copyright 7/5/14  YANG Qiao yangqiao0505@me.com
//kdeconnect is distributed under two licenses.
//
//* The Mozilla Public License (MPL) v2.0
//
//or
//
//* The General Public License (GPL) v2.1
//
//----------------------------------------------------------------------
//
//Software distributed under these licenses is distributed on an "AS
//IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
//implied. See the License for the specific language governing rights
//and limitations under the License.
//kdeconnect is distributed under both the GPL and the MPL. The MPL
//notice, reproduced below, covers the use of either of the licenses.
//
//----------------------------------------------------------------------

#ifndef kdeconnect_ios_common_h
#define kdeconnect_ios_common_h

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define isPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

// keychain related
#define KEYCHAIN_ID     @"org.kde.kdeconnect-ios"
#define KECHAIN_GROUP   @"34RXKJTKWE.org.kde.kdeconnect-ios"

// constants used to find public, private, and symmetric keys.
#define kPublicKeyTag			"org.kde.kdeconnect.publickey"
#define kPrivateKeyTag			"org.kde.kdeconnect.privatekey"
#define kSymmetricKeyTag		"org.kde.kdeconnect.symmetrickey"

// file paths
#define KDECONNECT_REMEMBERED_DEV_FILE_PATH    @"KDEConnectRememberedDevices"

// GCDSingleton
#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#endif
