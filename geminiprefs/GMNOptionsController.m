#include "GMNOptionsController.h"

@implementation GMNOptionsController
- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
        NSInteger additionalViewSelection = [settings[@"additionalViewSelection"] intValue];
        NSString *plistName;
        switch (additionalViewSelection) {
            case 1: {
                plistName = @"Notifications";
                break;
            }
            case 0: {
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

        NSArray *chosenIDs = @[@"controlCenterLinkCell"];
        self.savedSpecifiers = (_savedSpecifiers) ?: [NSMutableDictionary dictionary];
        for(PSSpecifier *specifier in [self specifiersForIDs:chosenIDs]) {
            [self.savedSpecifiers setObject:specifier forKey:[specifier propertyForKey:@"id"]];
        }
    }
    return _specifiers;
}
-(void)updateSpecifierVisibility:(BOOL)animated {
    //Get value of switch specifier
    PSSpecifier *switchSpecifier = [self specifierForID:@"hasCustomControlCenterModules"];
    BOOL switchValue = [[self readPreferenceValue:switchSpecifier] boolValue];

    //Check if our switch is set to NO, then remove the specifier
    if(!switchValue) {
        [self removeSpecifier:self.savedSpecifiers[@"controlCenterLinkCell"] animated:animated];

    //If the switch is set to YES, we check if the specifier exists then insert it after the switch using the SWITCH_ID
    } else if(![self containsSpecifier:self.savedSpecifiers[@"controlCenterLinkCell"]]) {
        [self insertSpecifier:self.savedSpecifiers[@"controlCenterLinkCell"] afterSpecifierID:@"hasCustomControlCenterModules" animated:animated];
    }
}
-(void)reloadSpecifiers {
    [super reloadSpecifiers];

    //We set the animated argument to NO to hide cell's animation of being removed
    [self updateSpecifierVisibility:NO];
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
    [self updateSpecifierVisibility:YES];
}
-(void)viewDidLoad {
    [super viewDidLoad];

    [self updateSpecifierVisibility:NO];
}
@end
extern void initGMNSettingsListController();
__attribute__((constructor))
static void init(void) {

    NSBundle *ccSettingsBundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/ControlCenterSettings.bundle"];
    if(ccSettingsBundle) {
        dlopen("/System/Library/PrivateFrameworks/ControlCenterServices.framework/ControlCenterServices", RTLD_NOW);
        dlopen("/System/Library/PreferenceBundles/ControlCenterSettings.bundle/ControlCenterSettings", RTLD_NOW);
        [ccSettingsBundle load];
        initGMNSettingsListController();
    }
}
