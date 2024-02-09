#!/usr/bin/env bash

# Stops all monitoring scripts

screen_monitor_id='monitoring'

# First check if there is an active monitoring session
if ! screen -ls "$screen_monitor_id" > /dev/null = 0;
then
    echo "Monitoring scripts don't seem to be running. Perhaps you want to first start them?"
    echo '> ./start.sh'
    exit 1
fi

# Send kill signal to stop monitoring daemon session
screen -S $screen_monitor_id -X quit

echo 'Stopped all monitoring scripts.'