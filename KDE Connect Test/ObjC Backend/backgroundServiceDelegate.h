//
//  backgroundServiceDelegate.h
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-10.
//

@protocol backgroundServiceDelegate <NSObject>
@optional
- (void) onPairRequest:(NSString*)deviceId;
- (void) onPairTimeout:(NSString*)deviceId;
- (void) onPairSuccess:(NSString*)deviceId;
- (void) onPairRejected:(NSString*)deviceId;
- (void) onDeviceListRefreshed;
- (void) refreshDiscoveryAndListInsideView;
- (void) currDeviceDetailsViewDisconnectedFromRemote:(NSString*)deviceId;
- (void) unpairFromBackgroundServiceInstance:(NSString*)deviceId;
- (void) removeDeviceFromArrays:(NSString*)deviceId;
@end
