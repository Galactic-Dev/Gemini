#import "Gemini.h"

NCNotificationStructuredListViewController *notifVC;
SBMainSwitcherViewController *mainSwitcherVC;
long long environmentMode;

NSTimeInterval lastOffsetCaptured;

//sbappswitcherscrollview stuff
CGPoint lastOffset;
NSTimeInterval lastOffsetCapture;
BOOL isScrollingFast;

//PREFERENCES:
BOOL isEnabled;
BOOL reduceAnimations;
NSInteger additionalViewSelection;

%group Main
%hook CCUIModuleCollectionViewController
//fixes weird animation issues by just... causing it not to animate;
-(void)dismissExpandedModuleAnimated:(BOOL)arg1 completion:(id)arg2 {
    if(self != mainSwitcherVC.geminiModuleViewController) {
        %orig;
        return;
    }
    %orig(NO, arg2);
}
-(void)dismissPresentedContentAnimated:(BOOL)arg1 completion:(id)arg2 {
    if(self != mainSwitcherVC.geminiModuleViewController) {
        %orig;
        return;
    }
    %orig(NO, arg2);
}

//supposedly fixes some modules not updating; this is the same code that runs after setting up the vc in the handlePinch: method 
-(void)addChildViewController:(UIViewController *)viewController {
    %orig;
    if(self == mainSwitcherVC.geminiModuleViewController) {
        [viewController.childViewControllers[0] viewWillAppear:NO];
    }
}
%end

//prevents axon from adding my custom clvc as its clvc; in turn, breaking both tweaks simultaneously
%hook AXNManager
-(void)setClvc:(id)arg1 {
    if(![self valueForKey:@"_clvc"]) {
        %orig;
    }
}
%end

%hook SBMainSwitcherViewController
%property (nonatomic, assign) BOOL isSmall;
%property (strong, nonatomic) CCUIModuleCollectionViewController *geminiModuleViewController;
%property (strong, nonatomic) NCNotificationStructuredListViewController *geminiStructuredListViewController;
%property (strong, nonatomic) UIView *geminiAdditionalView;
%property (strong, nonatomic) NSMutableDictionary *notificationRequests;
%property (strong, nonatomic) NSString *currentIdentifier;

-(void)viewDidLoad {
    %orig;
    mainSwitcherVC = self;

    //replaces the mainSwitcherVC's view with a custom UIView subclass so that I can override the hitTest:withEvent: method
    NSArray *subviews = self.view.subviews;
    self.view = [[GeminiSwitcherView alloc] initWithFrame:self.view.frame];
    for(UIView *subview in subviews){
        [self.view addSubview:subview];
    }

    //add pinch recognizer
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinchRecognizer];

    //adds notif observer for the "Test Notifications" button in prefs
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(GMNShowTestNotifications) name:@"com.galacticdev.gemini/showTestNotifications" object:nil];
    }
%new -(BOOL)bundleIdentifierIsInCenterOfSwitcher:(NSString *)identifier {
    UIView *view = [self.view hitTest:self.view.center withEvent:nil];
    if(view.superview.class == %c(SBAppSwitcherPageView)) {
        SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)view.superview;
        SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
        SBAppLayout *appLayout = snapshotView.appLayout;
        SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
        
        NSString *actualIdentifier = displayItem.bundleIdentifier;
        if([identifier isEqualToString:actualIdentifier]) {
            return YES;
        }
    }
    return NO;
}

