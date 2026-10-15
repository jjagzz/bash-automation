#!/usr/bin/env bash
# Task 2 - System health monitor (basic version)

CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80

# Capture system info into variables
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
MEM_USAGE=$(free | awk '/^Mem:/ {printf "%d", $3/$2*100}')
LOAD=$(awk '{print $1}' /proc/loadavg)
CORES=$(nproc)
CPU_USAGE=$(awk -v l="$LOAD" -v c="$CORES" 'BEGIN {printf "%d", l/c*100}')
PROC_COUNT=$(ps -e --no-headers | wc -l)

echo "=== Health Report: $(date '+%F %T') ==="
echo "Disk: ${DISK_USAGE}% | Memory: ${MEM_USAGE}% | CPU load: ${CPU_USAGE}% | Processes: $PROC_COUNT"

STATUS=0

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    echo "ALERT: disk usage high"; STATUS=1
fi
if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
    echo "ALERT: memory usage high"; STATUS=1
fi
if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
    echo "ALERT: CPU load high"; STATUS=1
fi

echo "Top 5 processes by memory:"
ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -6

# $? holds the exit code of the LAST command
grep -q "processor" /proc/cpuinfo
if [ $? -eq 0 ]; then
    echo "CPU info check: OK"
else
    echo "CPU info check: FAILED"; STATUS=1
fi

if [ "$STATUS" -eq 0 ]; then
    echo "RESULT: system healthy"
else
    echo "RESULT: problems detected"
fi
exit "$STATUS"
