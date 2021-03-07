#import "Gemini.h"

NSUInteger contentOrientation;
NSMutableArray<NCNotificationStructuredSectionList *> *notifLists;
NCNotificationStructuredListViewController *notifVC;
UIView *notifSuperview;
NSMutableArray *removedRequests;
SBMainSwitcherViewController *mainSwitcherVC;
NSMutableArray<SBFluidSwitcherItemContainerHeaderView *> *headerViews;
UIViewController *notifParentVC;
CSCombinedListViewController *combinedListVC;
NSMutableArray *adjunctListViews;
CSNotificationAdjunctListViewController *adjunctListViewController;
long long environmentMode;
CGFloat topValue;
NSMutableArray *allNotificationRequests;

//sbappswitcherscrollview stuff
CGPoint lastOffset;
NSTimeInterval lastOffsetCapture;
BOOL isScrollingFast;

//PREFERENCES:
BOOL isEnabled;
BOOL reduceAnimations;

%hook SBMainSwitcherViewController
%property (nonatomic, assign) BOOL isSmall;
%property (nonatomic, retain) UIView *geminiScrollView;
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

%new
-(void)handlePinch:(UIPinchGestureRecognizer *)pinchGesture {
  if(pinchGesture.scale <= 0.75 && !self.isSmall && contentOrientation == 1 && environmentMode == 2) {
    [mainSwitcherVC addChildViewController:notifVC];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
      self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 100, self.view.frame.size.width, self.view.frame.size.height);
      self.view.transform = CGAffineTransformMakeScale(.75, .75);
          [notifVC revealNotificationHistory:YES animated:NO];
          for(int i = 0; i < [notifLists count]; i++) {
            NCNotificationStructuredSectionList *notifList = notifLists[i];
            [notifList.sectionListView setRevealed:YES];

            notifList.sectionListView.frame = CGRectMake(notifList.sectionListView.frame.origin.x, notifList.sectionListView.frame.origin.y /*+ 643*/, notifList.sectionListView.frame.size.width, notifList.sectionListView.frame.size.height);
              self.geminiScrollView.userInteractionEnabled = YES;
              [mainSwitcherVC.view addSubview:notifVC.view];
              notifVC.masterListView.clipsToBounds = YES;
              for(UIView *subview in notifVC.masterListView.subviews){
                if(![subview isKindOfClass:%c(NCNotificationListView)]) {
                  if([subview isKindOfClass:%c(CSAdjunctListView)]){
                    if(![adjunctListViews containsObject:subview]) [adjunctListViews addObject:subview];
                    [subview removeFromSuperview];
                  }
                  [subview removeFromSuperview];
                }
              }
              notifVC.view.translatesAutoresizingMaskIntoConstraints = NO;
              notifVC.view.transform = CGAffineTransformMakeScale(1.25, 1.25);
              [notifVC.view.widthAnchor constraintEqualToConstant:notifVC.view.frame.size.width].active = YES;
              [notifVC.view.heightAnchor constraintEqualToConstant:notifVC.view.frame.size.height].active = YES;
              [notifVC.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor/* constant:/*(notifVC.masterListView.frame.size.height - notifVC.masterListView.subviews[0].frame.size.height) / -2 -300*/].active = YES;

            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
              notifVC.view.alpha = 1;
            } completion:nil];

            /*for(SBFluidSwitcherItemContainerHeaderView *headerView in headerViews.reverseObjectEnumerator){
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
                    RLog(@"Removed %@ notification", notificationRequest.sectionIdentifier);
                  }
                }

                //inserts removed notifications back into the notification center
                NSMutableArray *notifsToAddBack = [NSMutableArray array];
                for(NCNotificationRequest *notificationRequest in removedRequests) {
                  if([notificationRequest.sectionIdentifier isEqualToString:identifier]){
                    [notifVC insertNotificationRequest:notificationRequest];
                    [notifsToAddBack addObject:notificationRequest];
                    RLog(@"Insert %@ notificatin", notificationRequest.sectionIdentifier);
                  }
                }
                for(NCNotificationRequest *notificationRequest in notifsToAddBack) {
                  [removedRequests removeObject:notificationRequest];
                }
                headerView.showingNotifs = YES;
                break;
              }
            }*/
          }
      return;
    } completion:nil];
    RLog(@"yeh we changing shit dawg");
    mainSwitcherVC.isSmall = YES;

    [combinedListVC _updateListViewContentInset];
  }
  else if(pinchGesture.scale >= 1.0 && mainSwitcherVC.isSmall && contentOrientation == 1) {
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
      RLog(@"hucking fore");
      self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 100, self.view.frame.size.width, self.view.frame.size.height);
      self.view.transform = CGAffineTransformMakeScale(1, 1);
      notifVC.view.alpha = 0;
      return;
    } completion:nil];
    mainSwitcherVC.isSmall = NO;
    topValue = 0;
    [combinedListVC _updateListViewContentInset];
  }
}

