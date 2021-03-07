#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <RemoteLog.h>
#include <dlfcn.h>

@interface NSDistributedNotificationCenter : NSNotificationCenter
-(void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
@end

@interface SBFluidSwitcherViewController : UIViewController
@property (nonatomic,retain) UIView *contentView;
@end

@interface SBDeckSwitcherViewController : SBFluidSwitcherViewController
@end

@interface SBMainSwitcherViewController : UIViewController
@property (nonatomic, assign) BOOL isSmall;
@property (nonatomic, retain) UIView *geminiScrollView;
+(SBMainSwitcherViewController *)sharedInstance;
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture;
@property (nonatomic,readonly) SBDeckSwitcherViewController* contentViewController;
@end

@interface NCNotificationListView : UIScrollView
-(void)setRevealed:(BOOL)arg1;
@end

@interface NCNotificationStructuredSectionList
@property (nonatomic,retain) NCNotificationListView *sectionListView;
-(NSArray *)allNotificationRequests;
@end

@interface NCNotificationStructuredListViewController : UIViewController
@property (nonatomic, strong, readwrite) NCNotificationListView *masterListView;
@property (nonatomic,assign) BOOL axnAllowChanges;
-(void)revealNotificationHistory:(BOOL)arg1 animated:(BOOL)arg2;
-(void)removeNotificationRequest:(id)arg1;
-(void)insertNotificationRequest:(id)arg1;
@end

@interface SBFluidSwitcherContentView : UIView
@end

@interface SBTransitionSwitcherModifierEvent
@end

@interface AXNView : UIView
-(void)refresh;
@end

@interface AXNManager : NSObject
+(instancetype)sharedInstance;
-(void)showNotificationRequestsForBundleIdentifier:(NSString *)bundleIdentifier;
@property (nonatomic, weak) AXNView *view;
@end

@interface SBFluidSwitcherItemContainerHeaderView : UIView
@property (nonatomic, assign) BOOL showingNotifs;
@property (assign,nonatomic) double textAlpha;
@end

@interface CPNotification : NSObject
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message userInfo:(NSDictionary*)userInfo badgeCount:(int)badgeCount soundName:(NSString*)soundName delay:(double)delay repeats:(BOOL)repeats bundleId:(NSString*)bundleId uuid:(NSString*)uuid silent:(BOOL)silent;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message userInfo:(NSDictionary*)userInfo badgeCount:(int)badgeCount soundName:(NSString*)soundName delay:(double)delay repeats:(BOOL)repeats bundleId:(NSString*)bundleId;
@end

@interface NCNotificationRequest
@property (nonatomic,copy,readonly) NSString *sectionIdentifier;
@end

@interface SBDisplayItem
@property (nonatomic,copy,readonly) NSString *bundleIdentifier;
@end

@interface SBAppLayout : NSObject
@property (nonatomic, copy) NSDictionary *rolesToLayoutItemsMap;
@end

@interface SBAppSwitcherReusableSnapshotView
@property (nonatomic,retain) SBAppLayout * appLayout;
@end

@interface SBAppSwitcherPageView
@property (nonatomic,retain) SBAppSwitcherReusableSnapshotView *view;
@end

@interface GeminiSwitcherView : UIView
@end

@interface CSCombinedListViewController
-(UIEdgeInsets)_listViewDefaultContentInsets;
-(void)_updateListViewContentInset;
@end

@interface BSUIScrollView : UIScrollView
-(void)_setScrolling:(BOOL)arg1 ;
@end

@interface SBAppSwitcherScrollView : BSUIScrollView
@end

@interface CSAdjunctListView : UIView
@end

@interface CSNotificationAdjunctListViewController

@end
