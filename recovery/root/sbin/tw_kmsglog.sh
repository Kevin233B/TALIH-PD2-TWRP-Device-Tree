#!/system/bin/sh
# No-PC diagnostics v5.
#
# Channels:
#  1. kmsg: key lines + bounded dumps of /tmp/recovery.log into /dev/kmsg
#     so they land in the pstore console ring and survive a WARM reboot
#     (TWRP's Reboot -> System); a forced power-off loses that ring.
#  2. misc blob: a full snapshot (probes + logcat + dmesg + recovery.log
#     tails) written to the DEAD ZONE of the misc partition. The BCB
#     struct lives in the first 4 KiB, a 5-byte vendor marker sits at
#     32 KiB, and the 2026-10-07 dump of the whole 512 KiB partition
#     showed everything from 64 KiB to the end as all-zero.
#     v5 layout: core head @64 KiB (64 KiB slot, written by /sbin/corehead
#     from the kernel core_pattern pipe; magic "COREHEADv1"), snapshot
#     @128 KiB (256 KiB slot, last write wins). Both survive forced
#     power-off and fastboot round-trips.
#     Read from the running system with:
#       dd if=/dev/block/by-name/misc bs=512 skip=128 count=128   # core head
#       dd if=/dev/block/by-name/misc bs=512 skip=256 count=512   # snapshot
#     and look for the "COREHEADv1" / "tw_kmsglog v5 snapshot" magic.
#
# Modes:
#   (none)  watch: boot probe + 3 timed shots (used by the rc service)
#   dump    single immediate snapshot (called by the patched decrypt on
#           failure/timeout, or manually from TWRP's terminal)
#
# v5 over v4: crash forensics — logcat captured with -b all (crash buffer
# included), probe reports core_pattern/corehead, layout moved to make
# room for the kernel core-dump head at 64 KiB.
# v4 over v3: keystore2/keymaster/adbd state probes, the logcat/dmesg
# snapshot machinery and the misc blob. v3 fixes retained: /dev/kmsg
# wait (ueventd race), bulk head/tail writes instead of per-line printf
# (v2's fork+exec per line took ~60ms each and stalled the shots).

MISC=/dev/block/by-name/misc
MISC_OFF_KB=128
RD=/tmp/twrp-diag.txt

kmsg() { echo "$*" > /dev/kmsg 2>/dev/null; }

probe_str() {
    echo "probe [$1] uptime=[$(cat /proc/uptime 2>/dev/null)] UDC=[$(cat /config/usb_gadget/g1/UDC 2>/dev/null)] state=[$(cat /sys/class/udc/usb0/state 2>/dev/null)] ffs.ready=[$(getprop sys.usb.ffs.ready)] adbd=[$(getprop init.svc.adbd)] adbd_pid=[$(getprop init.svc_debug_pid.adbd)] km=[$(getprop init.svc.keymaster-4-1)] km_pid=[$(getprop init.svc_debug_pid.keymaster-4-1)] ks2=[$(getprop init.svc.keystore2)] ks2_pid=[$(getprop init.svc_debug_pid.keystore2)] logd=[$(getprop init.svc.logd)] core_pattern=[$(cat /proc/sys/kernel/core_pattern 2>/dev/null)] corehead=[$([ -x /sbin/corehead ] && echo yes || echo no)] dm=[$(cat /sys/block/dm-*/dm/name 2>/dev/null | tr '\n' ',')] data_mnt=[$(grep -c ' /data ' /proc/mounts 2>/dev/null)] metadata_mnt=[$(grep -c ' /metadata ' /proc/mounts 2>/dev/null)] crypto_blkdev=[$(getprop ro.crypto.fs_crypto_blkdev)] log_size=[$(wc -c < /tmp/recovery.log 2>/dev/null)]"
}

snapshot() {
    tag="$1"
    {
        echo "=== tw_kmsglog v5 snapshot tag=$tag date=$(date 2>/dev/null)"
        probe_str "$tag"
        echo "--- ps (key services):"
        ps -A 2>/dev/null | grep -aE "keystore2|keymaster|recovery|adbd|logd"
        echo "--- logcat juicy (keystore2/keymaster/vold/hwservicemanager):"
        /system/bin/logcat -d -v time -b all 2>/dev/null | grep -aE "keystore2|KeyMint|keymaster|Keymaster|vold|KeyStorage|hwservicemanager|Decrypt|SIGBUS|Fatal signal" | tail -n 300
        echo "--- logcat tail:"
        /system/bin/logcat -d -v time -b all 2>/dev/null | tail -n 400
        echo "--- dmesg tail:"
        dmesg 2>/dev/null | tail -n 200
        echo "--- recovery.log tail:"
        tail -n 300 /tmp/recovery.log 2>/dev/null
        echo "=== snapshot end ==="
    } > $RD 2>&1

    # kmsg: compact version, single bounded write
    {
        echo "tw_kmsglog: ===== v5 snapshot [$tag] ====="
        probe_str "$tag"
        sed -n "/--- logcat juicy/,/--- logcat tail:/p" $RD 2>/dev/null | tail -c 24576
        echo "tw_kmsglog: ===== end snapshot [$tag] ====="
    } > /dev/kmsg 2>/dev/null

    # misc dead-zone blob (last write wins; single slot at 128 KiB)
    if [ -e "$MISC" ]; then
        dd if=$RD of=$MISC bs=1024 seek=$MISC_OFF_KB count=256 conv=notrunc 2>/dev/null
    fi
}

case "$1" in
    dump)
        snapshot dump
        kmsg "tw_kmsglog: dump-mode snapshot written"
        exit 0
        ;;
esac

# watch mode
w=0
while [ ! -e /dev/kmsg ] && [ "$w" -lt 50 ]; do sleep 0.2; w=$((w+1)); done

snapshot boot

sleep 16
kmsg "tw_kmsglog: [shot1-head] beginning"
head -c 131072 /tmp/recovery.log > /dev/kmsg 2>/dev/null
snapshot shot1

sleep 24
kmsg "tw_kmsglog: [shot2-tail] beginning"
tail -n 400 /tmp/recovery.log > /dev/kmsg 2>/dev/null
snapshot shot2

sleep 25
kmsg "tw_kmsglog: [shot3-tail] beginning"
tail -n 200 /tmp/recovery.log > /dev/kmsg 2>/dev/null
snapshot shot3
kmsg "tw_kmsglog: complete (v5)"
