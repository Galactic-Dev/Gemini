#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#include <RemoteLog.h>

@interface CCSModuleSettingsProvider : NSObject
@end

@interface GMNSettingsListController : NSObject
@end

%subclass GMNSettingsListController : CCUISettingsListController
-(void)_saveState {
    NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    NSInteger additionalViewSelection = [[settings valueForKey:@"additionalViewSelection"] intValue];
    if(additionalViewSelection != 2) {
        [settings setObject:[self valueForKey:@"_enabledIdentifiers"] forKey:@"customControlCenterModules"];
        [settings setObject:[self valueForKey:@"_disabledIdentifiers"] forKey:@"disabledControlCenterModules"];
    }
    else {
        [settings setObject:[self valueForKey:@"_enabledIdentifiers"] forKey:@"dynamic_customControlCenterModules"];
        [settings setObject:[self valueForKey:@"_disabledIdentifiers"] forKey:@"dynamic_disabledControlCenterModules"];
    }
    [settings writeToFile:path atomically:YES];

    CFStringRef notificationName = (__bridge CFStringRef)@"com.galacticdev.geminiprefs.changed";

    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
}
-(void)_repopulateModuleData {
    NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    NSInteger additionalViewSelection = [settings[@"additionalViewSelection"] intValue];
    CCSModuleSettingsProvider *settingsProvider = [self valueForKey:@"_settingsProvider"];
    if(additionalViewSelection != 2) {
        NSArray *orderedIdentifiers = settings[@"customControlCenterModules"];
        if(orderedIdentifiers.count > 0) [settingsProvider setValue:orderedIdentifiers forKey:@"_orderedUserEnabledModuleIdentifiers"];

        NSMutableArray *enabledIdentifiers = [settings[@"customControlCenterModules"] mutableCopy];
        NSMutableArray *disabledIdentifiers = [settings[@"disabledControlCenterModules"] mutableCopy];

        if(enabledIdentifiers.count > 0) [self setValue:enabledIdentifiers forKey:@"_enabledIdentifiers"];
        if(disabledIdentifiers.count > 0) [self setValue:disabledIdentifiers forKey:@"_disabledIdentifiers"];
    }
    else {
        NSArray *orderedIdentifiers = settings[@"dynamic_customControlCenterModules"];
        if(orderedIdentifiers.count > 0) [settingsProvider setValue:orderedIdentifiers forKey:@"_orderedUserEnabledModuleIdentifiers"];

        NSMutableArray *enabledIdentifiers = [settings[@"dynamic_customControlCenterModules"] mutableCopy];
        NSMutableArray *disabledIdentifiers = [settings[@"dynamic_disabledControlCenterModules"] mutableCopy];

        if(enabledIdentifiers.count > 0) [self setValue:enabledIdentifiers forKey:@"_enabledIdentifiers"];
        if(disabledIdentifiers.count > 0) [self setValue:disabledIdentifiers forKey:@"_disabledIdentifiers"];
    }
    %orig;
}
-(NSString *)tableView:(id)arg1 titleForDeleteConfirmationButtonForRowAtIndexPath:(id)arg2 {
    return @"Remove";
}
-(NSString *)tableView:(id)arg1 titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Included Controls";
    }
    else if (section == 1) {
        return @"More Controls";
    }
    return nil;
}
%end
void initGMNSettingsListController() {
    %config(generator=internal)
    %init;
}
