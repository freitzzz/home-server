#!/usr/bin/env bash

# Monitors NGINX access logs for stats.joaomagfreitas.link

source shell.sh

on_count_hit() {
	request_log="$1"

	alert_message "📈 New count hit has been recorded!\n$request_log"
}

count_hit_handler() {
	request_log="$1"

	pattern_handler "$request_log" "POST /count" "on_count_hit"
}

register_handler "count_hit_handler"

init "stats"
