include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GeminiPrefs

GeminiPrefs_FILES = $(wildcard *.m) $(wildcard *.x)
GeminiPrefs_INSTALL_PATH = /Library/PreferenceBundles
GeminiPrefs_FRAMEWORKS = UIKit
GeminiPrefs_PRIVATE_FRAMEWORKS = Preferences OnBoardingKit
GeminiPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk
