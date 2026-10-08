LOCAL_PATH := device/alps/ls12_mt8797_wifi_64

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Virtual A/B
ENABLE_VIRTUAL_AB := true
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# Device ships Android 12 (MSSI: system upgraded to 13, vendor stays 12)
PRODUCT_TARGET_VNDK_VERSION := 31
PRODUCT_SHIPPING_API_LEVEL := 31

# Keymaster /data-decryption version pin (v10.10)
#
# The vendor keymaster@4.1 soft device (libpuresoftkeymasterdevice) stamps
# the OS version / patch-level of newly created key blobs from these three
# properties and validates existing blobs against them at begin()
# (system/keymaster android_keymaster.cpp CheckPatchLevel):
#   blob_patch < current_patch -> KM_ERROR_KEY_REQUIRES_UPGRADE
#   blob_patch > current_patch -> KM_ERROR_INVALID_KEY_BLOB
# The metadata-encryption key was created by the live system:
#   ro.build.version.release           = 13
#   ro.build.version.security_patch    = 2023-06-01
#   ro.vendor.build.security_patch     = 2023-06-05
# A recovery that reports different values (previous build: 12 /
# 2099-12-31 / 2099-12-31) makes begin() demand an upgrade; the upgrade
# then tries to lower the blob's OS version from 13 to 12 and is refused
# as a downgrade (KM_ERROR_INVALID_ARGUMENT / -38), blocking /data
# decryption.  With all three pinned to the live values the check passes
# directly: no upgrade path is entered and no writes to the user's key
# material happen (verified via the /metadata key files' mtimes).
#
# Note: this replaces the previous 2099-12-31 vendor-patch override.
# Zip side-load asserts that require a newer security patch than the real
# device will now behave as they would on the live system; /data
# decryption correctness takes precedence.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.version.release=13 \
    ro.build.version.security_patch=2023-06-01 \
    ro.vendor.build.security_patch=2023-06-05

# Health HAL
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctl \
    update_engine_client

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

# Recovery ramdisk files (recovery/root/ is copied into the ramdisk
# automatically by the build system, no PRODUCT_COPY_FILES needed here)
#
# Keymaster for /data decryption (Round C) is shipped the same way as
# static ramdisk files: byte-identical copies of the running system's
# vendor keymaster@4.1 service (recovery/root/system/bin) plus its full
# readelf-verified DT_NEEDED closure (13 vendor libs under
# recovery/root/system/lib64; every other dependency already ships in the
# recovery ramdisk), and a VINTF fragment at
# recovery/root/vendor/etc/vintf/manifest so vold's libhidl client can
# resolve the HAL transport. Started explicitly at on boot by
# init.recovery.mt8797.rc, before the recovery binary runs Decrypt_Data().
