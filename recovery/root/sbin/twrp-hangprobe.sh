#!/system/bin/sh
# TWRP hang probe: dump the state of the stuck metadata-decrypt child into
# the kernel log. Every line lands in the pstore console ring (ramoops),
# which survives a warm reboot into the system, so the state can be read
# from a running Android boot (see roundb notes for the read commands).
pid="$1"
if [ -z "$pid" ] || [ ! -d "/proc/$pid" ]; then
    echo "TWRP-HANG: no pid '$pid'" > /dev/kmsg 2>/dev/null
    exit 1
fi
k() { echo "TWRP-HANG: $*" > /dev/kmsg 2>/dev/null; }
k "=== begin pid=$pid cmd=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null) ==="
k "state=$(awk '{print $3}' /proc/$pid/stat 2>/dev/null) wchan=$(cat /proc/$pid/wchan 2>/dev/null) syscall=$(cat /proc/$pid/syscall 2>/dev/null)"
k "stack=$(tr '\n' '|' < /proc/$pid/stack 2>/dev/null)"
for t in /proc/$pid/task/*; do
    tid=$(basename "$t")
    k "task $tid comm=$(cat $t/comm 2>/dev/null) state=$(awk '{print $3}' $t/stat 2>/dev/null) wchan=$(cat $t/wchan 2>/dev/null)"
    k "task $tid stack=$(tr '\n' '|' < $t/stack 2>/dev/null)"
done
for c in $(cat /proc/$pid/task/*/children 2>/dev/null | tr ' ' '\n' | sort -u); do
    [ -n "$c" ] || continue
    k "child $c comm=$(cat /proc/$c/comm 2>/dev/null) cmd=$(tr '\0' ' ' < /proc/$c/cmdline 2>/dev/null)"
    k "child $c state=$(awk '{print $3}' /proc/$c/stat 2>/dev/null) wchan=$(cat /proc/$c/wchan 2>/dev/null) stack=$(tr '\n' '|' < /proc/$c/stack 2>/dev/null)"
done
k "=== end pid=$pid ==="
