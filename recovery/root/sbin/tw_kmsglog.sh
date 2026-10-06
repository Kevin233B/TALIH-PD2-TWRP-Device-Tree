#!/system/bin/sh
# No-PC diagnostics: mirror TWRP's /tmp/recovery.log into the kernel ring
# buffer so the log survives the recovery session and can be read back on
# the running system from /sys/fs/pstore/console-ramoops-0 — but only
# across a WARM reboot (TWRP's Reboot -> System); a forced power-off
# clears the records.
#
# v3 changes over v2 (all verified against the v5 pstore capture):
#  - Wait for /dev/kmsg: the v5 heartbeat + gadget probes were lost — this
#    service starts at on boot, but ueventd only creates /dev/kmsg shortly
#    after (init's own kmsg logging, including its write breadcrumbs and
#    service-exit records, fails the same way: not a single init line ever
#    reached the v5 pstore capture).
#  - Bulk dumps: v2 piped the log line-by-line through external printf
#    (one fork+exec per line, ~60ms each — a 2000-line head shot took 25s
#    and the session outlived shot2). head/tail straight into /dev/kmsg
#    is a single write; the ring renders the embedded newlines.
#  - adbd probes: init.svc.adbd was "restarting" all through v5 while UDC
#    stayed empty and sys.usb.ffs.ready never fired; the probes log state
#    + pid at every shot so the next capture pins the restart loop.
#  - Round C probes: keymaster service state, dm table names and the
#    /data mount count — decrypt verification without a PC.
#
# Budget: the pstore console region keeps only the last ~256 KB of the
# ring, so the first shot is capped and the later ones are tails only.

# Wait for ueventd to create /dev/kmsg (up to 10s, then probe anyway).
w=0
while [ ! -e /dev/kmsg ] && [ "$w" -lt 50 ]; do sleep 0.2; w=$((w+1)); done

kmsg() { echo "$*" > /dev/kmsg 2>/dev/null; }

probe() {
    kmsg "tw_kmsglog: [$1] UDC=[$(cat /config/usb_gadget/g1/UDC 2>/dev/null)] state=[$(cat /sys/class/udc/usb0/state 2>/dev/null)] ffs.ready=[$(getprop sys.usb.ffs.ready)] adbd=[$(getprop init.svc.adbd)] adbd_pid=[$(getprop init.svc_debug_pid.adbd)] km=[$(getprop init.svc.keymaster-4-1)] dm=[$(cat /sys/block/dm-*/dm/name 2>/dev/null | tr '\n' ',')] data_mnt=[$(grep -c ' /data ' /proc/mounts)] log_size=[$(wc -c < /tmp/recovery.log 2>/dev/null)]"
}

probe boot

sleep 16
kmsg "tw_kmsglog: [shot1-head] beginning"
head -c 131072 /tmp/recovery.log > /dev/kmsg 2>/dev/null
probe shot1

sleep 24
kmsg "tw_kmsglog: [shot2-tail] beginning"
tail -n 400 /tmp/recovery.log > /dev/kmsg 2>/dev/null
probe shot2

sleep 25
kmsg "tw_kmsglog: [shot3-tail] beginning"
tail -n 200 /tmp/recovery.log > /dev/kmsg 2>/dev/null
probe shot3
kmsg "tw_kmsglog: complete (v3)"
