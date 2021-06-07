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
@end
