LOCAL_PATH := device/alps/ls12_mt8797_wifi_64

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctl

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# A/B OTA
PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    update_engine_sideload

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6893.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6893.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt8797.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt8797.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/init/mtk-plpath-utils.rc:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init/mtk-plpath-utils.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/init/snapuserd.rc:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init/snapuserd.rc \
    $(LOCAL_PATH)/prebuilt/mtk_plpath_utils:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/mtk_plpath_utils
