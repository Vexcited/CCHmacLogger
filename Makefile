TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCHmacLogger

CCHmacLogger_FILES = Tweak.xm
CCHmacLogger_CFLAGS = -fobjc-arc
CCHmacLogger_LDFLAGS += -lSystem

include $(THEOS_MAKE_PATH)/tweak.mk
