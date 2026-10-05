# TALIH-PD2 (ls12_mt8797_wifi_64) TWRP（AOSP minimal manifest）

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
# WiFi-only 机型（无基带），不继承 full_base_telephony
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# Inherit some common Omni stuff.
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from ls12_mt8797_wifi_64 device
$(call inherit-product, device/alps/ls12_mt8797_wifi_64/device.mk)

PRODUCT_DEVICE := ls12_mt8797_wifi_64
PRODUCT_NAME := omni_ls12_mt8797_wifi_64
PRODUCT_BRAND := alps
PRODUCT_MODEL := TALIH-PD2
PRODUCT_MANUFACTURER := alps

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="vnd_ls12_mt8797_wifi_64-user 12 SP1A.210812.016 1723478295 release-keys"

BUILD_FINGERPRINT := alps/vnd_ls12_mt8797_wifi_64/ls12_mt8797_wifi_64:12/SP1A.210812.016/1723478295:user/release-keys
