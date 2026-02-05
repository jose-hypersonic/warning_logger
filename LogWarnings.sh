#!/bin/sh

[ -z "$1" ] && { echo "usage: ./extract_warnings.sh <log_path>"; exit 1; }
[ ! -f "$1" ] && { echo "log not found: $1"; exit 1; }

LOG="$1"
DIR="$(dirname "$LOG")"
NAME="$(basename "$LOG" .log)"
DATE="$(date +%F)"
OUT="$DIR/${NAME}_warnings_${DATE}.log"

grep -Ei 'Log[^:]*: Warning|warning:' "$LOG" > "$OUT"

echo "$OUT"
