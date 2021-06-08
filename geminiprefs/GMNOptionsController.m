#include "GMNOptionsController.h"

@implementation GMNOptionsController
- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
        NSInteger additionalViewSelection = [settings[@"additionalViewSelection"] intValue];
        NSString *plistName;
        switch (additionalViewSelection) {
            case 0: {
                plistName = @"Notifications";
                break;
            }
            case 1: {
                plistName = @"ControlCenter";
                break;
            }
            case 2: {
                plistName = @"Dynamic";
                break;
            }
            default: {
                break;
            }
        }
        _specifiers = [self loadSpecifiersFromPlistName:plistName target:self];
        }
    return _specifiers;
}
-(id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    [settings setObject:value forKey:specifier.properties[@"key"]];
    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];

    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
}
@end
