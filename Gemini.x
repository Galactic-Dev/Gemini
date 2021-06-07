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
BOOL automaticallyPinchSwitcher;

%group Main

//fixes volume hud not showing when moduleviewcontroller is presented
%hook MediaControlsVolumeViewController
-(BOOL)isOnScreen {
    if(self.parentViewController.parentViewController == mainSwitcherVC.geminiModuleViewController) {
        return NO;
    }
    return %orig;
}
%end

//fixes music cc module not dismissing when tapped
BOOL dismissingMusicModule;
%hook MRUControlCenterViewController
-(void)dismiss {
    %orig;
    if(self.presentingViewController == mainSwitcherVC) {
        [mainSwitcherVC.geminiModuleViewController dismissPresentedContentAnimated:YES completion:^{
            [self setState:0];
        }];
    }
}
-(void)setState:(NSInteger)arg1 {
    if(dismissingMusicModule) {
        %orig(0);
        dismissingMusicModule = NO;
        return;
    }
    %orig;
}
%end

%hook CCUIModuleCollectionView
-(CGSize)intrinsicContentSize {
    CGSize size = %orig;
    if(self == mainSwitcherVC.geminiModuleViewController.view) {
        switch(additionalViewSelection) {
            case 1: {
                if(mainSwitcherVC.geminiAdditionalView.class == [UIScrollView class]) {
                    [self.heightAnchor constraintEqualToConstant:size.height].active = YES;
                    [(UIScrollView *)mainSwitcherVC.geminiAdditionalView setContentSize:size];
                }
                break;
            }
            case 2: {
                [self.heightAnchor constraintEqualToConstant:size.height].active = YES;
                //[(UIScrollView *)self.superview.superview setContentSize:size];
                break;
            }
            default: {
                break;
            }
        }
    }
    return size;
}
-(void)addSubview:(UIView *)subview {
    %orig;
    if(additionalViewSelection == 2 && mainSwitcherVC.geminiModuleViewController.view == self) {
        subview.transform = CGAffineTransformMakeScale(0.95,0.95);
    }
}
-(id)layoutSource {
    if(additionalViewSelection == 2 && mainSwitcherVC.geminiModuleViewController.view == self) {
        CCUILayoutOptions *layoutOptions = [self valueForKey:@"_layoutOptions"];
        [layoutOptions setValue:@5 forKey:@"_itemSpacing"];
    }

    return %orig;
}
-(void)setEdgeInsets:(UIEdgeInsets)arg1 {
    if(additionalViewSelection == 2 && mainSwitcherVC.geminiModuleViewController.view == self) {
        %orig(UIEdgeInsetsMake(5,arg1.left/2,10,0));
    }
    else {
        %orig;
    }
}
%end

