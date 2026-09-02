#!/bin/bash
# test_laptop_restart.sh
# Mục đích: Kiểm tra xem job có sống qua laptop restart không
# Cách dùng: chạy script này trong terminal JupyterHub trước khi restart laptop

set -e

LOG="/home/jovyan/SharedFolder/restart_test.log"
PIDFILE="/home/jovyan/SharedFolder/restart_test.pid"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Dừng instance cũ nếu có
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "Dừng instance cũ (PID: $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
    fi
    rm -f "$PIDFILE"
fi

# Xóa log cũ
rm -f "$LOG"

log "=== TEST START ==="
log "Script PID: $$"
log "Node: $(hostname)"
log "Pod IP: $(hostname -I | awk '{print $1}')"

# Ghi PID để có thể kill sau này
echo $$ > "$PIDFILE"

# Vòng lặp chính — ghi log mỗi 30s
COUNT=0
while true; do
    COUNT=$((COUNT + 1))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tick #${COUNT} — job vẫn chạy bình thường" >> "$LOG"
    sleep 30
done
