# BoardConfig.mk — TALIH-PD2 (ls12_mt8797_wifi_64)
#
# SoC: MT8797 = MT6893（同一颗 SoC 的两个名字，原厂镜像内两种命名并存：
#      fstab.mt6893 / fstab.mt8797 / init.recovery.mt6893.rc / init.recovery.mt8797.rc）
#
# 预编译内核与 dtb 均取自实测可启动的原厂 boot 镜像（boot_a/boot_b 逐字节一致），
# 触摸（Himax HX83121A SPI）依赖内核内置驱动 + 设备 dtbo 分区 overlay，
# 详见 README.md「触摸」一节。

DEVICE_PATH := device/alps/ls12_mt8797_wifi_64

# For building with minimal manifest
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

# A/B（无独立 recovery 分区，recovery-as-boot：TWRP 装进 boot_a/boot_b）
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
TW_HAS_NO_RECOVERY_PARTITION := true

# Kernel — 预编译（TALIH-PD2-Kernel susfs+resukisu 分支产物，已实测双槽可启动）
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz
BOARD_KERNEL_IMAGE_NAME := Image.gz

# MTK boot image 参数（与原厂 boot header 实测值一致）
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_OFFSET := 0x00080000
BOARD_RAMDISK_OFFSET := 0x11100000
BOARD_KERNEL_TAGS_OFFSET := 0x07c80000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 buildvariant=user
BOARD_BOOT_HEADER_VERSION := 2
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_PAGESIZE := 2048
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_MKBOOTIMG_ARGS += \
    --header_version 2 \
    --base $(BOARD_KERNEL_BASE) \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

# DTB（重要，勿改）:
#   原厂布局为 MTK LK 私有加载方式 —— boot header 中 dtb_size=0，
#   DTBO 容器格式（magic 0xd7b7ab1e）的 dtb.img 物理追加在 ramdisk
#   页对齐偏移之后。因此这里不设 BOARD_INCLUDE_DTB_IN_BOOTIMG、不传 --dtb，
#   由 .github/workflows/build.yml 在 mkbootimg 之后完成追加（见 README.md）。
#   dtbo overlay（fragment@50 -> &spi1 himax_ts@0 触摸节点）在 LK 引导时
#   由设备 dtbo_a/dtbo 分区合并进该基础 dtb，不能替换为自编译 dtb，
#   否则 overlay 符号/phandle 匹配会失败、触摸失效。

# Partitions（实测 /dev/block/by-name + sysfs 大小）
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864          # boot_a/boot_b 各 64 MiB
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 32212254720          # super 实测 30 GiB
BOARD_SUPER_PARTITION_GROUPS := alps_dynamic_partitions
BOARD_ALPS_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor product
BOARD_ALPS_DYNAMIC_PARTITIONS_SIZE := 32128368128   # 30 GiB - 32 MiB 元数据余量

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
BOARD_SUPPRESS_SECURE_ERASE := true

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
BOARD_HAS_NO_SELECT_BUTTON := true

# Display（2560x1600 横屏平板）
TW_THEME := landscape_hdpi
TW_SCREEN_WIDTH := 2560
TW_SCREEN_HEIGHT := 1600
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 160

# 触摸（Himax HX83121A SPI, tct,lushan12_hx83121a_spi）:
#   驱动 CONFIG_TOUCHSCREEN_LUSHAN12_HX83121A_SPI=y 已内置预编译内核，
#   触摸节点由设备 dtbo 分区 overlay 提供 —— 无需额外配置即可工作。
#   hbtp_vm 为虚拟触控黑名单，与触摸无关，保留通用默认。
TW_INPUT_BLACKLIST := "hbtp_vm"

# Encryption（FBE v2 f2fs + MTK inline crypto；TEE 换钥大概率无法解密，保留尝试能力）
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_USE_FSCRYPT_POLICY := 2
TW_INCLUDE_FBE_METADATA_DECRYPT := false

# TWRP
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_RESETPROP := true
TW_DEFAULT_DEVICE_NAME := TALIH-PD2
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true
TW_NO_LEGACY_PROPS := true
TW_NO_REBOOT_BOOTLOADER := true
TW_NO_SCREEN_BLANK := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_EXCLUDE_SUPERSU := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone0/temp"

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0
