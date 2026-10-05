# device.mk — TALIH-PD2 (ls12_mt8797_wifi_64)

LOCAL_PATH := device/alps/ls12_mt8797_wifi_64

# A/B OTA
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL（mt6893 = mt8797，同一颗 SoC）
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-service

PRODUCT_PACKAGES += \
    bootctrl.mt6893

PRODUCT_STATIC_BOOT_CONTROL_HAL := \
    bootctrl.mt6893 \
    libgptutils \
    libz \
    libcutils

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    update_engine_sideload

# 带 health 的模块（HAL/service/vintf manifest）会安装到 /vendor 路径，
# 与 recovery root 的 vendor 符号链接冲突导致 ramdisk 打包失败；
# TWRP 直接读 sysfs 电量，不需要 health HAL，全部剔除
PRODUCT_PACKAGES := $(filter-out %health%,$(PRODUCT_PACKAGES))

# Recovery ramdisk 附加内容（取自原厂 boot 镜像 ramdisk，实测可用）
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6893.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6893.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt8797.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt8797.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/init/mtk-plpath-utils.rc:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init/mtk-plpath-utils.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/init/snapuserd.rc:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init/snapuserd.rc \
    $(LOCAL_PATH)/prebuilt/mtk_plpath_utils:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/mtk_plpath_utils
