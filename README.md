# TALIH-PD2 TWRP Device Tree

学而思学习机 TALIH-PD2（平台代号 `ls12_mt8797_wifi_64`）的 TWRP 设备树，适用于 [minimal-manifest-twrp](https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp) `twrp-12.1`。

| 项目 | 值 |
|---|---|
| 产品 | TALIH-PD2（TAL 学习平板，WiFi-only，无基带） |
| SoC | MT8797 = **MT6893**（同一颗 SoC 的两个名字，原厂镜像内两种命名并存） |
| 屏幕 | 2560×1600 (WQXGA) 横屏，HX83121A（Himax）面板 |
| 触摸 | Himax HX83121A，SPI 总线，`tct,lushan12_hx83121a_spi` |
| Android | 12（SP1A.210812.016），FBE v2 文件级加密 |
| 引导方式 | A/B 双槽，**无独立 recovery 分区**（recovery-as-boot） |
| boot 分区 | 64 MiB（boot_a / boot_b） |
| super | 30 GiB（system / vendor / product 逻辑分区） |
| /data | f2fs + FBE v2（aes-256-xts/aes-256-cts，keydirectory 在 /metadata） |

## 触摸

触摸**不需要任何额外配置**即可在 TWRP 中工作：

1. 触摸驱动 `CONFIG_TOUCHSCREEN_LUSHAN12_HX83121A_SPI=y` **内置**于预编译内核（`prebuilt/Image.gz`，与当前 boot_a/boot_b 逐字节一致）；
2. 触摸节点不在基础 dtb 里，而在**设备 dtbo 分区**的 overlay 中（`fragment@50` → `&spi1` → `himax_ts@0`），LK 引导时把它合并进 boot 镜像中的基础 dtb；
3. 因此 `prebuilt/dtb.img`（原厂 DTBO 容器格式，单条目）**必须保持原样**，不能替换为自编译 dtb —— 否则 dtbo overlay 的符号/phandle 匹配会失败，触摸会失效。

## Data 解密（FBE v2）

按 rosemary（MT6785，同为 FBE v2 + metadata keydirectory）等成熟设备树的方式配置：

- BoardConfig：`TW_INCLUDE_CRYPTO` + `TW_INCLUDE_CRYPTO_FBE` + `TW_INCLUDE_FBE_METADATA_DECRYPT` + `TW_USE_FSCRYPT_POLICY := 2`，并 relink 软件 keymaster 库（`libkeymaster4` / `libkeymaster41` / `libpuresoftkeymasterdevice`）；
- fstab 的 `/data` 行带完整 `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,keydirectory=/metadata/vold/metadata_encryption`（与本机原厂 first-stage fstab 一致），`/metadata` 挂载后 TWRP 即可读取密钥目录尝试解密；
- 密钥由 TEE 硬件绑定，recovery 内只能用软件 keymaster 尝试；能否成功取决于设备的密钥策略，无法保证。

## 只读保护（禁止写入 / 允许读取）

fstab 全表**只读**：

- 所有可挂载分区（system / vendor / product / metadata / persist / nvdata / nvcfg / protect / oempersist / data）一律 `ro` 挂载；
- 无 `formattable`（不能格式化）、无 `check`（不跑 fsck 修复，避免修复性写入）；
- 无 `wipeingui`、无 `flashimg`（GUI 无任何写入/刷写入口）；
- 裸分区（boot / dtbo / tee / lk 等）仅保留 Backup（读取）能力。

## Boot 镜像布局（MTK LK 私有加载方式）

原厂 boot 镜像（本仓库的基准，boot_a/boot_b 实测逐字节一致）：

```
[header v2 (2048B, dtb_size=0)] [kernel: Image.gz] [ramdisk: gzip cpio] [dtb.img]
                                                                    ^^^^^^
                                        追加在 ramdisk 页对齐偏移之后，header 不声明
```

- `mkbootimg` **不带** `--dtb`（header 中 `dtb_size=0`）；
- `prebuilt/dtb.img` 由 CI 在 mkbootimg 之后**手动追加**到页对齐偏移处，再填充到 64 MiB；
- 参数：`--base 0x40000000 --kernel_offset 0x00080000 --ramdisk_offset 0x11100000 --tags_offset 0x07c80000 --header_version 2 --pagesize 2048 --os_version 12.0.0 --os_patch_level 2023-06`，cmdline `bootopt=64S3,32N2,64N2 buildvariant=user`。

组装逻辑见 [`.github/workflows/build.yml`](.github/workflows/build.yml) 的 "Assemble boot image" 步骤。原厂镜像末尾的 AVB footer 经验证为陈旧残留数据（hash 与内容不匹配仍可正常启动，LK 不校验），CI 不做 AVB 签名。

## 构建

推送到 `main` 分支或手动触发 GitHub Actions 即可（约 1–2 小时）：

```bash
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
# 本设备树放到 device/alps/ls12_mt8797_wifi_64
. build/envsetup.sh
lunch omni_ls12_mt8797_wifi_64-eng
mka bootimage recoveryimage -j$(nproc)
# 之后按 build.yml 的 "Assemble boot image" 步骤组装出可刷写的 boot-twrp.img
```

产物：`boot-twrp.img`（recovery-as-boot，fastboot flash boot 或 dd 到 boot_a/boot_b）。

## fstab 说明

`recovery.fstab` 采用 AOSP fstab 格式（同 rosemary），分区名按设备实测 `/dev/block/by-name` 修正：真实分区为 A/B 后缀命名（`tee_a/b`、`lk_a/b`、`sspm_a/b`、`dtbo_a/b` 等），由 `slotselect` 处理；无 modem 分区（WiFi-only 机型）。

## 致谢

- 设备树初始模板由 [twrpdtgen](https://github.com/twrpdtgen/twrpdtgen) 从实测 boot 镜像生成；
- 解密配置参考 [recovery_device_redmi_rosemary](https://github.com/RedmiNote10S/recovery_device_redmi_rosemary)（MT6785 FBE v2）；
- BoardConfig / ramdisk 附件参考了此前 TALIH-PD2-Kernel `twrp` 分支内嵌设备树的实测经验（该分支已废弃，由本仓库取代）。
