include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GeminiPrefs

GeminiPrefs_FILES = $(wildcard *.m)
GeminiPrefs_INSTALL_PATH = /Library/PreferenceBundles
GeminiPrefs_FRAMEWORKS = UIKit
GeminiPrefs_PRIVATE_FRAMEWORKS = Preferences OnBoardingKit
GeminiPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GeminiPrefs.plist$(ECHO_END)
