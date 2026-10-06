#!/system/bin/sh
# No-PC diagnostics: mirror TWRP's /tmp/recovery.log into the kernel ring
# buffer so the log survives the recovery session and can be read back on
# the running system from /sys/fs/pstore/console-ramchip-0 — but only
# across a WARM reboot (TWRP's Reboot -> System); a forced power-off
# clears the records.
#
# One printf per line: /dev/kmsg truncates oversized single writes.
# The pstore region on this board is ~0xE0000 (896 KB), so a full
# early-session mirror (~100-200 KB) plus init's own action errors fit
# with room to spare. Graphics/USB/decryption diagnostics all land within
# the first ~30s of the session, so one shot at 35s captures them; init's
# own errors reach the kernel log live already.
sleep 35
[ -f /tmp/recovery.log ] || exit 0
while IFS= read -r line; do
    printf '%s\n' "$line" > /dev/kmsg
done < /tmp/recovery.log
