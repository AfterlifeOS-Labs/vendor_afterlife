# Copyright (C) 2017 Unlegacy-Android
# Copyright (C) 2023 The AfterlifeOS Project
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

# -----------------------------------------------------------------
# Afterlife OTA update package

AFTERLIFE_ZIPNAME := afterlife_$(TARGET_DEVICE)-$(shell echo $(AFTERLIFE_VERSION) | tr '[:upper:]' '[:lower:]').zip
AFTERLIFE_TARGET_PACKAGE := $(PRODUCT_OUT)/$(AFTERLIFE_ZIPNAME)

SHA256 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/sha256sum

$(AFTERLIFE_TARGET_PACKAGE): $(INTERNAL_OTA_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_OTA_PACKAGE_TARGET) $(AFTERLIFE_TARGET_PACKAGE)
	$(hide) $(SHA256) $(AFTERLIFE_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(AFTERLIFE_TARGET_PACKAGE).sha256sum
	@echo "Done"
	@echo -e "\t ===============================-Package complete-========================================="
	@echo -e "\t Filename: $(AFTERLIFE_TARGET_PACKAGE)"
	@echo -e "\t Size: `du -sh $(AFTERLIFE_TARGET_PACKAGE) | awk '{print $$1}' `"
	@echo -e "\t AfterlifeOS | #NeverDie"
	@echo -e "\t =========================================================================================="

.PHONY: afterlife
afterlife: $(AFTERLIFE_TARGET_PACKAGE) $(DEFAULT_GOAL)
