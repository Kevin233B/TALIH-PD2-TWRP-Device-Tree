# TALIH-PD2 (ls12_mt8797_wifi_64) — MT8797/MT6893

DEVICE_PATH := device/alps/ls12_mt8797_wifi_64

ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# Platform
TARGET_BOARD_PLATFORM := mt6893
TARGET_BOOTLOADER_BOARD_NAME := ls12_mt8797_wifi_64
TARGET_NO_BOOTLOADER := true

# A/B (recovery-as-boot)
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    system \
    vendor \
    product \
    boot \
    dtbo \
    init_boot \
    vendor_boot \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor
BOARD_USES_RECOVERY_AS_BOOT := true
# TW_HAS_NO_RECOVERY_PARTITION (a TWRP 3.x recoveryimage flag) has no consumer
# anywhere in the twrp-12.1 build: zero references in
# TeamWin/android_bootable_recovery, TeamWin/android_vendor_twrp and
# TeamWin/android_build (core/Makefile + core/config.mk). Removed after the
# Round B flag-wiring audit.

# Kernel
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz
BOARD_KERNEL_IMAGE_NAME := Image.gz

# Boot image
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_OFFSET := 0x00080000
BOARD_RAMDISK_OFFSET := 0x11100000
BOARD_KERNEL_TAGS_OFFSET := 0x07c80000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 buildvariant=user
BOARD_BOOT_HEADER_VERSION := 2
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_PAGESIZE := 2048
BOARD_FLASH_BLOCK_SIZE := 131072
# AOSP 12.1 mkbootimg rejects header v2 images without a non-empty DTB, so
# the DTB is passed explicitly here (flows into the internal packaging rule).
# The MTK DTB container (prebuilt/dtb.img, 206433 bytes) is byte-identical to
# the one embedded in the running stock image; it sits at the standard v2
# offset and dtb_addr = base + 0x07c80000 = 0x47c80000, matching stock.
BOARD_MKBOOTIMG_ARGS += \
    --header_version 2 \
    --base $(BOARD_KERNEL_BASE) \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET) \
    --dtb $(DEVICE_PATH)/prebuilt/dtb.img \
    --dtb_offset 0x07c80000

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 32212254720
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_PARTITION_LIST := system vendor product
BOARD_MAIN_SIZE := 32210157568

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
# TARGET_USES_MKE2FS was an android-8/9 transition flag (make_ext4fs -> mke2fs).
# android-12 has no make_ext4fs at all: core/config.mk sets MKE2FS_CONF
# unconditionally and every ext4 image goes through mke2fs, so the flag is
# inert here. Removed after the Round B flag-wiring audit.
BOARD_SUPPRESS_SECURE_ERASE := true

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
BOARD_HAS_NO_SELECT_BUTTON := true

# Display
# Native panel is a WQXGA Himax in-cell (hx83121a_cdot_csot_wqxga) that comes
# up as a portrait framebuffer: 1600x2560, rotate=0. Touch panel-coords are
# identical to display-coords (1600x2560), so recovery touch aligns natively
# and no axis swap or offset is needed.
#
# Touch release: the himax driver ends every finger-up frame with
# ABS_MT_TRACKING_ID -1 FIRST, then ABS_MT_TOUCH_MAJOR 0 and ABS_MT_PRESSURE 0
# (captured on-device with getevent; 222/222 lifts carry this exact shape).
# In minuitwrp/events.cpp the tracking-id case sets
# touchReleaseOnNextSynReport=2 and use_tracking_id_negative_as_touch_release,
# but the later zero TOUCH_MAJOR/PRESSURE events overwrite the marker back to
# 1, so at SYN_REPORT BOTH release conditions are false: the GUI gets
# touch-down and drag updates but never a finger-up (buttons highlight but
# never activate, sliders never commit).
#
# TW_IGNORE_ABS_MT_TRACKING_ID would mask this by ignoring the tracking-id
# events, but the flag has no wiring in the twrp-12.1 build: neither
# TeamWin/android_bootable_recovery nor TeamWin/android_vendor_twrp turns the
# BoardConfig variable into -DTW_IGNORE_ABS_MT_TRACKING_ID (verified against
# both trees; the soong_config list in vendor/twrp/build/soong/Android.bp
# covers TW_IGNORE_MAJOR_AXIS_0 and TW_INPUT_BLACKLIST but not this flag), so
# setting it here is a no-op. The real fix is the source patch applied by CI:
# patches/0001-minuitwrp-keep-tracking-id-release-marker.patch keeps a
# tracking-id release marker (2) from being downgraded back to 1.
TW_THEME := portrait_hdpi
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 160

