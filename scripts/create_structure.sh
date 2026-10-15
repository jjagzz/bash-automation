#!/usr/bin/env bash
# create_structure.sh - idempotent directory/file creation (refactored)
# Usage: ./create_structure.sh [base_dir]     (default: ~/devops-lab)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
init_logging "create_structure"

usage() { echo "Usage: $0 [base_dir_inside_home]"; }

# create_dir <dir>
create_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        log INFO "Exists:  $dir"
    else
        mkdir -p "$dir"
        log INFO "Created: $dir"
    fi
}

# create_file <path> <content>   (never overwrites an existing file)
create_file() {
    local file="$1" content="$2"
    if [[ -f "$file" ]]; then
        log INFO "Kept:    $file"
        return 0
    fi
    touch "$file"
    echo "$content" > "$file"
    log INFO "Created: $file"
}

main() {
    local base="${1:-$HOME/devops-lab}"
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"

    validate_safe_path "$base" || { usage; exit 2; }

    create_dir "$base/projects/app/src"
    create_dir "$base/projects/app/config"
    create_dir "$base/projects/app/logs"
    create_dir "$base/backups"
    create_dir "$base/reports"

    create_file "$base/projects/app/config/app.conf" "APP_NAME=demo-app"
    create_file "$base/projects/app/logs/app_${ts}.log" "Log started $(date)"
    create_file "$base/reports/report_${ts}.txt" "Report generated $(date '+%F %T')"

    log INFO "Structure ready under $base"
}

main "$@"
