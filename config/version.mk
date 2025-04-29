# Copyright (C) 2024 Project AFTERLIFE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ANDROID_VERSION := 15
AFTERLIFEVERSION := 8.0

AFTERLIFE_BUILD_TYPE ?= COMMUNITY
AFTERLIFE_MAINTAINER ?= UNKNOWN
AFTERLIFE_DATE_YEAR := $(shell date -u +%Y)
AFTERLIFE_DATE_MONTH := $(shell date -u +%m)
AFTERLIFE_DATE_DAY := $(shell date -u +%d)
AFTERLIFE_DATE_HOUR := $(shell date -u +%H)
AFTERLIFE_DATE_MINUTE := $(shell date -u +%M)
AFTERLIFE_BUILD_DATE := $(AFTERLIFE_DATE_YEAR)$(AFTERLIFE_DATE_MONTH)$(AFTERLIFE_DATE_DAY)-$(AFTERLIFE_DATE_HOUR)$(AFTERLIFE_DATE_MINUTE)
TARGET_PRODUCT_SHORT := $(subst afterlife_,,$(AFTERLIFE_BUILD))

# OFFICIAL_DEVICES
ifeq ($(AFTERLIFE_BUILD_TYPE), OFFICIAL)
  LIST = $(shell cat vendor/afterlife/config/afterlife.devices)
    ifeq ($(filter $(AFTERLIFE_BUILD), $(LIST)), $(AFTERLIFE_BUILD))
      IS_OFFICIAL=true
      AFTERLIFE_BUILD_TYPE := OFFICIAL
    endif
    ifneq ($(IS_OFFICIAL), true)
      AFTERLIFE_BUILD_TYPE := COMMUNITY
      $(error Device is not official "$(AFTERLIFE_BUILD)")
    endif
endif

AFTERLIFE_VERSION := $(AFTERLIFEVERSION)-$(AFTERLIFE_BUILD)-$(AFTERLIFE_BUILD_DATE)-VANILLA-$(AFTERLIFE_BUILD_TYPE)
ifeq ($(WITH_GAPPS), true)
AFTERLIFE_VERSION := $(AFTERLIFEVERSION)-$(AFTERLIFE_BUILD)-$(AFTERLIFE_BUILD_DATE)-GAPPS-$(AFTERLIFE_BUILD_TYPE)
endif
AFTERLIFE_MOD_VERSION :=$(ANDROID_VERSION)-$(AFTERLIFEVERSION)
AFTERLIFE_DISPLAY_VERSION := AfterlifeOS-$(AFTERLIFEVERSION)-$(AFTERLIFE_BUILD_TYPE)
AFTERLIFE_DISPLAY_BUILDTYPE := $(AFTERLIFE_BUILD_TYPE)
AFTERLIFE_FINGERPRINT := AfterlifeOS/$(AFTERLIFE_MOD_VERSION)/$(TARGET_PRODUCT_SHORT)/$(AFTERLIFE_BUILD_DATE)

# Afterlife System Version
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
  ro.afterlife.version=$(AFTERLIFE_DISPLAY_VERSION) \
  ro.afterlife.build.status=$(AFTERLIFE_BUILD_TYPE) \
  ro.modversion=$(AFTERLIFE_MOD_VERSION) \
  ro.afterlife.build.date=$(AFTERLIFE_BUILD_DATE) \
  ro.afterlife.buildtype=$(AFTERLIFE_BUILD_TYPE) \
  ro.afterlife.fingerprint=$(AFTERLIFE_FINGERPRINT) \
  ro.afterlife.device=$(AFTERLIFE_BUILD) \
  org.afterlife.version=$(AFTERLIFEVERSION) \
  ro.afterlife.maintainer=$(AFTERLIFE_MAINTAINER)
