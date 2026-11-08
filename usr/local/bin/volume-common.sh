#!/usr/bin/env bash
# Shared volume status functions

# Get current volume status
# Returns: "average_volume:mute_status" (e.g., "50:no" or "0:yes")
get_volume_status() {
    local left right avg mute

    left=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]\+%' | sed -n '1p' | sed 's/%//g')
    right=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]\+%' | sed -n '2p' | sed 's/%//g')

    # Handle case where only one channel is reported
    if [ -z "$left" ]; then
        avg=0
    elif [ -z "$right" ]; then
        avg=$left
    else
        avg=$(((left + right) / 2))
    fi

    mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | sed -n 's/^Mute: //p')

    echo "${avg}:${mute:-no}"
}

# Get appropriate volume icon based on percentage
get_volume_icon() {
    local vol="$1"
    local mute="${2:-no}"

    if [ "$mute" = "yes" ]; then
        echo "volume-x"
    elif [ "$vol" -le 33 ]; then
        echo "volume"
    elif [ "$vol" -le 66 ]; then
        echo "volume-1"
    elif [ "$vol" -le 100 ]; then
        echo "volume-2"
    else
        echo "volume-3"
    fi
}
