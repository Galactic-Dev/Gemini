#include "GMNRootListController.h"

#import "NSTask.h"
#include <RemoteLog.h>
OBButtonTray *btnTray;
OBWelcomeController *welcomeController;
@implementation GMNRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];
	//[self setupWelcomeController];

	UISwitch *enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51, 31)];
	[enabledSwitch addTarget:self action:@selector(enabledSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	NSNumber *isEnabled = [settings valueForKey:@"isEnabled"] ?: @1;
	if([isEnabled isEqual:@1]){
		[enabledSwitch setOn:YES animated:NO];
	}
	else {
		[enabledSwitch setOn:NO animated:NO];
	}
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:enabledSwitch];

	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 100)];

	UIImage *backgroundImage = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/GeminiPrefs.bundle/background.jpg"];
	UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
	backgroundImageView.frame = self.headerView.bounds;
	backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
		// Set vertical effect
	UIInterpolatingMotionEffect *verticalMotionEffect =
	[[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	verticalMotionEffect.minimumRelativeValue = @(-10);
	verticalMotionEffect.maximumRelativeValue = @(10);

	// Set horizontal effect
	UIInterpolatingMotionEffect *horizontalMotionEffect =
	[[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
	horizontalMotionEffect.minimumRelativeValue = @(-10);
	horizontalMotionEffect.maximumRelativeValue = @(10);

	// Create group to combine both
	UIMotionEffectGroup *group = [UIMotionEffectGroup new];
	group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];

	// Add both effects to your view
	[backgroundImageView addMotionEffect:group];
	[self.headerView addSubview:backgroundImageView];

	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.headerView.frame.size.height / 4, [[UIScreen mainScreen] bounds].size.width, 50)];
	label.font = [UIFont boldSystemFontOfSize:40];
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.numberOfLines = 1;
	label.text = @"Gemini";
	self.headerView.clipsToBounds = YES;
	[self.headerView addSubview:label];
}

-(void)enabledSwitchChanged:(UISwitch *)enabledSwitch {
	if (enabledSwitch.on){
		RLog(@"SWITCH IS ON");
		//Sleeping to give time for UISwitch animating to complete. It just looks cleaner that way.
		NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
		NSMutableDictionary *settings = [NSMutableDictionary dictionary];
		[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
		[settings setObject:@1 forKey:@"isEnabled"];
		[settings writeToFile:path atomically:YES];
		[NSThread sleepForTimeInterval:0.3f];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring:)];
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
	}
	else {
		RLog(@"SWITCH IS OFF");
		NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
		NSMutableDictionary *settings = [NSMutableDictionary dictionary];
		[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
		[settings setObject:@0 forKey:@"isEnabled"];
		[settings writeToFile:path atomically:YES];
		[NSThread sleepForTimeInterval:0.3f];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring:)];
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
	}
}

-(void)setupWelcomeController {
	// Create the OBWelcomeView with a title, a desription text, and an icon if you wish. Any of this can be nil if it doesn't apply to your view.
	welcomeController = [[OBWelcomeController alloc] initWithTitle:@"OBWelcomeController Example" detailText:@"This is some text to welcome you. Please take off your shoes before entering." icon:[UIImage systemImageNamed:@"gear"]];

	// Create a bulleted item with a title, description, and icon. Any of the parameters can be set to nil if you wish. You can have as little or as many of these as you wish. The view automatically compensates for adjustments.
	[welcomeController addBulletedListItemWithTitle:@"Point One" description:@"Something important may go here, or it may not even be important. Who cares, amirite?" image:[UIImage systemImageNamed:@"1.circle.fill"]];
	[welcomeController addBulletedListItemWithTitle:@"Point Two" description:@"It's a bird! Wait, no! It's a plane! Haha, just kidding, it's an OBWelcomeController." image:[UIImage systemImageNamed:@"2.circle.fill"]];
	[welcomeController addBulletedListItemWithTitle:@"Point Three" description:@"Do people even read these? Like, people don't read the Terms & Conditions, so why would this be any different?" image:[UIImage systemImageNamed:@"3.circle.fill"]];

	// Create your button here, set some properties, and add it to the controller.
	OBBoldTrayButton* continueButton = [OBBoldTrayButton buttonWithType:1];
	[continueButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
	[continueButton setTitle:@"Continue" forState:UIControlStateNormal];
	[continueButton setClipsToBounds:YES]; // There seems to be an internal issue with the properties, so you may need to force this to YES like so.
	[continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // There seems to be an internal issue with the properties, so you may need to force this to be [UIColor whiteColor] like so.
	[continueButton.layer setCornerRadius:15]; // Set your button's corner radius. This can be whatever. If this doesn't work, make sure you make setClipsToBounds to YES.
	[welcomeController.buttonTray addButton:continueButton];

	//The caption text goes right above the buttons, sort of like as a thank you or disclaimer.
	[welcomeController.buttonTray addCaptionText:@"Thank you for using this tutorial on how to use an OBWelcomeView."];

	welcomeController.modalPresentationStyle = UIModalPresentationPageSheet; // The same style stock iOS uses.
	welcomeController.modalInPresentation = YES; //Set this to yes if you don't want the user to dismiss this on a down swipe.
	[self presentViewController:welcomeController animated:YES completion:nil]; // Don't forget to present it!
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(void)loadView {
			[super loadView];

}

-(id)readPreferenceValue:(PSSpecifier *)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];

	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
    
    if([[specifier.properties objectForKey:@"key"] isEqualToString:@"reduceAnimations"] && [value boolValue]) {
        RLog(@"we made it boys");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://google.com"] options:@{} completionHandler:nil];
    }
}

-(void)dismissVC {
	[welcomeController dismissViewControllerAnimated:YES completion:nil];
}

-(void)twitter:(PSSpecifier *)specifier {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=dev_galactic"] options:@{} completionHandler:nil];
}

-(void)showNotifs:(PSSpecifier *)specifier {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.galacticdev.gemini/showTestNotifications" object:nil];
}

-(void)respring:(PSSpecifier *)specifier {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/sbreload"];
	[task launch];
}
@end
