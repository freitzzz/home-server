#!/usr/bin/env bash

# Monitors NGINX access logs for immich.joaomagfreitas.link

source shell.sh

on_authentication_attempt() {
	request_log="$1"

	alert_message "🚨 New authentication attempt to immich.joaomagfreitas.link! 🚨\n$request_log"
}

authentication_attempt_handler() {
	request_log="$1"

	pattern_handler "$request_log" "POST /api/auth" "on_authentication_attempt"
}

register_handler "authentication_attempt_handler"

init
