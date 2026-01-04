#!/bin/sh

# XGPv3 SARADC Reset Button Handler Script by zzzz0317

PRESS_TIME_FILE="/tmp/xgpv3_saradc_reset_button_press_time"
LOG_TAG="xgpv3_saradc_reset_button"

log_kmsg() {
    echo "<6>[$LOG_TAG] $1" > /dev/kmsg
}

get_timestamp() {
    cat /proc/uptime | awk '{print int($1)}'
}

handle_press() {
    log_kmsg "Reset button PRESSED"
    get_timestamp > "$PRESS_TIME_FILE"
    echo timer > /sys/class/leds/blue:status/trigger
    echo 500 > /sys/class/leds/blue:status/delay_on
    echo 500 > /sys/class/leds/blue:status/delay_off
}

handle_release() {
    log_kmsg "Reset button RELEASED"
    if [ ! -f "$PRESS_TIME_FILE" ]; then
        log_kmsg "ERROR: No press time recorded"
        return 1
    fi
    press_time=$(cat "$PRESS_TIME_FILE")
    release_time=$(get_timestamp)
    duration=$((release_time - press_time))
    
    log_kmsg "Button held for ${duration} seconds"
    rm -f "$PRESS_TIME_FILE"

    if [ "$duration" -ge 10 ]; then
        log_kmsg "FACTORY RESET triggered (held for ${duration}s)"
        logger -t "$LOG_TAG" "Factory reset initiated - button held for ${duration} seconds"
        echo timer > /sys/class/leds/blue:status/trigger
        echo 50 > /sys/class/leds/blue:status/delay_on
        echo 50 > /sys/class/leds/blue:status/delay_off
        echo timer > /sys/class/leds/blue:wan/trigger
        echo 50 > /sys/class/leds/blue:wan/delay_on
        echo 50 > /sys/class/leds/blue:wan/delay_off
        echo "FACTORY RESET" > /dev/console
        sleep 3
        jffs2reset -y && reboot &
        
    elif [ "$duration" -ge 1 ]; then
        log_kmsg "REBOOT triggered (held for ${duration}s)"
        logger -t "$LOG_TAG" "Reboot initiated - button held for ${duration} seconds"
        echo timer > /sys/class/leds/blue:status/trigger
        echo 250 > /sys/class/leds/blue:status/delay_on
        echo 250 > /sys/class/leds/blue:status/delay_off
        echo timer > /sys/class/leds/blue:wan/trigger
        echo 250 > /sys/class/leds/blue:wan/delay_on
        echo 250 > /sys/class/leds/blue:wan/delay_off
        echo "REBOOT" > /dev/console
        sleep 3
        sync
        reboot &
    else
        log_kmsg "Button press too short (${duration}s), ignoring"
        echo heartbeat > /sys/class/leds/blue:status/trigger
    fi
}

case "$1" in
    press)
        handle_press
        ;;
    release)
        handle_release
        ;;
    *)
        echo "Usage: $0 {press|release}"
        exit 1
        ;;
esac

exit 0