%new
-(void)GMNShowTestNotifications {
  //add notifications for currently opened apps
  NSArray *mainAppLayouts = [self valueForKey:@"_mainAppLayouts"];
  for(int i = 0; i < [mainAppLayouts count]; i++ ){
    SBAppLayout *appLayout = mainAppLayouts[i];
    SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
    NSString *identifier = displayItem.bundleIdentifier;
    int penis = i;
    for(int b = 0; b < [mainAppLayouts count] - 0; b++) {
      void *handle = dlopen("/usr/lib/libnotifications.dylib", RTLD_LAZY);
      if (handle != NULL) {

         NSString *uid = [[NSUUID UUID] UUIDString];
          [objc_getClass("CPNotification") showAlertWithTitle:@"Holy Smokes!"
                                                      message:[NSString stringWithFormat:@"Notification #%d", penis + 1]
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
      topValue = 0;
    }
    for(UIViewController *childVC in mainSwitcherVC.childViewControllers){
      if(![childVC isKindOfClass:%c(SBDeckSwitcherViewController)]){
        //[notifVC addChildViewController:childVC];
      }
    }
    for(NCNotificationStructuredSectionList *notifList in notifLists){
      for(NSLayoutConstraint *layoutConstraint in notifList.sectionListView.constraints) {
        layoutConstraint.active = NO;
      }
      NSMutableArray *notifsToAddBack = [NSMutableArray array];
      for(NCNotificationRequest *notificationRequest in removedRequests) {
        [notifVC insertNotificationRequest:notificationRequest];
        [notifsToAddBack addObject:notificationRequest];
      }
      for(NCNotificationRequest *notificationRequest in notifsToAddBack) {
        [removedRequests removeObject:notificationRequest];
      }
      notifVC.view.transform = CGAffineTransformMakeScale(1, 1);
      [notifParentVC addChildViewController:notifVC];
      notifVC.masterListView.clipsToBounds = NO;
      //RLog(@"number of things %d", [adjunctListViews count]);
      for(UIView *listView in adjunctListViews){
        //RLog(@"adding %@", listView);
        [notifVC.masterListView addSubview:listView];
      }
      [notifSuperview addSubview:notifVC.view];
      notifVC.view.hidden = NO;
    }
    notifVC.view.alpha = 1;

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
  UILabel *label = (UILabel *)[self valueForKey:@"_firstTitleLabel"];
  if(arg1 >= 0.9 && ![self showingNotifs] && mainSwitcherVC.isSmall && !isScrollingFast) {
      RLog(@"Add notifs for: %@", label.text);

      //Adds childVC's to mainSwitcherVC to avoid UIViewControlerHierarchyInconsistency error
      /*for(UIViewController *childVC in notifVC.childViewControllers){
        [mainSwitcherVC addChildViewController:childVC];
      }*/

      //for(NCNotificationStructuredSectionList *notifList in notifLists) {
        //[notifVC revealNotificationHistory:YES animated:NO];
        //[notifList.sectionListView setRevealed:YES];
        SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)self.superview;
        SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
        SBAppLayout *appLayout = snapshotView.appLayout;
        SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
        NSString *identifier = displayItem.bundleIdentifier;
        AXNManager *axonManager = [%c(AXNManager) sharedInstance];
        [axonManager showNotificationRequestsForBundleIdentifier:identifier];
        allNotificationRequests  = [NSMutableArray array];
        for(NCNotificationStructuredSectionList *notifList in notifLists){
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
            //RLog(@"Insert %@ notificatin", notificationRequest.sectionIdentifier);
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
            //RLog(@"Removed %@ notification", notificationRequest.sectionIdentifier);
          }
        }
        if([notifVC respondsToSelector:@selector(axnAllowChanges)]){
          notifVC.axnAllowChanges = axnAllowChangesOld;
        }
      //}
      self.showingNotifs = YES;
  }
  else if (arg1 < 0.9 && [self showingNotifs]){
    if(![notifVC respondsToSelector:@selector(axnAllowChanges)]) {
      allNotificationRequests  = [NSMutableArray array];
      for(NCNotificationStructuredSectionList *notifList in notifLists){
        for(id req in notifList.allNotificationRequests){
          [allNotificationRequests addObject:req];
        }
      }
      RLog(@"Remove notifs for: %@", label.text);
      SBAppSwitcherPageView *pageView = (SBAppSwitcherPageView *)self.superview;
      SBAppSwitcherReusableSnapshotView *snapshotView = pageView.view;
      SBAppLayout *appLayout = snapshotView.appLayout;
      SBDisplayItem *displayItem = [[appLayout valueForKey:@"_rolesToLayoutItemsMap"] objectForKey:@1];
      NSString *identifier = displayItem.bundleIdentifier;
      for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
        if([notificationRequest.sectionIdentifier isEqualToString:identifier]) {
          RLog(@"removed req: %@", notificationRequest.sectionIdentifier);
          [removedRequests addObject:notificationRequest];
          [notifVC removeNotificationRequest:notificationRequest];
          //RLog(@"Removed %@ notification", notificationRequest.sectionIdentifier);
        }
      }
    }

    self.showingNotifs = NO;
  }
}
%end

