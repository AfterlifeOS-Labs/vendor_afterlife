# Inherit mobile full common Afterlife stuff
$(call inherit-product, vendor/afterlife/config/common_mobile.mk)

# Inherit tablet common Afterlife stuff
$(call inherit-product, vendor/afterlife/config/tablet.mk)

$(call inherit-product, vendor/afterlife/config/telephony.mk)
