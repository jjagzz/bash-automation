#!/usr/bin/env bash
# health_monitor.sh - system health check with thresholds, validation, cleanup
# Usage: ./health_monitor.sh [disk_path] [threshold_percent]
#   e.g. ./health_monitor.sh / 80
# Exit codes: 0 healthy | 1 threshold exceeded | 2 bad input | 130 interrupted
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
init_logging "health_monitor"

REPORT_DIR="${REPORT_DIR:-$HOME/devops-lab/reports}"
TMP_FILE=""

# ---- trap handlers ----------------------------------------------------------
cleanup() {
    local code=$?                       # exit code of the script
    if [[ -n "$TMP_FILE" && -f "$TMP_FILE" ]]; then
        rm -f "$TMP_FILE"
        log INFO "Removed temp file"
    fi
    log INFO "Exiting with code $code"
    exit "$code"
}
trap cleanup EXIT                                        # runs on any exit
trap 'log WARN "Interrupted by user"; exit 130' INT TERM # Ctrl+C / kill

usage() { echo "Usage: $0 [disk_path] [threshold_percent]"; }

# ---- metric functions (print a number) --------------------------------------
get_disk_usage() {     # $1 = path
    df --output=pcent "$1" | tail -n 1 | tr -dc '0-9'
}
get_mem_usage() {
    free | awk '/^Mem:/ {printf "%d", $3/$2*100}'
}
get_cpu_usage() {      # 1-min load average as % of core count
    local load cores
    load="$(awk '{print $1}' /proc/loadavg)"
    cores="$(nproc)"
    awk -v l="$load" -v c="$cores" 'BEGIN {printf "%d", l/c*100}'
}

main() {
    local path="${1:-/}"
    local limit="${2:-80}"

    # ---- input validation ----
    validate_dir_exists "$path" || { usage; exit 2; }
    validate_percent "$limit"   || { usage; exit 2; }

    mkdir -p "$REPORT_DIR"
    TMP_FILE="$(mktemp)"
    # Demo hook for testing the trap: DEMO_SLEEP=10 ./health_monitor.sh
    sleep "${DEMO_SLEEP:-0}"

    # ---- capture into variables ----
    local disk mem cpu procs
    disk="$(get_disk_usage "$path")"
    mem="$(get_mem_usage)"
    cpu="$(get_cpu_usage)"
    procs="$(ps -e --no-headers | wc -l)"

    log INFO "Host: $(hostname) | Processes: $procs | Disk path: $path"

    # ---- compare against thresholds, capture exit codes with $? ----
    local status=0 rc=0

    rc=0; check_threshold "Disk"   "$disk" "$limit" || rc=$?
    if [[ $rc -ne 0 ]]; then status=1; fi

    rc=0; check_threshold "Memory" "$mem"  "$limit" || rc=$?
    if [[ $rc -ne 0 ]]; then status=1; fi

    rc=0; check_threshold "CPU"    "$cpu"  "$limit" || rc=$?
    if [[ $rc -ne 0 ]]; then status=1; fi

    # ---- build the report in a temp file, then move into place ----
    {
        echo "=== Health Report $(date '+%F %T') ==="
        echo "Disk($path)=${disk}%  Memory=${mem}%  CPU=${cpu}%  Threshold=${limit}%"
        echo "--- Top 5 processes by memory ---"
        ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6
        echo "--- Disk overview ---"
        df -h
        echo "--- Memory ---"
        free -h
    } > "$TMP_FILE"

    local report="$REPORT_DIR/health_$(date +%Y%m%d_%H%M%S).txt"
    mv "$TMP_FILE" "$report"
    TMP_FILE=""                         # moved, so nothing left to clean
    log INFO "Report saved: $report"

    if [[ $status -eq 0 ]]; then
        log INFO "RESULT: system healthy"
    else
        log ERROR "RESULT: one or more thresholds exceeded"
    fi
    return "$status"
}

main "$@"