%new -(void)insertNotificationsForBundleIdentifier:(NSString *)identifier {
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - lastOffsetCaptured;
    if(timeDiff <= 0.1) {
        RLog(@"SKIPPING");
        return;
    }
    RLog(@"NOT SKPPING");

    AXNManager *axonManager = [%c(AXNManager) sharedInstance];

    NSMutableArray <NCNotificationRequest *> *requests = [NSMutableArray array];
    NSMutableArray <NCNotificationRequest *> *oldRequests = [NSMutableArray array];

    for(NSString *ident in axonManager.names.allKeys) {
        [requests addObjectsFromArray:[axonManager requestsForBundleIdentifier:ident]];
    }

    for(NCNotificationStructuredSectionList *sectionList in self.geminiStructuredListViewController.masterList.notificationSections) {
        [oldRequests addObjectsFromArray:[sectionList allNotificationRequests]];
    }
    for(NCNotificationStructuredSectionList *sectionList in notifVC.masterList.notificationSections) {
        [requests addObjectsFromArray:[sectionList allNotificationRequests]];
    }


    for(NCNotificationRequest *request in oldRequests) {
        if(![requests containsObject:request]) {
            [self.notificationRequests[request.sectionIdentifier] removeObject:request];
            [self.geminiStructuredListViewController.masterList.notificationSections[0] removeNotificationRequest:request];
        }
    }

    for(int i = 0; i < requests.count; i++) {
        [self.geminiStructuredListViewController.masterList.notificationSections[0] removeNotificationRequest:requests[i]];
        NSString *sectionIdentifier = requests[i].sectionIdentifier;
        if([self.notificationRequests.allKeys containsObject:sectionIdentifier]) {
            NSMutableArray *requestsForID = self.notificationRequests[sectionIdentifier];
            if(![requestsForID containsObject:requests[i]]) [requestsForID addObject:requests[i]];
        }
        else {
            [self.notificationRequests setValue:@[requests[i]].mutableCopy forKey:sectionIdentifier];
        }
        if(identifier) {
            if([sectionIdentifier isEqualToString:identifier]) {
                [self.geminiStructuredListViewController.masterList.notificationSections[0] insertNotificationRequest:requests[i]];
            }
        }
    }
    self.geminiStructuredListViewController.masterList.notificationSections[1].revealHintView.hidden = YES;
    lastOffsetCaptured = currentTime;
}

