//
//  JITEnableContext.h
//  StikJIT
//
//  Created by s s on 2025/3/28.
//
@import Foundation;
@import UIKit;
#include "idevice.h"
#include "jit.h"
#include "heartbeat.h"
#include "mount.h"

typedef void (^HeartbeatCompletionHandler)(int result, NSString *message);
typedef void (^LogFuncC)(const char* message, ...);
typedef void (^LogFunc)(NSString *message);
typedef void (^SyslogLineHandler)(NSString *line);
typedef void (^SyslogErrorHandler)(NSError *error);

@interface JITEnableContext : NSObject {
    // process
    @protected dispatch_queue_t processInspectorQueue;
    @protected IdeviceProviderHandle* provider;

    // syslog
    @protected dispatch_queue_t syslogQueue;
    @protected BOOL syslogStreaming;
    @protected SyslogRelayClientHandle *syslogClient;
    @protected SyslogLineHandler syslogLineHandler;
    @protected SyslogErrorHandler syslogErrorHandler;
}
@property (class, readonly)JITEnableContext* shared;
- (IdevicePairingFile*)getPairingFileWithError:(NSError**)error;
- (IdeviceProviderHandle*)getTcpProviderHandle;
- (BOOL)ensureHeartbeatWithError:(NSError**)err;
- (BOOL)startHeartbeat:(NSError**)err;
- (BOOL)afcPushFile:(NSString *)sourcePath toPath:(NSString *)destPath error:(NSError **)error;
- (BOOL)debugAppWithBundleID:(NSString*)bundleID logger:(LogFunc)logger jsCallback:(DebugAppCallback)jsCallback;
- (BOOL)debugAppWithPID:(int)pid logger:(LogFunc)logger jsCallback:(DebugAppCallback)jsCallback;
- (NSDictionary<NSString*, NSString*>*)getAppListWithError:(NSError**)error;
- (NSDictionary<NSString*, NSString*>*)getAllAppsWithError:(NSError**)error;
- (NSDictionary<NSString*, NSString*>*)getHiddenSystemAppsWithError:(NSError**)error;
- (NSDictionary<NSString*, id>*)getAllAppsInfoWithError:(NSError**)error;
- (UIImage*)getAppIconWithBundleId:(NSString*)bundleId error:(NSError**)error;
- (BOOL)launchAppWithoutDebug:(NSString*)bundleID logger:(LogFunc)logger;
- (void)startSyslogRelayWithHandler:(SyslogLineHandler)lineHandler
                             onError:(SyslogErrorHandler)errorHandler NS_SWIFT_NAME(startSyslogRelay(handler:onError:));
- (void)stopSyslogRelay;
- (NSArray<NSData*>*)fetchAllProfiles:(NSError **)error;
- (BOOL)removeProfileWithUUID:(NSString*)uuid error:(NSError **)error;
- (BOOL)addProfile:(NSData*)profile error:(NSError **)error;
- (NSArray<NSDictionary*>*)fetchProcessListWithError:(NSError**)error;
- (BOOL)killProcessWithPID:(int)pid signal:(int)signal error:(NSError **)error;
@end

@interface JITEnableContext(DDI)
- (NSUInteger)getMountedDeviceCount:(NSError**)error __attribute__((swift_error(zero_result)));
- (NSInteger)mountPersonalDDIWithImagePath:(NSString*)imagePath trustcachePath:(NSString*)trustcachePath manifestPath:(NSString*)manifestPath error:(NSError**)error __attribute__((swift_error(nonzero_result)));
@end
