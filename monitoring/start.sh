#!/usr/bin/env bash

# Starts all monitoring scripts

script_dir_path=$(dirname $(realpath "$0"))
screen_monitor_id='monitoring'
monitor_scripts_prefix='monitor'

# First check if there is an already active monitoring session
if screen -ls "$screen_monitor_id" > /dev/null != 0;
then
    echo 'Monitoring scripts already seem to be running. Perhaps you want to first stop them?'
    echo '> ./stop.sh'
    exit 1
fi

# Create new daemon screen session dedicated to monitoring
(cd $script_dir_path; screen -dmS $screen_monitor_id)

# Find all monitoring scripts and send them to background
for script in $script_dir_path/$monitor_scripts_prefix*;
do
	screen -S $screen_monitor_id -X stuff "exec $script &^M"
done

echo 'Started all monitoring scripts.'