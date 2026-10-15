#!/usr/bin/env bash
# Task 1 - Idempotent directory and file creation (basic version)

BASE_DIR="$HOME/devops-lab"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# -p = create parents as needed, and no error if it already exists
mkdir -p "$BASE_DIR"/projects/app/{src,config,logs}
mkdir -p "$BASE_DIR"/{backups,reports}

# Static file: only create if missing, so re-runs never overwrite it
CONFIG_FILE="$BASE_DIR/projects/app/config/app.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
    echo "APP_NAME=demo-app" >> "$CONFIG_FILE"
    echo "APP_ENV=development" >> "$CONFIG_FILE"
    echo "Created: $CONFIG_FILE"
else
    echo "Skipped (already exists): $CONFIG_FILE"
fi

# Dynamic files: timestamp in the name, so every run adds a new one
LOG_FILE="$BASE_DIR/projects/app/logs/app_${TIMESTAMP}.log"
touch "$LOG_FILE"
echo "Log started at $(date)" > "$LOG_FILE"
echo "Created: $LOG_FILE"

REPORT_FILE="$BASE_DIR/reports/report_${TIMESTAMP}.txt"
echo "Report generated: $(date '+%F %T')" > "$REPORT_FILE"
echo "Created: $REPORT_FILE"

echo "Done."
