#!/system/bin/sh
# No-PC diagnostics: mirror TWRP's /tmp/recovery.log into the kernel ring
# buffer so the log survives the recovery session and can be read back on
# the running system from /sys/fs/pstore/console-ramoops-0 — but only
# across a WARM reboot (TWRP's Reboot -> System); a forced power-off
# clears the records.
#
# v2: self-diagnosing. The v4 one-shot 35s dump never reached pstore: the
# service was the only one in the whole ramdisk without a seclabel, and
# init refuses to start such a service while SELinux is enabled (the
# context derived from the script file, u:object_r:rootfs:s0, is a file
# type, not a process domain), so init's "start tw_kmsglog" was silently
# refused — the error only reached logd, which dies with the session. The
# rc now carries seclabel u:r:recovery:s0; this script additionally
# reports its own liveness, probes the USB gadget state (adb case) and
# refuses to exit silently, so any future failure is diagnosable from the
# next pstore read alone.
#
# Budget: the pstore console region keeps only the last ~256 KB of the
# ring, so the first shot is capped and the later ones are tails only.
kmsg() { printf '%s\n' "$*" > /dev/kmsg 2>&1; }

kmsg "tw_kmsglog: service running (v2, uptime $(cut -d. -f1 /proc/uptime)s)"
kmsg "tw_kmsglog: UDC=[$(cat /config/usb_gadget/g1/UDC 2>&1)] udc_state=[$(cat /sys/class/udc/usb0/state 2>&1)] ffs=[$(ls /dev/usb-ffs 2>&1 | tr '\n' ' ')]"
kmsg "tw_kmsglog: usb mounts [$(grep -E 'configfs|functionfs' /proc/mounts | tr '\n' ';')]"

dump() {  # $1 = label, $2 = filter command (takes the log path as argument)
    kmsg "tw_kmsglog: [$1] UDC=[$(cat /config/usb_gadget/g1/UDC 2>&1)] state=[$(cat /sys/class/udc/usb0/state 2>&1)] size=[$(wc -c < /tmp/recovery.log 2>/dev/null)]"
    if [ ! -f /tmp/recovery.log ]; then
        kmsg "tw_kmsglog: [$1] no /tmp/recovery.log; /tmp: [$(ls /tmp 2>&1 | tr '\n' ' ')]"
        return 0
    fi
    $2 /tmp/recovery.log | while IFS= read -r line; do
        printf '%s\n' "$line" > /dev/kmsg 2>&1
    done
    kmsg "tw_kmsglog: [$1] end"
}

sleep 14
dump shot1-head "head -c 131072"
sleep 16
dump shot2-tail "tail -n 400"
sleep 15
dump shot3-tail "tail -n 150"
kmsg "tw_kmsglog: complete"
