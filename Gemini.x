#import "Gemini.h"

NSUInteger contentOrientation;
NCNotificationStructuredListViewController *notifVC;
NSMutableArray *removedRequests;
SBMainSwitcherViewController *mainSwitcherVC;
NSMutableArray<SBFluidSwitcherItemContainerHeaderView *> *headerViews;
long long environmentMode;

//sbappswitcherscrollview stuff
CGPoint lastOffset;
NSTimeInterval lastOffsetCapture;
BOOL isScrollingFast;

//PREFERENCES:
BOOL isEnabled;
BOOL reduceAnimations;

%group Main
%hook CCUIModuleCollectionViewController
-(void)dismissExpandedModuleAnimated:(BOOL)arg1 completion:(id)arg2 {
    %orig(NO, arg2);
}
-(void)dismissPresentedContentAnimated:(BOOL)arg1 completion:(id)arg2 {
    %orig(NO, arg2);
}
-(void)addChildViewController:(UIViewController *)viewController {
    %orig;
    [viewController.childViewControllers[0] viewWillAppear:NO];
}
%end

%hook AXNManager
-(void)setClvc:(id)arg1 {
    if(![self valueForKey:@"_clvc"]) {
        %orig;
    }
}
%end

%hook SBMainSwitcherViewController
%property (nonatomic, assign) BOOL isSmall;
%property (strong, nonatomic) CCUIModuleCollectionViewController *moduleViewController;
%property (strong, nonatomic) NCNotificationStructuredListViewController *structuredListViewController;
%property (strong, nonatomic) UIView *geminiAdditionalView;
-(void)viewDidLoad {
  %orig;
  mainSwitcherVC = self;

  //replaces the mainSwitcherVC's view with a custom UIView subclass so that I can override the hitTest:withEvent: method
  NSArray *subviews = self.view.subviews;
  self.view = [[GeminiSwitcherView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
  for(UIView *subview in subviews){
    [self.view addSubview:subview];
  }

  //add pinch recognizer
  UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
  [self.view addGestureRecognizer:pinchRecognizer];

  //adds notif observer for the "Test Notifications" button in prefs
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(GMNShowTestNotifications) name:@"com.galacticdev.gemini/showTestNotifications" object:nil];
}
-(void)_setContentOrientation:(long long)arg1 forContentViewController:(id)arg2 {
  %orig;
  contentOrientation = arg1;
}
%new -(void)insertNotificationsForBundleIdentifier:(NSString *)identifier {
    AXNManager *axonManager = [%c(AXNManager) sharedInstance];

    
    NSMutableArray *requests = [NSMutableArray array];
    NSMutableArray *oldRequests = [NSMutableArray array];
    
    for(NSString *identifier in axonManager.names.allKeys) {
        [requests addObjectsFromArray:[axonManager requestsForBundleIdentifier:identifier]];
    }

    for(NCNotificationStructuredSectionList *sectionList in self.structuredListViewController.masterList.notificationSections) {
        [oldRequests addObjectsFromArray:[sectionList allNotificationRequests]];
    }
    for(NCNotificationStructuredSectionList *sectionList in notifVC.masterList.notificationSections) {
        [requests addObjectsFromArray:[sectionList allNotificationRequests]];
    }

    for(id request in oldRequests) {
        if(![requests containsObject:request]) {
            [self.structuredListViewController.masterList.notificationSections[0] removeNotificationRequest:request];
        }
    }
    
    for(int i = 0; i < requests.count; i++) {
        [self.structuredListViewController.masterList.notificationSections[0] insertNotificationRequest:requests[i]];
    }
    self.structuredListViewController.masterList.notificationSections[1].revealHintView.hidden = YES;
}
%new
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture {
  if(pinchGesture.scale <= 0.75 && !self.isSmall && contentOrientation == 1 && environmentMode == 2) {
      if(self.childViewControllers.count < 2) {
          /*
          SBControlCenterSystemAgent *systemAgent = [[%c(SBControlCenterSystemAgent) alloc] init];
          CCUIModuleInstanceManager *moduleInstanceManager = [[%c(CCUIModuleInstanceManager) alloc] _initWithSystemAgent:systemAgent repository:[%c(CCSModuleRepository) repositoryWithDefaults]];
          self.moduleViewController = [[%c(CCUIModuleCollectionViewController) alloc] initWithModuleInstanceManager:moduleInstanceManager];
         [mainSwitcherVC addChildViewController:self.moduleViewController];
          UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.moduleViewController.view.frame];
          [scrollView addSubview:self.moduleViewController.view];
          scrollView.translatesAutoresizingMaskIntoConstraints = NO;
          [mainSwitcherVC.view addSubview:scrollView];
          self.moduleViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
          [scrollView.widthAnchor constraintEqualToConstant:self.moduleViewController.view.frame.size.width].active = YES;
          [scrollView.heightAnchor constraintEqualToConstant:400].active = YES;
          [scrollView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-100].active = YES;
          [scrollView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
          [self.moduleViewController.view.heightAnchor constraintEqualToConstant:1024].active = YES;
          [self.moduleViewController.view.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:60].active = YES;
          scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, 1024);
           self.geminiAdditionalView = scrollView;
           */
          
          
          self.structuredListViewController = [[%c(NCNotificationStructuredListViewController) alloc] init];


          [self addChildViewController:self.structuredListViewController];
          [self.view addSubview:self.structuredListViewController.view];
          self.structuredListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
          [self.structuredListViewController.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
          [self.structuredListViewController.view.heightAnchor constraintEqualToConstant:self.structuredListViewController.view.frame.size.height].active = YES;
          [self.structuredListViewController.view.widthAnchor constraintEqualToConstant:self.structuredListViewController.view.frame.size.width].active = YES;
          self.geminiAdditionalView = self.structuredListViewController.view;
          
          self.structuredListViewController.delegate = notifVC.delegate;
          self.structuredListViewController.deviceAuthenticated = YES;
          self.geminiAdditionalView.clipsToBounds = YES;
          
          [self insertNotificationsForBundleIdentifier:nil];
        }
      
      
      for(UIViewController *childViewController in self.moduleViewController.childViewControllers) {
          UIViewController *childChildViewController = childViewController.childViewControllers[0];
          [childChildViewController viewWillAppear:NO];
          if([childChildViewController respondsToSelector:@selector(setState:)]) {
              [childChildViewController performSelector:@selector(setState:) withObject:nil]; //ew this is gross but whatever ill get a better way eventually
          }
      }

      
      
      [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
          self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 100, self.view.frame.size.width, self.view.frame.size.height);
          self.view.transform = CGAffineTransformMakeScale(.75, .75);
          [notifVC revealNotificationHistory:YES animated:NO];
          for(int i = 0; i < [notifVC.masterList.notificationSections count]; i++) {
              NCNotificationStructuredSectionList *notifList = notifVC.masterList.notificationSections[i];
              [notifList.sectionListView setRevealed:YES];

              notifList.sectionListView.frame = CGRectMake(notifList.sectionListView.frame.origin.x, notifList.sectionListView.frame.origin.y /*+ 643*/, notifList.sectionListView.frame.size.width, notifList.sectionListView.frame.size.height);

              self.geminiAdditionalView.transform = CGAffineTransformMakeScale(1.25,1.25);


              [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
                  self.geminiAdditionalView.alpha = 1;
              } completion:nil];

              for(SBFluidSwitcherItemContainerHeaderView *headerView in headerViews.reverseObjectEnumerator){
                  if(headerView.textAlpha > 0.9 && !headerView.showingNotifs){
                      [notifVC revealNotificationHistory:YES animated:NO];
                      [notifList.sectionListView setRevealed:YES];
                      NSArray *allNotificationRequests = [notifList allNotificationRequests];
                      SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)headerView.superview;
                      SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
                      SBAppLayout *appLayout = snapshotView.appLayout;
                      SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
                      NSString *identifier = displayItem.bundleIdentifier;
                      AXNManager *axonManager = [%c(AXNManager) sharedInstance];
                      [axonManager showNotificationRequestsForBundleIdentifier:identifier];
                      [notifList.sectionListView setRevealed:YES];

                      //removes notifications that aren't a certain app
                      for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
                          if(![notificationRequest.sectionIdentifier isEqualToString:identifier]) {
                              [removedRequests addObject:notificationRequest];
                              [notifVC removeNotificationRequest:notificationRequest];
                          }
                      }

                      //inserts removed notifications back into the notification center
                      NSMutableArray *notifsToAddBack = [NSMutableArray array];
                      for(NCNotificationRequest *notificationRequest in removedRequests) {
                          if([notificationRequest.sectionIdentifier isEqualToString:identifier]){
                              [notifVC insertNotificationRequest:notificationRequest];
                              [notifsToAddBack addObject:notificationRequest];
                          }
                      }
                      for(NCNotificationRequest *notificationRequest in notifsToAddBack) {
                          [removedRequests removeObject:notificationRequest];
                      }
                      headerView.showingNotifs = YES;
                      break;
                  }
              }
          }
          return;
      } completion:nil];
      mainSwitcherVC.isSmall = YES;
  }
  else if(pinchGesture.scale >= 1.0 && mainSwitcherVC.isSmall && contentOrientation == 1) {
      [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
          self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 100, self.view.frame.size.width, self.view.frame.size.height);
          self.view.transform = CGAffineTransformMakeScale(1, 1);
          self.geminiAdditionalView.alpha = 0;
          return;
      } completion:nil];
      mainSwitcherVC.isSmall = NO;
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
                                                    soundName:nil //research UNNotificationSound
                                                        delay:1.00 //cannot be zero & cannot be < 60 if repeats is YES
                                                      repeats:NO
                                                     bundleId:identifier
                                                         uuid:uid //specify if you need to use hideAlertWithBundleId and store the string for later use
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
    if (arg1 != 2 && contentOrientation == 1){
        mainSwitcherVC = [%c(SBMainSwitcherViewController) sharedInstance];
        if (mainSwitcherVC.isSmall){
            mainSwitcherVC.view.frame = CGRectMake(mainSwitcherVC.view.frame.origin.x, mainSwitcherVC.view.frame.origin.y + 100, mainSwitcherVC.view.frame.size.width, mainSwitcherVC.view.frame.size.height);
            mainSwitcherVC.view.transform = CGAffineTransformMakeScale(1, 1);
            mainSwitcherVC.isSmall = NO;
        }
        mainSwitcherVC.geminiAdditionalView.alpha = 0;
    }
}
%end

