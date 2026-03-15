#!/bin/bash

STREAM="http://STL_PLAYOUT_URL_HERE"
TX="10.69.69.69" #Transmitter or RDS TCP Server here
PORT="5555" #Port of your RDS TCP Server, leave default for Aqua Broadcast Cobalt series. 

KUMA_URL="https://YOUR_UPTIMEKUMA_PUSH_MONITOR_URL" #Optional, but adds some nice momitoring and will log changes in the heartbeats

CONNECT_TIMEOUT=10
STREAM_MAX_TIME=300
NC_TIMEOUT=1
RECONNECT_DELAY=3

LAST=""

push_kuma() {
    local status="$1"
    local msg="$2"

    curl -fsS --max-time 10 --get \
        --data-urlencode "status=${status}" \
        --data-urlencode "msg=${msg}" \
        "$KUMA_URL" >/dev/null 2>&1 || true
}

while true; do
    echo "$(date '+%F %T') Connecting to stream..."

    curl -s --connect-timeout "$CONNECT_TIMEOUT" --max-time "$STREAM_MAX_TIME" \
        -H "Icy-MetaData: 1" "$STREAM" \
    | stdbuf -oL strings \
    | stdbuf -oL grep "StreamTitle=" \
    | while IFS= read -r line; do
        TITLE=$(printf '%s' "$line" \
            | sed -n "s/.*StreamTitle='\(.*\)';.*/\1/p" \
            | tr -d '\r' \
            | sed 's/[[:space:]]\+/ /g; s/^ *//; s/ *$//' \
            | cut -c1-64)

        [ -z "$TITLE" ] && continue
        [ "$TITLE" = "$LAST" ] && continue

        if printf 'TEXT=%s\r' "$TITLE" | nc -w "$NC_TIMEOUT" "$TX" "$PORT" >/dev/null 2>&1; then
            echo "$(date '+%F %T') RDS updated: $TITLE"
            push_kuma "up" "Updated"
            LAST="$TITLE"
        else
            echo "$(date '+%F %T') TX send failed"
            push_kuma "down" "TX send failed"
        fi
    done

    echo "$(date '+%F %T') Stream disconnected, reconnecting..."
    push_kuma "down" "Stream disconnected"
    sleep "$RECONNECT_DELAY"
done

