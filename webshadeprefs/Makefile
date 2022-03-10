TARGET := iphone:clang:latest:11.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WebShadePrefs

WebShadePrefs_FILES = WSPRootListController.m WSPSiteListController.m WSPCustomSiteListController.m 
WebShadePrefs_FRAMEWORKS = UIKit
WebShadePrefs_PRIVATE_FRAMEWORKS = Preferences
WebShadePrefs_INSTALL_PATH = /Library/PreferenceBundles
WebShadePrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
