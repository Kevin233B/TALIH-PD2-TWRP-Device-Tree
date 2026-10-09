# PBRP product for TALIH-PD2 (ls12_mt8797_wifi_64)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_keys.mk)

$(call inherit-product, device/alps/ls12_mt8797_wifi_64/device.mk)
$(call inherit-product, vendor/pb/config/common.mk)

PRODUCT_DEVICE := ls12_mt8797_wifi_64
PRODUCT_NAME := pb_ls12_mt8797_wifi_64
PRODUCT_BRAND := alps
PRODUCT_MODEL := TALIH-PD2
PRODUCT_MANUFACTURER := alps

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="vnd_ls12_mt8797_wifi_64-user 12 SP1A.210812.016 1723478295 release-keys"

BUILD_FINGERPRINT := alps/vnd_ls12_mt8797_wifi_64/ls12_mt8797_wifi_64:12/SP1A.210812.016/1723478295:user/release-keys

PB_CODE := ls12_mt8797_wifi_64
PB_MAINTAINER := Kevin233B