%new
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture {
    if(pinchGesture.scale <= 0.75 && !self.isSmall && [self sbActiveInterfaceOrientation] == 1 && environmentMode == 2) {
        mainSwitcherVC.isSmall = YES;

        self.notificationRequests = [NSMutableDictionary dictionary];
        if(self.childViewControllers.count < 2) {
            switch(additionalViewSelection) {
                case 0: {
                    self.geminiStructuredListViewController = [[%c(NCNotificationStructuredListViewController) alloc] init];

                    [self addChildViewController:self.geminiStructuredListViewController];
                    [self.view addSubview:self.geminiStructuredListViewController.view];
                    
                    self.geminiStructuredListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
                    self.geminiStructuredListViewController.masterListView.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    
                    CGFloat switcherHeight = self.view.frame.size.height * 0.75;
                    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                    CGFloat height = (screenHeight - switcherHeight) + 100;
                    [self.geminiStructuredListViewController.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-100].active = YES;
                    [self.geminiStructuredListViewController.view.heightAnchor constraintEqualToConstant:height].active = YES;
                    [self.geminiStructuredListViewController.view.widthAnchor constraintEqualToConstant:self.geminiStructuredListViewController.view.frame.size.width].active = YES;
                    
                    [self.geminiStructuredListViewController.masterListView.topAnchor constraintEqualToAnchor:self.geminiStructuredListViewController.view.topAnchor].active = YES;
                    [self.geminiStructuredListViewController.masterListView.heightAnchor constraintEqualToConstant:height].active = YES;

                    [self.geminiStructuredListViewController.masterListView.widthAnchor constraintEqualToConstant:self.geminiStructuredListViewController.masterListView.frame.size.width].active = YES;
                    
                    self.geminiAdditionalView = self.geminiStructuredListViewController.view;

                    self.geminiStructuredListViewController.delegate = notifVC.delegate;
                    self.geminiStructuredListViewController.deviceAuthenticated = YES;
                    self.geminiAdditionalView.clipsToBounds = YES;

                    [self insertNotificationsForBundleIdentifier:self.currentIdentifier];
                    break;
                }
                case 1: {
                    SBControlCenterSystemAgent *systemAgent = [[%c(SBControlCenterSystemAgent) alloc] init];
                    CCUIModuleInstanceManager *moduleInstanceManager = [[%c(CCUIModuleInstanceManager) alloc] _initWithSystemAgent:systemAgent repository:[%c(CCSModuleRepository) repositoryWithDefaults]];
                    
                    self.geminiModuleViewController = [[%c(CCUIModuleCollectionViewController) alloc] initWithModuleInstanceManager:moduleInstanceManager];
                    
                    [mainSwitcherVC addChildViewController:self.geminiModuleViewController];
                    
                    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.geminiModuleViewController.view.frame];
                    [scrollView addSubview:self.geminiModuleViewController.view];
                    [mainSwitcherVC.view addSubview:scrollView];
                    
                    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
                    self.geminiModuleViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    CGFloat switcherHeight = self.view.frame.size.height * 0.75;
                    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                    CGFloat height = (screenHeight - switcherHeight) + 100;
                    
                    [scrollView.widthAnchor constraintEqualToConstant:self.geminiModuleViewController.view.frame.size.width].active = YES;
                    [scrollView.heightAnchor constraintEqualToConstant:height].active = YES;
                    [scrollView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-100].active = YES;
                    [scrollView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
                    
                    [self.geminiModuleViewController.view.heightAnchor constraintEqualToConstant:1024].active = YES;
                    [self.geminiModuleViewController.view.topAnchor constraintEqualToAnchor:scrollView.topAnchor].active = YES;
                    
                    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, 1024); //need an actual way to get the height of the moduleViewController, or what is is supposed to be, so i can set the contentSize height and moduleViewController frame height accordingly instead of just using 1024 as an arbitrary number that just happens to be large enough for my cc setup.
                    self.geminiAdditionalView = scrollView;
                    break;
                }
                default: {
                    break;
                }
            }
        }

        for(UIViewController *childViewController in self.geminiModuleViewController.childViewControllers) {
            UIViewController *childChildViewController = childViewController.childViewControllers[0];
            [childChildViewController viewWillAppear:NO];
            
            if([childChildViewController respondsToSelector:@selector(setState:)]) { //fixes music player being a weird size when dismissed
                [childChildViewController performSelector:@selector(setState:) withObject:nil]; //ew this is gross but whatever ill get a better way eventually
            }
        }

        self.geminiAdditionalView.transform = CGAffineTransformMakeScale(0.1,0.1);
        self.geminiAdditionalView.alpha = 1;
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 100, self.view.frame.size.width, self.view.frame.size.height);
            self.view.transform = CGAffineTransformMakeScale(.75, .75);

            self.geminiAdditionalView.transform = CGAffineTransformMakeScale(1.25,1.25);
            
            return;
        } completion:nil];
    }
    else if(pinchGesture.scale >= 1.0 && mainSwitcherVC.isSmall && [self sbActiveInterfaceOrientation] == 1) {
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 100, self.view.frame.size.width, self.view.frame.size.height);
            self.view.transform = CGAffineTransformMakeScale(1, 1);

            self.geminiAdditionalView.alpha = 0;
            self.geminiAdditionalView.transform = CGAffineTransformMakeScale(0.1,0.1);

            return;
        } completion:nil];
        self.isSmall = NO;
        self.currentIdentifier = nil;
    }
}

%new
-(void)GMNShowTestNotifications {
    //add notifications for currently opened apps
    NSArray *mainAppLayouts = [self valueForKey:@"_appLayouts"];
    for(int i = 0; i < [mainAppLayouts count]; i++ ){
        SBAppLayout *appLayout = mainAppLayouts[i];
        SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
        NSString *identifier = displayItem.bundleIdentifier;
        int ii = i;
        for(int b = 0; b < [mainAppLayouts count] - 0; b++) {
            void *handle = dlopen("/usr/lib/libnotifications.dylib", RTLD_LAZY);
            if (handle != NULL) {
                NSString *uid = [[NSUUID UUID] UUIDString];
                [objc_getClass("CPNotification") showAlertWithTitle:@"Holy Smokes!"
                                                            message:[NSString stringWithFormat:@"Notification #%d", ii + 1]
                                                           userInfo:@{@"" : @""}
                                                         badgeCount:1
                                                          soundName:nil
                                                              delay:1.00
                                                            repeats:NO
                                                           bundleId:identifier
                                                               uuid:uid
                                                             silent:NO];
                dlclose(handle);
            }
        }
    }
}
%end

