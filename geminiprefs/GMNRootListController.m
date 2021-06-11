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

	UISwitch *enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	[enabledSwitch addTarget:self action:@selector(enabledSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    BOOL shownWelcomeController = [settings[@"shownWelcomeController"] boolValue];
    if(!shownWelcomeController) {
        [self setupWelcomeController];
    }
    
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
		//Sleeping to give time for UISwitch animating to complete. It just looks cleaner that way.
		NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		[settings setObject:@1 forKey:@"isEnabled"];
		[settings writeToFile:path atomically:YES];
		[NSThread sleepForTimeInterval:0.3f];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring:)];
		self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
	}
	else {
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
	welcomeController = [[OBWelcomeController alloc] initWithTitle:@"Gemini" detailText:@"Utilize your App Switcher like never before!" icon:[UIImage systemImageNamed:@"sparkles"]];

	[welcomeController addBulletedListItemWithTitle:@"Control Center" description:@"Bring the Control Center into you App Switcher in a premium fashion, and the option to choose whatever modules you want." image:[UIImage systemImageNamed:@"rectangle.3.offgrid.fill"]];
	[welcomeController addBulletedListItemWithTitle:@"Notification Center" description:@"Show your app's notifications right in the App Switcher, with sorting so you only see notifications for the app you're hovering over in the switcher." image:[UIImage systemImageNamed:@"app.badge"]];
	[welcomeController addBulletedListItemWithTitle:@"Dynamic" description:@"Combine both Control and Notification Centers in one dynamic view with the option to intelligently switch between views." image:[UIImage systemImageNamed:@"square.stack.3d.down.right.fill"]];

	OBBoldTrayButton* continueButton = [OBBoldTrayButton buttonWithType:1];
	[continueButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
	[continueButton setTitle:@"Continue" forState:UIControlStateNormal];
	[continueButton setClipsToBounds:YES];
	[continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[continueButton.layer setCornerRadius:15];
	[welcomeController.buttonTray addButton:continueButton];

	[welcomeController.buttonTray addCaptionText:@"Thank you for purchasing Gemini"];

	welcomeController.modalPresentationStyle = UIModalPresentationPageSheet;
	welcomeController.modalInPresentation = YES;
	[self presentViewController:welcomeController animated:YES completion:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
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
}

-(void)dismissVC {
    NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
    NSMutableDictionary *settings;
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    else {
        settings = [NSMutableDictionary dictionary];
    }
    [settings setObject:@1 forKey:@"shownWelcomeController"];
    [settings writeToFile:path atomically:YES];
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
-(void)resetSettings {
    NSString *path = @"/User/Library/Preferences/com.galacticdev.geminiprefs.plist";
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/sbreload"];
    [task launch];
}
@end
