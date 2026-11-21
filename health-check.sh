#!/bin/bash

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "=== Health check ${TIMESTAMP} UTC ==="

MEM_THRESHOLD=80
MEM_USAGE=$(free | awk '/Mem:/ {printf "%d\n", $3/$2*100}')
echo "Memory usage: ${MEM_USAGE}%"
if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    echo "WARNING: Memory usage is above ${MEM_THRESHOLD}%"
else
    echo "OK: Memory usage is within limits"
fi

DISK_THRESHOLD=80
DISK_USAGE=$(df --output=pcent / | tail -n 1 | tr -d ' %')
echo "Disk usage: ${DISK_USAGE}%"
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    echo "WARNING: Disk usage is above ${DISK_THRESHOLD}%"
else
    echo "OK: Disk usage is within limits"
fi