%hook SBTransitionSwitcherModifierEvent
-(void)setToEnvironmentMode:(long long)arg1 {
    environmentMode = arg1;
    %orig;
    if (arg1 != 2 && [mainSwitcherVC sbActiveInterfaceOrientation] == 1){ //checks if switcher isn't showing and content orientation is portrait;
        mainSwitcherVC = [%c(SBMainSwitcherViewController) sharedInstance];
        if (mainSwitcherVC.isSmall){
            mainSwitcherVC.view.frame = CGRectMake(mainSwitcherVC.view.frame.origin.x, mainSwitcherVC.view.frame.origin.y + 100, mainSwitcherVC.view.frame.size.width, mainSwitcherVC.view.frame.size.height);
            mainSwitcherVC.view.transform = CGAffineTransformMakeScale(1, 1);
            mainSwitcherVC.isSmall = NO;
            mainSwitcherVC.currentIdentifier = nil;
        }
        mainSwitcherVC.geminiAdditionalView.alpha = 0;
        mainSwitcherVC.geminiAdditionalView.transform = CGAffineTransformMakeScale(0.1,0.1);
    }
}
%end

%hook SBAppLayout
%property (nonatomic, assign) BOOL geminiIsShowingNotifs;
%end;

%hook NCNotificationStructuredListViewController
-(id)init {
    if(!notifVC) notifVC = self; //checks if notifvc is already set to prevent my custom notifvc from being set as the notifvc
    return %orig;
}

