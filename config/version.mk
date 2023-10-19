PRODUCT_VERSION_MAJOR = 8
PRODUCT_VERSION_MINOR = 0
AFTERLIFE_VERSION_CODENAME := BrotherHood

CURRENT_DEVICE=$(shell echo "$(TARGET_PRODUCT)" | cut -d'_' -f 2,3)

AFTERLIFE_BUILDTYPE := UNOFFICIAL

ifeq ($(AFTERLIFE_OFFICIAL), true)
     AFTERLIFE_BUILDTYPE := OFFICIAL
endif

AFTERLIFE_MAINTAINER ?= UNKNOWN

AFTERLIFE_VERSION := AfterlifeOS-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(AFTERLIFE_VERSION_CODENAME)-$(CURRENT_DEVICE)-$(AFTERLIFE_BUILDTYPE)-$(shell date -u +%Y%m%d-%H%M)

AFTERLIFE_DISPLAY_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(AFTERLIFE_VERSION_CODENAME)

# AfterlifeOS version properties
PRODUCT_PRODUCT_PROPERTIES += \
    ro.afterlife.version=$(AFTERLIFE_VERSION) \
    ro.afterlife.display.version=$(AFTERLIFE_DISPLAY_VERSION) \
    ro.afterlife.build.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.afterlife.maintainer=$(AFTERLIFE_MAINTAINER) \
    ro.afterlife.releasetype=$(AFTERLIFE_BUILDTYPE) \
    ro.modversion=$(AFTERLIFE_VERSION)

# Signing
ifeq (user,$(TARGET_BUILD_VARIANT))
ifneq (,$(wildcard .android-certs/releasekey.pk8))
PRODUCT_DEFAULT_DEV_CERTIFICATE := .android-certs/releasekey
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += ro.oem_unlock_supported=1
endif
ifneq (,$(wildcard .android-certs/otakey.x509.pem))
PRODUCT_OTA_PUBLIC_KEYS := .android-certs/otakey.x509.pem
endif
endif