%hook CCUIModuleCollectionViewController
//adds a blur view to the switcher when presenting an expanded module vc
-(void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(id)completion {
    if(self == mainSwitcherVC.geminiModuleViewController) {
        [mainSwitcherVC showGeminiBlurView:YES makeTopMostView:YES];
    }
    %orig;
}

//fixes weird animation issues by just... causing it not to animate;
-(void)dismissExpandedModuleAnimated:(BOOL)arg1 completion:(id)arg2 {
    if(self != mainSwitcherVC.geminiModuleViewController) {
        %orig;
        return;
    }
    if(!mainSwitcherVC.geminiHasExpandedDynamicView) {
        [mainSwitcherVC showGeminiBlurView:NO makeTopMostView:YES];
    }
    else {
        [mainSwitcherVC showGeminiBlurView:YES makeTopMostView:NO];
        mainSwitcherVC.geminiBlurView.alpha = 0.2;
    }
    %orig(NO, arg2);
}
-(void)dismissPresentedContentAnimated:(BOOL)arg1 completion:(id)arg2 {
    if(self != mainSwitcherVC.geminiModuleViewController) {
        %orig;
        return;
    }
    
    if(self.presentedViewController.childViewControllers[0].class == %c(MRUControlCenterViewController)) {
        dismissingMusicModule = YES;
    }
    
    if(!mainSwitcherVC.geminiHasExpandedDynamicView) {
        [mainSwitcherVC showGeminiBlurView:NO makeTopMostView:YES];
    }
    else {
        [mainSwitcherVC showGeminiBlurView:YES makeTopMostView:NO];
        mainSwitcherVC.geminiBlurView.alpha = 0.2;
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
%property (strong, nonatomic) UIVisualEffectView *geminiBlurView;
%property (nonatomic, assign) BOOL geminiHasExpandedDynamicView;
%property (strong, nonatomic) NSLayoutConstraint *geminiExpandedCenterYAnchor;
%property (strong, nonatomic) NSLayoutConstraint *geminiExpandedHeightAnchor;
%property (strong, nonatomic) NSLayoutConstraint *geminiDynamicHeightAnchor;

-(void)viewDidLoad {
    %orig;
    mainSwitcherVC = self;
    self.isSmall = NO;

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
    if(TARGET_OS_SIMULATOR) {
        if(self.geminiAdditionalView.subviews.count > 0) {
            [self.geminiAdditionalView.subviews[0] removeFromSuperview];
        }
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,300,100)];
        label.text = identifier;
        [self.geminiAdditionalView addSubview:label];
    }
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval timeDiff = currentTime - lastOffsetCaptured;
    if(timeDiff <= 0.1) {
        //return;
    }

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
                    
                    if([UIDevice.currentDevice isNotched]) {
                        [self.geminiStructuredListViewController.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-75].active = YES;
                    }
                    else {
                        [self.geminiStructuredListViewController.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-50].active = YES;
                    }
                    
                    [self.geminiStructuredListViewController.view.heightAnchor constraintEqualToConstant:height].active = YES;
                    [self.geminiStructuredListViewController.view.widthAnchor constraintEqualToConstant:self.geminiStructuredListViewController.view.frame.size.width].active = YES;
                    
                    [self.geminiStructuredListViewController.masterListView.topAnchor constraintEqualToAnchor:self.geminiStructuredListViewController.view.topAnchor].active = YES;
                    [self.geminiStructuredListViewController.masterListView.heightAnchor constraintEqualToConstant:height].active = YES;

                    [self.geminiStructuredListViewController.masterListView.widthAnchor constraintEqualToConstant:self.geminiStructuredListViewController.masterListView.frame.size.width].active = YES;
                    
                    self.geminiAdditionalView = self.geminiStructuredListViewController.view;

                    self.geminiStructuredListViewController.delegate = notifVC.delegate;
                    self.geminiStructuredListViewController.deviceAuthenticated = YES;
                    self.geminiAdditionalView.clipsToBounds = YES;

                    [self insertNotificationsForBundleIdentifier:self.currentIdentifier]; //don't delete this it makes notifs insert when first pinching switcher
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
                    
                    if([UIDevice.currentDevice isNotched]) {
                        [scrollView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-75].active = YES;
                    }
                    else {
                        [scrollView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-50].active = YES;
                    }
                    
                    [scrollView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
                    
                    [self.geminiModuleViewController.view.heightAnchor constraintEqualToConstant:self.geminiModuleViewController.view.intrinsicContentSize.height].active = YES;
                    [self.geminiModuleViewController.view.topAnchor constraintEqualToAnchor:scrollView.topAnchor].active = YES;
                    
                    self.geminiAdditionalView = scrollView;
                    break;
                }
                case 2: {
                    //dynamic
                    
                    //setup the views contained in the dynamic view
                    //notif setup
                    self.geminiStructuredListViewController = [[%c(NCNotificationStructuredListViewController) alloc] init];

                    [self addChildViewController:self.geminiStructuredListViewController];
                    self.geminiStructuredListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
                    self.geminiStructuredListViewController.masterListView.translatesAutoresizingMaskIntoConstraints = NO;
                    self.geminiStructuredListViewController.delegate = notifVC.delegate;
                    self.geminiStructuredListViewController.deviceAuthenticated = YES;
                    self.geminiStructuredListViewController.view.userInteractionEnabled = NO;
                    
                    //cc setup
                    SBControlCenterSystemAgent *systemAgent = [[%c(SBControlCenterSystemAgent) alloc] init];
                    CCUIModuleInstanceManager *moduleInstanceManager = [[%c(CCUIModuleInstanceManager) alloc] _initWithSystemAgent:systemAgent repository:[%c(CCSModuleRepository) repositoryWithDefaults]];
                    
                    self.geminiModuleViewController = [[%c(CCUIModuleCollectionViewController) alloc] initWithModuleInstanceManager:moduleInstanceManager];
                    self.geminiModuleViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
                    [mainSwitcherVC addChildViewController:self.geminiModuleViewController];
                                    
                    //setup the background view
                    UIVisualEffect *blurEffect;
                    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

                    UIVisualEffectView *dynamicContainerView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                    dynamicContainerView.layer.cornerRadius = 20;
                    dynamicContainerView.clipsToBounds = YES;
                    dynamicContainerView.translatesAutoresizingMaskIntoConstraints = NO;
                    [self.view addSubview:dynamicContainerView];
                    [dynamicContainerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-36].active = YES;
                    
                    CGFloat switcherHeight = self.view.frame.size.height * 0.75;
                    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                    CGFloat height = (screenHeight - switcherHeight) + 100;
                    self.geminiDynamicHeightAnchor = [dynamicContainerView.heightAnchor constraintEqualToConstant:height];
                    self.geminiDynamicHeightAnchor.active = YES;
                    [dynamicContainerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
                    if([UIDevice.currentDevice isNotched]) {
                        [dynamicContainerView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-90].active = YES;
                    }
                    else {
                        [dynamicContainerView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-65].active = YES;
                    }
                    self.geminiAdditionalView = dynamicContainerView;
                    
                    UIScrollView *dynamicScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
                    dynamicScrollView.translatesAutoresizingMaskIntoConstraints = NO;
                                        
                    UIStackView *dynamicStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.geminiModuleViewController.view, self.geminiStructuredListViewController.view]];
                    dynamicStackView.translatesAutoresizingMaskIntoConstraints = NO;

                    
                    [dynamicScrollView addSubview:dynamicStackView];
                    dynamicStackView.axis = UILayoutConstraintAxisHorizontal;
                    dynamicScrollView.pagingEnabled = YES;
                    [dynamicContainerView.contentView addSubview:dynamicScrollView];
                    
                    //gesture recognizer setup
                    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
                    doubleTap.numberOfTapsRequired = 2;
                    doubleTap.cancelsTouchesInView = NO;
                    [dynamicStackView addGestureRecognizer:doubleTap];
                    
                    
                    //constraints
                    [dynamicScrollView.widthAnchor constraintEqualToAnchor:dynamicContainerView.widthAnchor].active = YES;
                    [dynamicScrollView.heightAnchor constraintEqualToAnchor:dynamicContainerView.heightAnchor].active = YES;
                    
                    [dynamicScrollView.topAnchor constraintEqualToAnchor:dynamicContainerView.topAnchor].active = YES;
                    
                    [dynamicScrollView.centerXAnchor constraintEqualToAnchor:dynamicContainerView.centerXAnchor].active = YES;
                    
                    [dynamicStackView.heightAnchor constraintEqualToAnchor:dynamicContainerView.heightAnchor].active = YES;
                    [dynamicStackView.topAnchor constraintEqualToAnchor:dynamicScrollView.topAnchor].active = YES;
                    [dynamicStackView.leadingAnchor constraintEqualToAnchor:dynamicScrollView.leadingAnchor constant:0].active = YES;
                    
                    [self.geminiModuleViewController.view.widthAnchor constraintEqualToAnchor:dynamicContainerView.widthAnchor constant:0].active = YES;
                    
                    [self.geminiStructuredListViewController.view.heightAnchor constraintEqualToAnchor:dynamicContainerView.heightAnchor].active = YES;
                    [self.geminiStructuredListViewController.view.widthAnchor constraintEqualToAnchor:dynamicContainerView.widthAnchor].active = YES;
                    [self.geminiStructuredListViewController.view.topAnchor constraintEqualToAnchor:dynamicContainerView.topAnchor constant:10].active = YES;
                    [self.geminiModuleViewController.view.topAnchor constraintEqualToAnchor:dynamicContainerView.topAnchor constant:-2.5].active = YES;

                    
                    [self.geminiStructuredListViewController.masterListView.topAnchor constraintEqualToAnchor:self.geminiStructuredListViewController.view.topAnchor].active = YES;
                    [self.geminiStructuredListViewController.masterListView.heightAnchor constraintEqualToAnchor:dynamicContainerView.heightAnchor].active = YES;
                    [self.geminiStructuredListViewController.masterListView.widthAnchor constraintEqualToAnchor:dynamicContainerView.widthAnchor].active = YES;
                    self.geminiAdditionalView.clipsToBounds = YES;
                    
                    CGFloat switcherWidth = self.view.frame.size.width;
                    CGFloat width = switcherWidth - 36;
                    dynamicScrollView.contentSize = CGSizeMake(width * 2, 0);
                    
                    dynamicScrollView.showsHorizontalScrollIndicator = NO;
                    [(UIScrollView *)self.geminiModuleViewController.view setScrollEnabled:NO];
                    [self insertNotificationsForBundleIdentifier:self.currentIdentifier]; //don't delete this btw it makes things work
                    break;
                }
                default: {
                    break;
                }
            }
            
            //this is for testing how the additional view will look on different sized devices
            if(TARGET_OS_SIMULATOR) {
                UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
                view.backgroundColor = UIColor.redColor;
                [self.view addSubview:view];
                
                view.translatesAutoresizingMaskIntoConstraints = NO;
                
                CGFloat switcherHeight = (self.view.frame.size.height ) * 0.75;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                CGFloat height = (screenHeight - switcherHeight) + 100;
                if([UIDevice.currentDevice isNotched]) {
                    [view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-75].active = YES;
                }
                else {
                    [view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-50].active = YES;
                }
                
                [view.widthAnchor constraintEqualToConstant:self.view.frame.size.width].active = YES;
                [view.heightAnchor constraintEqualToConstant:height].active = YES;
                self.geminiAdditionalView = view;
            }
            
        }

        for(UIViewController *childViewController in self.geminiModuleViewController.childViewControllers) {
            if(childViewController.childViewControllers.count > 0) {
                UIViewController *childChildViewController = childViewController.childViewControllers[0];
                [childChildViewController viewWillAppear:NO];
                
                if([childChildViewController respondsToSelector:@selector(setState:)]) { //fixes music player being a weird size when dismissed
                    [childChildViewController performSelector:@selector(setState:) withObject:nil]; //ew this is gross but whatever ill get a better way eventually
                }
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
%new -(void)handleTap:(UITapGestureRecognizer *)tap {
    self.geminiHasExpandedDynamicView = YES;
    [self showGeminiBlurView:YES makeTopMostView:NO];
    self.geminiBlurView.alpha = 0.2;
    
    [(UIScrollView *)self.geminiModuleViewController.view setScrollEnabled:YES];
    self.geminiStructuredListViewController.view.userInteractionEnabled = YES;

    
    //gesture recognizer setup
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissExpandedDynamicView)];
    [self.geminiBlurView addGestureRecognizer:singleTap];
    
    [self.geminiAdditionalView layoutIfNeeded];
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^(void) {
        self.geminiExpandedCenterYAnchor = [self.geminiAdditionalView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:100];
        self.geminiExpandedCenterYAnchor.active = YES;
        self.geminiDynamicHeightAnchor.active = NO;
        
        CGFloat switcherHeight = self.view.frame.size.height;
        CGFloat height = switcherHeight;
        self.geminiExpandedHeightAnchor = [self.geminiAdditionalView.heightAnchor constraintEqualToConstant:height];
        self.geminiExpandedHeightAnchor.active = YES;
        [self.geminiAdditionalView setNeedsLayout];
        [self.geminiAdditionalView layoutIfNeeded];
    } completion:nil];
}