# /sdcard lives on /data (FBE), so TWRP must treat it as data media.
# /data is metadata-encrypted (dm-default-key, keydirectory=
# /metadata/vold/metadata_encryption) with FBE v2 on top. Decryption is
# enabled (v6): the fstab /data entry carries the stock crypto keywords
# again, the real vendor keymaster@4.1 service + its full readelf-verified
# library closure live in the ramdisk (recovery/root/system), and the
# VINTF fragment at recovery/root/vendor/etc/vintf/manifest declares the
# HAL so vold's libhidl client resolves transport=hwbinder via
# hwservicemanager's getTransport (the v5 session logged a getTransport
# miss for every unmanifested HAL). Round A's logo hang was exactly the
# missing service leg of this chain; with the service up before
# Decrypt_Data() runs, vold's keymaster wait resolves.
RECOVERY_SDCARD_ON_DATA := true
BOARD_USES_METADATA_PARTITION := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true

# TWRP
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_PYTHON := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_RESETPROP := true
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
# TW_DEFAULT_DEVICE_NAME has no consumer in the twrp-12.1 build (zero
# references in TeamWin/android_bootable_recovery and android_vendor_twrp);
# the displayed device name comes from ro.product.device. Removed after the
# Round B flag-wiring audit.
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true
TW_DEVICE_VERSION := Kevin233B
TW_NO_LEGACY_PROPS := true
TW_NO_REBOOT_BOOTLOADER := true
# Screen-blank on boot removed (v6): gui_init()'s TW_SCREEN_BLANK_ON_BOOT
# path blanks (brightness 000 + FBIOBLANK POWERDOWN) and immediately
# unblanks around the first splash render; on this MTK panel that dance
# left a white screen until the first input event redrew a frame (v5
# field report: touch once and it recovers). Without the flag the first
# frame renders directly.
# TW_EXCLUDE_SUPERSU has no consumer: SuperSU installation is deprecated and
# removed in twrp-12.1 (gui/action.cpp logs "Installing SuperSU was
# deprecated from TWRP"). Removed after the Round B flag-wiring audit.
# 温区实测: thermal_zone3 = mtktscpu (zone0 是电池 mtktsbattery)
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone3/temp"
# Battery: TWRP 12.1's default monitor uses GetBatteryInfo() (health@2.0
# HAL over hwbinder). No health service runs in this recovery, so it hits
# the "no health implementation, assuming defaults" fallback in
# recovery_utils/battery_utils.cpp: charging=true, capacity=100 — the
# observed "100%+" on a ~46% battery (v4 session; live sysfs read 46 /
# Charging). The legacy path reads
# /sys/class/power_supply/battery/{capacity,status} directly, exactly what
# the running system exposes. Wired in the recovery root Android.mk
# (ifeq -> -DTW_USE_LEGACY_BATTERY_SERVICES in twrp.cpp
# monitorBatteryInBackground).
TW_USE_LEGACY_BATTERY_SERVICES := true
TARGET_OTA_ASSERT_DEVICE := ls12_mt8797_wifi_64
# USB: adb 由 init 侧保证(见 init.recovery.mt6893/8797.rc 的 on init):
# configfs=0 + persist.sys.usb.config=adb → boot 时 init.usb.rc 老式
# android0 链自动配 gadget 并 start adbd, 与 GUI 死活无关(本机内核
# /sys/class/android_usb/android0 实测存在)。老式链无 mtp,adb handler,
# 本轮 MTP 不可用。不设 TW_EXCLUDE_DEFAULT_USB_INIT, 保留 AOSP usb rc。

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0
