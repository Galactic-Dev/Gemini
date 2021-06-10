export PREFIX=$(THEOS)/toolchain/Xcode.xctoolchain/usr/bin/

export TARGET = iphone:clang:13.4
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Gemini

Gemini_FILES = Gemini.x GeminiSwitcherView.m UIDevice+notchedDevice.m
Gemini_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += geminiprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