%new -(void)dismissExpandedDynamicView {
    [(UIScrollView *)self.geminiModuleViewController.view setScrollEnabled:NO];
    self.geminiStructuredListViewController.view.userInteractionEnabled = NO;

    [self.geminiAdditionalView layoutIfNeeded];
    [self showGeminiBlurView:NO makeTopMostView:NO];
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^(void) {
        self.geminiExpandedHeightAnchor.active = NO;
        self.geminiDynamicHeightAnchor.active = YES;

        [self.geminiAdditionalView setNeedsLayout];
        [self.geminiAdditionalView layoutIfNeeded];
    } completion:nil];
    [self.geminiAdditionalView layoutIfNeeded];
    [UIView animateWithDuration:0.1 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
        self.geminiExpandedCenterYAnchor.active = NO;
        [self.geminiAdditionalView setNeedsLayout];
        [self.geminiAdditionalView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.geminiHasExpandedDynamicView = NO;
    }];
}


%new -(void)showGeminiBlurView:(BOOL)shouldShow makeTopMostView:(BOOL)shouldMakeTopMost {
    if(!self.geminiBlurView) {
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        mainSwitcherVC.geminiBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        mainSwitcherVC.geminiBlurView.frame = CGRectMake(-1000,-200,2000,2000); //why why why why why
    }
    
    if(shouldShow) {
        self.geminiBlurView.alpha = 0;
        if(!shouldMakeTopMost) {
            [self.view insertSubview:self.geminiBlurView atIndex:1];
        }
        else {
            [self.view addSubview:self.geminiBlurView];
        }
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            self.geminiBlurView.alpha = 1;
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            mainSwitcherVC.geminiBlurView.alpha = 0;
        } completion:^(BOOL finished){
            [self.geminiBlurView removeFromSuperview];
        }];
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
        if (mainSwitcherVC.isSmall){
            mainSwitcherVC.view.frame = CGRectMake(mainSwitcherVC.view.frame.origin.x, mainSwitcherVC.view.frame.origin.y + 100, mainSwitcherVC.view.frame.size.width, mainSwitcherVC.view.frame.size.height);
            mainSwitcherVC.view.transform = CGAffineTransformMakeScale(1, 1);
            mainSwitcherVC.isSmall = NO;
            mainSwitcherVC.currentIdentifier = nil;
            [mainSwitcherVC.geminiModuleViewController dismissPresentedContentAnimated:YES completion:nil];
            if(additionalViewSelection == 2) {
                [mainSwitcherVC dismissExpandedDynamicView];
            }
        }
        mainSwitcherVC.geminiAdditionalView.alpha = 0;
        mainSwitcherVC.geminiAdditionalView.transform = CGAffineTransformMakeScale(0.1,0.1);
    }
    if(arg1 == 2 && automaticallyPinchSwitcher) {
        [mainSwitcherVC handlePinch:nil];
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
    /*if([self respondsToSelector:@selector(axnAllowChanges)]) {
        if(self.axnAllowChanges) {
            [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
        }
    }
    else {*/
        [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
    //}
}
-(void)removeNotificationRequest:(id)arg1 {
    %orig;
    /*if([self respondsToSelector:@selector(axnAllowChanges)]) {
        if(self.axnAllowChanges) {
            [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
        }
    }
    else {*/
        [mainSwitcherVC insertNotificationsForBundleIdentifier:mainSwitcherVC.currentIdentifier];
    //}
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
            if(mainSwitcherVC.geminiHasExpandedDynamicView && subview == mainSwitcherVC.geminiBlurView) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if(result) {
                    return result;
                }
            }
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
        }
        else {
            isScrollingFast = NO;
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

//fixes notification bug where notifications wouldn't show until you start to swipe :)
-(void)_updateVisibleViewsForUpdatedVisibleRect:(CGRect)rect {
    if(mainSwitcherVC.isSmall) {
        %orig(mainSwitcherVC.geminiStructuredListViewController.view.bounds);
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
    
    automaticallyPinchSwitcher = prefs[@"automaticallyPinchSwitcher"] ? [prefs[@"automaticallyPinchSwitcher"] boolValue] : NO;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
    
    if(mainSwitcherVC.childViewControllers.count > 1) { //removes the geminiAdditionalView and its viewcontroller so that if that setting was changed, it will immeditately apply w/o a respring
        for(UIViewController *viewController in mainSwitcherVC.childViewControllers.copy) {
            if(viewController.class != %c(SBDeckSwitcherViewController)) {
                [viewController removeFromParentViewController];
            }
        }
        for(int i = 0; i < mainSwitcherVC.view.subviews.count; i++) {
            if(i > 0){
                [mainSwitcherVC.view.subviews[i] removeFromSuperview];
            }
        }
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
