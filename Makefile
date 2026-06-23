ARCHS := arm64
TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES := GeometryDashLite
THEOS_PACKAGE_SCHEME ?= rootless
STRIP = 1
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := imgui

imgui_USE_MODULES := 0
imgui_FILES := $(shell find . -type f \( -iname "*.cpp" -o -iname "*.m" -o -iname "*.c" -o -iname "*.mm" \) -not -path "./.theos/*" -not -path "./packages/*" -not -path "./obj/*")
imgui_CCFLAGS += -I./imgui -I./imgui/backends -O3 -s -std=c++23 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -Wc++11-narrowing -Wno-narrowing -Wundefined-bool-conversion -Wreturn-stack-address -Wno-error=format-security -fvisibility=hidden -fpermissive -fexceptions -w -Wno-error=format-security -fvisibility=hidden -Werror -fpermissive -Wall -fexceptions -Wno-module-import-in-extern-c
imgui_CFLAGS  += -I./imgui -I./imgui/backends -O3 -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -fvisibility=hidden -Wc++11-narrowing -Wno-narrowing -Wundefined-bool-conversion -Wreturn-stack-address -Wno-error=format-security -fvisibility=hidden -fpermissive -fexceptions -w -Wno-error=format-security -fvisibility=hidden -Werror -fpermissive -Wall -fexceptions -Wno-module-import-in-extern-c
imgui_LDFLAGS += -stdlib=libc++ -lz
imgui_FRAMEWORKS += UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController MetalKit Metal
imgui_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk
