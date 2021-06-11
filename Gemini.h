#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <RemoteLog.h>
#include <dlfcn.h>
#import "UIDevice+notchedDevice.h"

@interface UIViewController (Private)
-(id)_rootAncestorViewController;
@end

@interface UIScrollView (Private)
@property (nonatomic, assign, getter=_maximumContentOffset) CGPoint maximumContentOffset;
@end

@interface NSDistributedNotificationCenter : NSNotificationCenter
-(void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
@end

@interface SBAppSwitcherScrollView : UIScrollView
@end

@interface SBAppLayout : NSObject
@property (nonatomic, copy) NSDictionary *rolesToLayoutItemsMap;

//custom properties and methods
@property (nonatomic, assign) BOOL geminiIsShowingNotifs;
@end

@interface SBFluidSwitcherViewController : UIViewController
@property (nonatomic,retain) UIView *contentView;
@property (strong, nonatomic) NSMutableDictionary *visibleItemContainers;
@property (strong, nonatomic) SBAppSwitcherScrollView *scrollView;
-(void)_scrollToAppLayout:(SBAppLayout *)appLayout animated:(BOOL)animated completion:(id)completion;
@end

@interface SBDeckSwitcherViewController : SBFluidSwitcherViewController
@property (nonatomic,retain) UIViewController *appSuggestionController;
@end

//Control Center Stuff
@interface PowerUIModuleContentViewController : UIViewController
@end

@interface RPControlCenterClient : NSObject
@property (nonatomic, assign) BOOL broadcastMode;
@property (nonatomic, assign) BOOL microphoneOn;
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) BOOL shouldShowMicButton;
@property (nonatomic, assign) BOOL lockUIControls;
@property (nonatomic, assign) BOOL isCountingDown;
@property (nonatomic, assign) BOOL recordingOn;
@property (strong, nonatomic) NSString *extensionBundleID;
@property (strong, nonatomic) NSString *preferredExtension;
@property (strong, nonatomic) NSString *currentTimerString;
@end

@interface RPControlCenterModule : NSObject
@end

@interface CCUIModuleCollectionView : UIView
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@end

@interface CCUILayoutOptions : NSObject
-(void)setItemEdgeSize:(CGFloat)arg1;
-(void)setItemSpacing:(CGFloat)arg1;
@end

@interface MediaControlsVolumeViewController : UIViewController
@end

@interface MRUControlCenterViewController : UIViewController
-(void)setState:(NSInteger)arg1;
@end

@interface SBControlCenterSystemAgent : NSObject
@end

@interface CCSModuleRepository : NSObject
+(instancetype)repositoryWithDefaults;
@end

@interface CCSModuleSettingsProvider : NSObject
@end

@interface CCUIModuleSettingsManager : NSObject
@end

@interface CCUIModuleInstanceManager : NSObject
-(instancetype)_initWithSystemAgent:(SBControlCenterSystemAgent *)arg1 repository:(CCSModuleRepository *)arg2;
+(instancetype)sharedInstance;
@property (strong, nonatomic) NSSet *enabledModuleIdentifiers;
-(void)_updateModuleInstances;
@end

@interface CCUIModuleCollectionViewController : UIViewController
-(instancetype)initWithModuleInstanceManager:(CCUIModuleInstanceManager *)arg1;
-(void)_updateModuleControllers;
-(void)_updatePositionProviders;
-(void)_updateEnabledModuleIdentifiers;
-(void)dismissPresentedContentAnimated:(BOOL)arg1 completion:(id)arg2;
@end

@interface NCNotificationListView : UIScrollView
-(void)_updateVisibleViewsForUpdatedVisibleRect:(CGRect)arg1;
@end

@interface NCNotificationStructuredSectionList : NSObject
@property (nonatomic,retain) NCNotificationListView *sectionListView;
-(NSMutableArray *)allNotificationRequests;
-(void)insertNotificationRequest:(id)arg1;
-(void)removeNotificationRequest:(id)arg1;
@property (strong, nonatomic) UIView *revealHintView;
@property (nonatomic, assign) NSUInteger notificationCount;
@end

@interface NCNotificationMasterList : NSObject
@property (strong, nonatomic) NSMutableArray <NCNotificationStructuredSectionList *> *notificationSections;
@end

@interface NCNotificationListSectionRevealHintView : UIView
-(void)_layoutRevealHintTitle;
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
-(BOOL)bundleIdentifierIsInCenterOfSwitcher:(NSString *)identifier;
@property (strong, nonatomic) UIVisualEffectView *geminiBlurView;
-(void)showGeminiBlurView:(BOOL)shouldShow makeTopMostView:(BOOL)shouldMakeTopMost;
@property (nonatomic, assign) BOOL geminiHasExpandedDynamicView;
-(void)dismissExpandedDynamicView;
@property (strong, nonatomic) NSLayoutConstraint *geminiExpandedCenterYAnchor;
@property (strong, nonatomic) NSLayoutConstraint *geminiExpandedHeightAnchor;
@property (strong, nonatomic) NSLayoutConstraint *geminiDynamicHeightAnchor;
@property (strong, nonatomic) NSLayoutConstraint *geminiControlCenterHeightAnchor;
-(void)setupGeminiModuleViewController;
-(void)setupGeminiStructuredListViewController;
@property (strong, nonatomic) CCUIModuleInstanceManager *geminiModuleInstanceManager;
@end

@interface AXNView : UIView
@end

@interface AXNManager : NSObject
+(instancetype)sharedInstance;
-(void)showNotificationRequestsForBundleIdentifier:(NSString *)bundleIdentifier;
@property (nonatomic, weak) AXNView *view;
-(NSMutableArray *)requestsForBundleIdentifier:(NSString *)arg1;
@property (strong, nonatomic) NSMutableDictionary *names;
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

@interface SBAppSwitcherReusableSnapshotView
@property (nonatomic,retain) SBAppLayout *appLayout;
@end

@interface SBAppSwitcherPageView
@property (nonatomic,retain) SBAppSwitcherReusableSnapshotView *view;
@end

@interface GeminiSwitcherView : UIView
@end
