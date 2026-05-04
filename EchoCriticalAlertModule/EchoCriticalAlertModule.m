#import "EchoCriticalAlertModule.h"
#import <UserNotifications/UserNotifications.h>

@interface EchoCriticalAlertModule () <UNUserNotificationCenterDelegate>
@end

@implementation EchoCriticalAlertModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(getCriticalAlertStatus:))
WX_EXPORT_METHOD(@selector(fireAlert))

- (void)getCriticalAlertStatus:(WXModuleKeepAliveCallback)callback {
    if (@available(iOS 12.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            BOOL isEnabled = (settings.criticalAlertSetting == UNNotificationSettingEnabled);
            NSDictionary *result = @{
                @"code": @0,
                @"authStatus": @(settings.authorizationStatus),
                @"criticalSetting": @(settings.criticalAlertSetting),
                @"isCriticalEnabled": @(isEnabled)
            };
            if (callback) callback(result, NO);
        }];
    } else {
        if (callback) callback(@{@"code": @-1, @"msg": @"系统版本低于 iOS 12"}, NO);
    }
}

- (void)fireAlert {
    NSLog(@"[Echo-CriticalAlert] 收到前端指令，准备发射本地关键警告！");
    
    if (@available(iOS 12.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"紧急求助信号";
        content.body = @"检测到异常状态，已触发最高级别警报！";
        content.sound = [UNNotificationSound defaultCriticalSoundWithAudioVolume:1.0];
        
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:trigger];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"[Echo-CriticalAlert] 警报发射失败: %@", error);
            } else {
                NSLog(@"[Echo-CriticalAlert] 警报发射成功！");
            }
        }];
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center 
       willPresentNotification:(UNNotification *)notification 
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionList);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
    }
}

@end
