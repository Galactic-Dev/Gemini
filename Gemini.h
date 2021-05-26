#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <RemoteLog.h>
#include <dlfcn.h>

@interface NSDistributedNotificationCenter : NSNotificationCenter
-(void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
@end

@interface SBFluidSwitcherViewController : UIViewController
@property (nonatomic,retain) UIView *contentView;
@property (strong, nonatomic) NSMutableDictionary *visibleItemContainers;
@end

@interface SBDeckSwitcherViewController : SBFluidSwitcherViewController
@end

//Control Center Stuff
@interface SBControlCenterSystemAgent : NSObject
@end

@interface CCSModuleRepository : NSObject
+(instancetype)repositoryWithDefaults;
@end

@interface CCUIModuleInstanceManager : NSObject
-(instancetype)_initWithSystemAgent:(SBControlCenterSystemAgent *)arg1 repository:(CCSModuleRepository *)arg2;
+(instancetype)sharedInstance;
@end

@interface CCUIModuleCollectionViewController : UIViewController
-(instancetype)initWithModuleInstanceManager:(CCUIModuleInstanceManager *)arg1;
-(void)_updateModuleControllers;
-(void)_updatePositionProviders;
-(void)_updateEnabledModuleIdentifiers;
@end

@interface NCNotificationListView : UIScrollView
-(void)setRevealed:(BOOL)arg1;
@end

@interface NCNotificationStructuredSectionList : NSObject
@property (nonatomic,retain) NCNotificationListView *sectionListView;
-(NSMutableArray *)allNotificationRequests;
-(void)insertNotificationRequest:(id)arg1;
-(void)removeNotificationRequest:(id)arg1;
@property (strong, nonatomic) UIView *revealHintView;
@end

@interface NCNotificationMasterList : NSObject
@property (strong, nonatomic) NSMutableArray <NCNotificationStructuredSectionList *> *notificationSections;
@end

@interface NCNotificationStructuredListViewController : UIViewController
@property (nonatomic, strong, readwrite) NCNotificationListView *masterListView;
@property (strong, nonatomic) NCNotificationMasterList *masterList;
@property (nonatomic,assign) BOOL axnAllowChanges;
-(void)revealNotificationHistory:(BOOL)arg1 animated:(BOOL)arg2;
-(void)removeNotificationRequest:(id)arg1;
-(void)insertNotificationRequest:(id)arg1;
@property (strong, nonatomic) id delegate;
@property (nonatomic, assign, getter=isDeviceAuthenticated) BOOL deviceAuthenticated;
@end

@interface SBMainSwitcherViewController : UIViewController
+(SBMainSwitcherViewController *)sharedInstance;
@property (nonatomic,readonly) SBDeckSwitcherViewController* contentViewController;
-(NSInteger)sbActiveInterfaceOrientation;

//my custom methods & properties
@property (strong, nonatomic) CCUIModuleCollectionViewController *geminiModuleViewController;
@property (strong, nonatomic) NCNotificationStructuredListViewController *geminiStructuredListViewController;
@property (strong, nonatomic) UIView *geminiAdditionalView;
-(void)insertNotificationsForBundleIdentifier:(NSString *)identifier;
@property (strong, nonatomic) NSMutableDictionary *notificationRequests;
@property (strong, nonatomic) NSString *currentIdentifier;
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture;
@property (nonatomic, assign) BOOL isSmall;
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
-(NSMutableArray *)requestsForBundleIdentifier:(NSString *)arg1;
@property (strong, nonatomic) NSMutableDictionary *names;
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
