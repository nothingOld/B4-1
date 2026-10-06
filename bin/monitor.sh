#!/usr/bin/env bash

# 시스템 상태를 점검하고 주요 리소스 사용량을 로그로 기록한다.

APP_NAME="agent-app-linux-x86"
APP_PATH="/home/agent-admin/agent-app/agent-app-linux-x86"
APP_PORT="15034"
LOG_FILE="/var/log/agent-app/monitor.log"

CPU_THRESHOLD="20"
MEM_THRESHOLD="10"
DISK_THRESHOLD="80"

echo "====== SYSTEM MONITOR RESULT ======"
echo
echo "[HEALTH CHECK]"

# 애플리케이션 프로세스 확인
PID="$(pgrep -u agent-admin -f "${APP_PATH}" | head -n 1)"

if [[ -z "${PID}" ]]; then
    echo "Checking process '${APP_NAME}'... [FAIL]"
    exit 1
fi

echo "Checking process '${APP_NAME}'... [OK] (PID: ${PID})"

# 애플리케이션 포트 확인
if ! ss -lnt | grep -q ":${APP_PORT} "; then
    echo "Checking port ${APP_PORT}... [FAIL]"
    exit 1
fi

echo "Checking port ${APP_PORT}... [OK]"

# UFW 활성 상태 확인
if grep -q '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null; then
    echo "Checking firewall (UFW)... [OK]"
else
    echo "[WARNING] UFW firewall is inactive."
fi

# CPU 사용률 계산
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

CPU_IDLE_1=$((idle + iowait))
CPU_TOTAL_1=$((user + nice + system + idle + iowait + irq + softirq + steal))

sleep 1

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

CPU_IDLE_2=$((idle + iowait))
CPU_TOTAL_2=$((user + nice + system + idle + iowait + irq + softirq + steal))

CPU_IDLE_DELTA=$((CPU_IDLE_2 - CPU_IDLE_1))
CPU_TOTAL_DELTA=$((CPU_TOTAL_2 - CPU_TOTAL_1))

CPU_USAGE="$(
    awk -v total="${CPU_TOTAL_DELTA}" -v idle="${CPU_IDLE_DELTA}" \
        'BEGIN {
            if (total > 0) {
                printf "%.1f", ((total - idle) * 100 / total)
            } else {
                printf "0.0"
            }
        }'
)"

# 메모리 사용률 계산
MEM_USAGE="$(
    free | awk '/^Mem:/ {
        if ($2 > 0) {
            printf "%.1f", ($3 / $2) * 100
        } else {
            printf "0.0"
        }
    }'
)"

# Root 파티션 디스크 사용률 계산
DISK_USED="$(
    df -P / | awk 'NR == 2 {
        gsub("%", "", $5)
        print $5
    }'
)"

echo
echo "[RESOURCE MONITORING]"
echo "CPU Usage  : ${CPU_USAGE}%"
echo "MEM Usage  : ${MEM_USAGE}%"
echo "DISK Used  : ${DISK_USED}%"

echo

# CPU 임계값 확인
if awk -v value="${CPU_USAGE}" -v limit="${CPU_THRESHOLD}" \
    'BEGIN { exit !(value > limit) }'; then
    echo "[WARNING] CPU threshold exceeded (${CPU_USAGE}% > ${CPU_THRESHOLD}%)"
fi

# 메모리 임계값 확인
if awk -v value="${MEM_USAGE}" -v limit="${MEM_THRESHOLD}" \
    'BEGIN { exit !(value > limit) }'; then
    echo "[WARNING] MEM threshold exceeded (${MEM_USAGE}% > ${MEM_THRESHOLD}%)"
fi

# 디스크 임계값 확인
if awk -v value="${DISK_USED}" -v limit="${DISK_THRESHOLD}" \
    'BEGIN { exit !(value > limit) }'; then
    echo "[WARNING] DISK threshold exceeded (${DISK_USED}% > ${DISK_THRESHOLD}%)"
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
    "${TIMESTAMP}" \
    "${PID}" \
    "${CPU_USAGE}" \
    "${MEM_USAGE}" \
    "${DISK_USED}" >> "${LOG_FILE}"

echo
echo "[INFO] Log appended: ${LOG_FILE}"
