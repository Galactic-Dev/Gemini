#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface UIDevice (notchedDevice)
@property (nonatomic,readonly) NSString * model;
-(NSString *)model;
// new methods
-(BOOL)isNotched;
@end
