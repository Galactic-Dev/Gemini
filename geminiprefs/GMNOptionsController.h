#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface GMNOptionsController : PSListController
@end

@interface NSDistributedNotificationCenter : NSNotificationCenter
-(void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
- (void)postNotificationName:(NSNotificationName)aName object:(NSString *)anObject;
@end
