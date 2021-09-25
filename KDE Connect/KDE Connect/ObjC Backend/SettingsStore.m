////Copyright 11/6/14  YANG Qiao yangqiao0505@me.com
////kdeconnect is distributed under two licenses.
////
////* The Mozilla Public License (MPL) v2.0
////
////or
////
////* The General Public License (GPL) v2.1
////
////----------------------------------------------------------------------
////
////Software distributed under these licenses is distributed on an "AS
////IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
////implied. See the License for the specific language governing rights
////and limitations under the License.
////kdeconnect is distributed under both the GPL and the MPL. The MPL
////notice, reproduced below, covers the use of either of the licenses.
////
////----------------------------------------------------------------------
//
//#import "SettingsStore.h"
//
//@interface SettingsStore()
//@property(nonatomic) NSMutableDictionary* _dict;
//
//@end
//
//@implementation SettingsStore
//
//@synthesize _filePath;
//@synthesize _dict;
//
//- (id)initWithPath:(NSString*)path
//{
//    //get app document path
//    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *plistPath = [paths objectAtIndex:0];
//    _filePath=[plistPath stringByAppendingPathComponent:path];
//    if((self = [super init])) {
//        _dict = [[NSMutableDictionary alloc] initWithContentsOfFile:_filePath];
//        if(_dict == nil) {
//            _dict = [NSMutableDictionary dictionaryWithCapacity:1];
//        }
//    }
//    return self;
//}
//
//- (NSArray*)getAllKeys
//{
//    return [_dict allKeys];
//}
//
//- (void)setObject:(id)value forKey:(NSString *)key {
//    if (!value) {
//        [_dict removeObjectForKey:key];
//    }
//    else{
//        [_dict setObject:value forKey:key];
//    }
//}
//
//- (id)objectForKey:(NSString *)key {
//    return [_dict objectForKey:key];
//}
//
//- (BOOL)synchronize {
//    return [_dict writeToFile:_filePath atomically:YES];
//}
//
//@end
