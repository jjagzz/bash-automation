#!/usr/bin/env bash
# common.sh - shared function library. Use: source lib/common.sh

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$LIB_DIR")")"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE=""

# init_logging <name>  -> logs go to logs/<name>.log
init_logging() {
    local name="$1"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/${name}.log"
}

# log <LEVEL> <message...>
log() {
    local level="$1"; shift
    local line
    line="[$(date '+%F %T')] [$level] $*"
    echo "$line"
    if [[ -n "$LOG_FILE" ]]; then
        echo "$line" >> "$LOG_FILE"
    fi
}

# validate_safe_path <path>  -> must be non-empty, inside $HOME, no "..", safe chars only
validate_safe_path() {
    local path="${1:-}"
    if [[ -z "$path" ]]; then
        log ERROR "Path is empty"; return 1
    fi
    if [[ "$path" != "$HOME"/* ]]; then
        log ERROR "Path must be inside $HOME: $path"; return 1
    fi
    if [[ "$path" == *..* ]]; then
        log ERROR "Path traversal ('..') not allowed: $path"; return 1
    fi
    if [[ ! "$path" =~ ^[A-Za-z0-9_./-]+$ ]]; then
        log ERROR "Path contains illegal characters: $path"; return 1
    fi
    return 0
}

# validate_dir_exists <path>
validate_dir_exists() {
    local path="${1:-}"
    if [[ ! -d "$path" ]]; then
        log ERROR "Not a directory: $path"; return 1
    fi
    return 0
}

# validate_percent <value>  -> integer 1-100
validate_percent() {
    local value="${1:-}"
    if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value < 1 || value > 100 )); then
        log ERROR "Threshold must be an integer 1-100, got: '$value'"; return 1
    fi
    return 0
}

# check_threshold <name> <value> <limit>  -> returns 0 if OK, 1 if over limit
check_threshold() {
    local name="$1" value="$2" limit="$3"
    if (( value >= limit )); then
        log WARN "$name at ${value}% (limit ${limit}%) - ALERT"
        return 1
    fi
    log INFO "$name at ${value}% (limit ${limit}%) - OK"
    return 0
}
