# Inherit mobile full common Afterlife stuff
$(call inherit-product, vendor/afterlife/config/common_mobile.mk)

# Enable support of one-handed mode
PRODUCT_PRODUCT_PROPERTIES += \
    ro.support_one_handed_mode?=true

# Inherit tablet common Afterlife stuff
$(call inherit-product, vendor/afterlife/config/tablet.mk)

$(call inherit-product, vendor/afterlife/config/telephony.mk)

PRODUCT_PACKAGE_OVERLAYS += vendor/afterlife/overlay/foldable_book