%hook SBFluidSwitcherItemContainerHeaderView
%property (nonatomic,assign) BOOL showingNotifs;
-(id)initWithFrame:(CGRect)arg1 {
    [headerViews addObject:self];
    return %orig;
}
-(void)setTextAlpha:(CGFloat)arg1 {
  %orig;
  if(arg1 >= 0.9 && ![self showingNotifs] && mainSwitcherVC.isSmall && !isScrollingFast) {

      //for(NCNotificationStructuredSectionList *notifList in notifVC.masterList.notificationSections) {
        //[notifVC revealNotificationHistory:YES animated:NO];
        //[notifList.sectionListView setRevealed:YES];
        /*SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)self.superview;
        SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
        SBAppLayout *appLayout = snapshotView.appLayout;
        SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
        NSString *identifier = displayItem.bundleIdentifier;
        AXNManager *axonManager = [%c(AXNManager) sharedInstance];
        [axonManager showNotificationRequestsForBundleIdentifier:identifier];
        allNotificationRequests  = [NSMutableArray array];
        for(NCNotificationStructuredSectionList *notifList in notifVC.masterList.notificationSections){
          for(id req in notifList.allNotificationRequests){
            [allNotificationRequests addObject:req];
            [notifList.sectionListView setRevealed:YES];
          }
        }
        //inserts removed notifications back into the notification center
        NSMutableArray *notifsToAddBack = [NSMutableArray array];
        for(NCNotificationRequest *notificationRequest in removedRequests) {
          if([notificationRequest.sectionIdentifier isEqualToString:identifier]){
            [notifVC insertNotificationRequest:notificationRequest];
            [notifsToAddBack addObject:notificationRequest];
          }
        }
        for(NCNotificationRequest *notificationRequest in notifsToAddBack) {
          [removedRequests removeObject:notificationRequest];
        }

        BOOL axnAllowChangesOld;
        if([notifVC respondsToSelector:@selector(axnAllowChanges)]){
          axnAllowChangesOld = notifVC.axnAllowChanges;
          notifVC.axnAllowChanges = YES;
        }
        //removes notifications that aren't a certain app
        for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
          if(![notificationRequest.sectionIdentifier isEqualToString:identifier]) {
            [removedRequests addObject:notificationRequest];
            [notifVC removeNotificationRequest:notificationRequest];
          }
        }
        if([notifVC respondsToSelector:@selector(axnAllowChanges)]){
          notifVC.axnAllowChanges = axnAllowChangesOld;
        }
      //}
      self.showingNotifs = YES;*/
  //}
      /*
  else if (arg1 < 0.9 && [self showingNotifs]){
    if(![notifVC respondsToSelector:@selector(axnAllowChanges)]) {
      allNotificationRequests  = [NSMutableArray array];
      for(NCNotificationStructuredSectionList *notifList in notifVC.masterList.notificationSections){
        for(id req in notifList.allNotificationRequests){
          [allNotificationRequests addObject:req];
        }
      }
      SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)self.superview;
      SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
      SBAppLayout *appLayout = snapshotView.appLayout;
      SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
      NSString *identifier = displayItem.bundleIdentifier;
      for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
        if([notificationRequest.sectionIdentifier isEqualToString:identifier]) {
          [removedRequests addObject:notificationRequest];
          [notifVC removeNotificationRequest:notificationRequest];
        }
      }
    }

    self.showingNotifs = NO;*/
  }
}
%end

