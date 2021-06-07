#include "GMNCreditsController.h"
@implementation GMNCreditsController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Credits" target:self];
        }
    return _specifiers;
}
@end
