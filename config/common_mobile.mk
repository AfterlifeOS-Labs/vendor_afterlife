# Inherit common mobile Afterlife stuff
$(call inherit-product, vendor/afterlife/config/common.mk)

# Charger
PRODUCT_PACKAGES += \
    charger_res_images

ifneq ($(WITH_LINEAGE_CHARGER),false)
PRODUCT_PACKAGES += \
    lineage_charger_animation \
    lineage_charger_animation_vendor
endif

# Customizations
PRODUCT_PACKAGES += \
    NavigationBarNoHint \
    NavigationBarMode2ButtonOverlay

# Website
PRODUCT_SYSTEM_PROPERTIES += \
    ro.afterlife.url=https://afterlifeos.com

# Media
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    media.recorder.show_manufacturer_and_model=true

# SystemUI plugins
PRODUCT_PACKAGES += \
    QuickAccessWallet

# Themes
PRODUCT_PACKAGES += \
    ThemePicker \
    ThemesStub