%hook NCNotificationStructuredSectionList
-(id)initWithTitle:(id)arg1 {
  [notifLists addObject:self];
  RLog(@"notifList: %@", self);
  return %orig;
}
%end

%hook NCNotificationStructuredListViewController
-(id)init {
  notifVC = self;
  return %orig;
}
-(void)viewWillLayoutSubviews {
  %orig;
  if(mainSwitcherVC.isSmall){
    notifVC.masterListView.frame = CGRectMake(notifVC.masterListView.frame.origin.x, notifVC.masterListView.frame.origin.y, notifVC.masterListView.frame.size.width,/* notifVC.view.frame.size.height - notifVC.view.frame.origin.y*/350);
  }
  if(!notifSuperview) notifSuperview = self.view.superview;
  if(!notifParentVC) notifParentVC = self.parentViewController;
}
%end

%hook GeminiSwitcherView
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  id orig = %orig;
  if(self == mainSwitcherVC.view) {
    if(self.clipsToBounds || self.hidden || self.alpha == 0){
      RLog(@"returning : %@", orig);
      return orig;
    }
    for(UIView *subview in self.subviews.reverseObjectEnumerator) {
      if(subview == notifVC.view){
        CGPoint subPoint = [subview convertPoint:point fromView:self];
        UIView *result = [subview hitTest:subPoint withEvent:event];
        if(result) {
          RLog(@"quack");
          return result;
        }
      }
    }
  }
  RLog(@"returning : %@", orig);
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
            //notifVC.view.hidden = YES;
            RLog(@"Fast");
        } else {
            isScrollingFast = NO;
            if(mainSwitcherVC.isSmall && notifVC.view.hidden){
              //notifVC.view.hidden = NO;
            }
            /*for(NCNotificationStructuredSectionList *notifList in notifLists){
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
                  RLog(@"identifier = %@", identifier);
                  //removes notifications that aren't a certain app
                  for(NCNotificationRequest *notificationRequest in allNotificationRequests) {
                    if(![notificationRequest.sectionIdentifier isEqualToString:identifier]) {
                      [removedRequests addObject:notificationRequest];
                      [notifVC removeNotificationRequest:notificationRequest];
                      RLog(@"Removed %@ notification", notificationRequest.sectionIdentifier);
                    }
                  }

                  //inserts removed notifications back into the notification center
                  NSMutableArray *notifsToAddBack = [NSMutableArray array];
                  for(NCNotificationRequest *notificationRequest in removedRequests) {
                    if([notificationRequest.sectionIdentifier isEqualToString:identifier]){
                      [notifVC insertNotificationRequest:notificationRequest];
                      [notifsToAddBack addObject:notificationRequest];
                      RLog(@"Insert %@ notificatin", notificationRequest.sectionIdentifier);
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
            RLog(@"Slow");
        }

        lastOffset = currentOffset;
        lastOffsetCapture = currentTime;
    }
}

-(void)_setScrolling:(BOOL)arg1 {
  %orig;
  if(isScrollingFast && mainSwitcherVC.isSmall && !arg1){
    notifVC.view.hidden = NO;
  }
  if(!arg1){

  }
}
%end

%hook CSCombinedListViewController
-(instancetype)initWithNibName:(id)arg1 bundle:(id)arg2 {
  combinedListVC = self;
  return %orig;
}
-(UIEdgeInsets)_listViewDefaultContentInsets {
  UIEdgeInsets insets = %orig;
  if(mainSwitcherVC.isSmall){
    for(UIView *listView in adjunctListViews){
      if(!topValue && listView.frame.size.height != 0){
        topValue = listView.frame.size.height;
      }
    }
    insets.top += (topValue + 200) * -1;
    return insets;
  }
  else {
    return insets;
  }
}
%end

%hook CSNotificationAdjunctListViewController
-(instancetype)init {
  adjunctListViewController = self;
  return %orig;
}
%end

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

%hook NCNotificationListView
-(void)setRevealed:(BOOL)arg1{
  %orig;
  RLog(@"setRevealed %d", arg1);
}
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

%hook NCNotificationStructuredSectionList
-(void)_removeNotificationGroupList:(id)arg1 {
  %orig;
  RLog(@"_removeNotificationGroupList %@", arg1);
}
%end

%hook AXNManager
-(void)showNotificationRequest:(id)arg1 {
  %orig;
  RLog(@"showNotificationRequest: %@", arg1);
}
%end

%hook SBFluidSwitcherAnimationSettings
-(void)setStackedSwitcherTrackingSettings:(id)arg1 {
  %orig(nil);
  RLog(@"ddueueu");
}
%end

static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.galacticdev.geminiprefs.plist"];

  isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
  reduceAnimations  = [prefs objectForKey:@"reduceAnimations"] ? [[prefs objectForKey:@"reduceAnimations"] boolValue] : NO;

}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	RLog(@"PREFERENCES CHANGED");
  loadPrefs();
}


%ctor {  loadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.galacticdev.geminiprefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	if(isEnabled) {
    %init;
    notifLists = [NSMutableArray array];
    headerViews = [NSMutableArray array];
    removedRequests = [NSMutableArray array];
    adjunctListViews = [NSMutableArray array];
  }


}