%hook NCNotificationStructuredListViewController
-(id)init {
    if(!notifVC) notifVC = self;
    return %orig;
}
-(void)insertNotificationRequest:(id)arg1 {
    %orig;
    [mainSwitcherVC insertNotificationsForBundleIdentifier:nil];
}
-(void)removeNotificationRequest:(id)arg1 {
    %orig;
    [mainSwitcherVC insertNotificationsForBundleIdentifier:nil];
}
%end

%hook GeminiSwitcherView
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
-(void)setContentOffset:(CGPoint)arg1{
    %orig;
    CGPoint currentOffset = arg1;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

    NSTimeInterval timeDiff = currentTime - lastOffsetCapture;
    if(timeDiff > 0.1) {
        CGFloat distance = currentOffset.x - lastOffset.x;
        CGFloat scrollSpeedNotAbs = (distance * 10) / 1000;

        CGFloat scrollSpeed = fabs(scrollSpeedNotAbs);
        if (scrollSpeed > 0.5) {
            isScrollingFast = YES;
        } else {
            isScrollingFast = NO;
            if(mainSwitcherVC.isSmall && notifVC.view.hidden){
            }
            /*for(NCNotificationStructuredSectionList *notifList in notifVC.masterList.notificationSections){
              for(SBFluidSwitcherItemContainerHeaderView *headerView in headerViews.reverseObjectEnumerator){
                if(headerView.textAlpha > 0.9 && !headerView.showingNotifs){
                  [notifVC revealNotificationHistory:YES animated:NO];
                  [notifList.sectionListView setRevealed:YES];
                  NSArray *allNotificationRequests = [notifList allNotificationRequests];
                  SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)headerView.superview;
                  SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
                  SBAppLayout *appLayout = snapshotView.appLayout;
                  SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
                  NSString *identifier = displayItem.bundleIdentifier;
                  AXNManager *axonManager = [%c(AXNManager) sharedInstance];
                  [axonManager showNotificationRequestsForBundleIdentifier:identifier];
                  [notifList.sectionListView setRevealed:YES];
                  if(!identifier){
                    continue;
                  }
                  //removes notifications that aren't a certain app
                  for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
                    if(![notificationRequest.sectionIdentifier isEqualToString:identifier]) {
                      [removedRequests addObject:notificationRequest];
                      [notifVC removeNotificationRequest:notificationRequest];
                    }
                  }

                  //inserts removed notifications back into the notification center
                  NSMutableArray *notifsToAddBack = [NSMutableArray array];
                  for(NCNotificationRequest *notificationRequest in removedRequests) {
                    if([notificationRequest.sectionIdentifier isEqualToString:identifier]){
                      [notifVC insertNotificationRequest:notificationRequest];
                      [notifsToAddBack addObject:notificationRequest];
                    }
                  }
                  for(NCNotificationRequest *notificationRequest in notifsToAddBack) {
                    [removedRequests removeObject:notificationRequest];
                  }
                  headerView.showingNotifs = YES;
                  break;
                }
              }
            }*/
        }

        lastOffset = currentOffset;
        lastOffsetCapture = currentTime;
    }
}

-(void)_setScrolling:(BOOL)arg1 {
    %orig;
    if(isScrollingFast && mainSwitcherVC.isSmall && !arg1){
        
    }
    
    if(!arg1){

    }
}
%end

%hook NCNotificationListView
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

%hook AXNManager
-(void)showNotificationRequest:(id)arg1 {
    %orig;
}
%end

%hook SBFluidSwitcherAnimationSettings
-(void)setStackedSwitcherTrackingSettings:(id)arg1 {
    %orig(nil);
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
    isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
    reduceAnimations  = [prefs objectForKey:@"reduceAnimations"] ? [[prefs objectForKey:@"reduceAnimations"] boolValue] : NO;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
}


%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.galacticdev.geminiprefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    if(isEnabled) {
        %init(Main);
        headerViews = [NSMutableArray array];
        removedRequests = [NSMutableArray array];
    }
    if(dlopen("/Library/MobileSubstrate/DynamicLibraries/Sylph.dylib", RTLD_LAZY)) {
        %init(Sylph);
    }
}