//updates my custom notifvc when a notification is received or deleted
-(void)insertNotificationRequest:(id)arg1 {
    %orig;
    if([self respondsToSelector:@selector(axnAllowChanges)]) {
        if(self.axnAllowChanges) {
            [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
        }
    }
    else {
        [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
    }
}
-(void)removeNotificationRequest:(id)arg1 {
    %orig;
    if([self respondsToSelector:@selector(axnAllowChanges)]) {
        if(self.axnAllowChanges) {
            [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
        }
    }
    else {
        [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
    }
}
%end

%hook GeminiSwitcherView
//checks if a hitTest is inside the bounds of a subview, namely, the geminiAdditionalView even if it is outside the bounds of its superview :)
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id orig = %orig;
    if(self == mainSwitcherVC.view) {
        if(self.clipsToBounds || self.hidden || self.alpha == 0){
            return orig;
        }
        for(UIView *subview in self.subviews.reverseObjectEnumerator) {
            if(subview == mainSwitcherVC.geminiAdditionalView){
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if(result) {
                    return result;
                }
            }
        }
    }
    return orig;
}
%end

%hook SBAppSwitcherScrollView
-(void)setContentOffset:(CGPoint)currentOffset{
    %orig;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - lastOffsetCapture;
    
    if(timeDiff > 0.1) {
        CGFloat distance = currentOffset.x - lastOffset.x;
        CGFloat scrollSpeedNotAbs = (distance * 10) / 1000;

        CGFloat scrollSpeed = fabs(scrollSpeedNotAbs);
        if (scrollSpeed > 0.5) {
            isScrollingFast = YES;
            RLog(@"SCROLLING FAST");
        }
        else {
            isScrollingFast = NO;
            RLog(@"SCROLLING SLOW");
            
            for(SBAppLayout *appLayout in mainSwitcherVC.contentViewController.visibleItemContainers.allKeys) {
                SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
                NSString *identifier = displayItem.bundleIdentifier;
                
                if(appLayout.geminiIsShowingNotifs && identifier != mainSwitcherVC.currentIdentifier) {
                    appLayout.geminiIsShowingNotifs = NO;
                }
                else if(appLayout.geminiIsShowingNotifs) {
                    continue;
                }

                if([mainSwitcherVC bundleIdentifierIsInCenterOfSwitcher:identifier]) {
                    mainSwitcherVC.currentIdentifier = identifier;
                    
                    [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
                    
                    appLayout.geminiIsShowingNotifs = YES;
                    break;
                }
                else {
                    continue;
                }
            }
            if(!mainSwitcherVC.currentIdentifier) {
                [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
            }
        }
        lastOffset = currentOffset;
        lastOffsetCapture = currentTime;
    }
}
%end

%hook SBFluidSwitcherViewController

//updates the notifications when the switcher is first opened and hasn't scrolled yet
-(void)_scrollToAppLayout:(SBAppLayout *)appLayout animated:(BOOL)animated completion:(id)completion {
    %orig;
    SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
    NSString *identifier = displayItem.bundleIdentifier;
    
    mainSwitcherVC.currentIdentifier = identifier;
    appLayout.geminiIsShowingNotifs = YES;
    RLog(@"CALLING WITH IDENT %@", identifier);
    [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
}
%end

%hook NCNotificationListView
//removes insert/remov-ing notification animations to make it look, imo, smoother when scrolling through with the notification view enabled;
-(void)insertViewAtIndex:(NSUInteger)arg1 animated:(BOOL)arg2 {
    if(mainSwitcherVC.isSmall && reduceAnimations){
        %orig(arg1, NO);
    }
    else {
        %orig;
    }
}
-(void)removeViewAtIndex:(NSUInteger)arg1 animated:(BOOL)arg2 {
    if(mainSwitcherVC.isSmall && reduceAnimations){
        %orig(arg1, NO);
    }
    else {
        %orig;
    }
}
%end
%end



%group Sylph
//Fixes Sylph bug. Thank god for hopper amirite.
%hook MediaControlsTransportStackView
-(id)_rootView {
    if([%orig isKindOfClass:%c(SBMainSwitcherWindow)]){
        return [%c(SBCoverSheetWindow) alloc];
    }
    else {
        return %orig;
    }
}
%end

%hook MediaControlsParentContainerView
-(id)_rootView {
    if([%orig isKindOfClass:%c(SBMainSwitcherWindow)]){
        return [%c(SBCoverSheetWindow) alloc];
    }
    else {
        return %orig;
    }
}
%end

%hook MediaControlsTimeControl
-(id)_rootView {
    if([%orig isKindOfClass:%c(SBMainSwitcherWindow)]){
        return [%c(SBCoverSheetWindow) alloc];
    }
    else {
        return %orig;
    }
}
%end

%hook MediaControlsHeaderView
-(id)_rootView {
    if([%orig isKindOfClass:%c(SBMainSwitcherWindow)]){
        return [%c(SBCoverSheetWindow) alloc];
    }
    else {
        return %orig;
    }
}
%end

%hook MediaControlsVolumeSlider
-(id)_rootView {
    if([%orig isKindOfClass:%c(SBMainSwitcherWindow)]){
        return [%c(SBCoverSheetWindow) alloc];
    }
    else {
        return %orig;
    }
}
%end
//End of Sylph support hooks
%end


static void loadPrefs(){
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.galacticdev.geminiprefs.plist"];
    isEnabled = prefs[@"isEnabled"] ? [prefs[@"isEnabled"] boolValue] : YES;
    reduceAnimations  = prefs[@"reduceAnimations"] ? [prefs[@"reduceAnimations"] boolValue] : NO;
    additionalViewSelection = prefs[@"additionalViewSelection"] ? [prefs[@"additionalViewSelection"] intValue] : 0;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
    
    if(mainSwitcherVC.childViewControllers.count > 1) { //removes the geminiAdditionalView and its viewcontroller so that if that setting was changed, it will immeditately apply w/o a respring
        [mainSwitcherVC.childViewControllers[1] removeFromParentViewController];
        [mainSwitcherVC.view.subviews[1] removeFromSuperview];
    }
}


%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.galacticdev.geminiprefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
    if(isEnabled) {
        %init(Main);
        if(dlopen("/Library/MobileSubstrate/DynamicLibraries/Sylph.dylib", RTLD_LAZY)) {
            %init(Sylph);
        }
    }
}
