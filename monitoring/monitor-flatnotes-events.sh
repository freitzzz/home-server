#!/usr/bin/env bash

# Monitors NGINX access logs for flatnotes.joaomagfreitas.link

source shell.sh

on_authentication_attempt() {
	request_log="$1"

	alert_message "🚨 New authentication attempt to flatnotes.joaomagfreitas.link! 🚨\n$request_log"
}

authentication_attempt_handler() {
	request_log="$1"

	pattern_handler "$request_log" "POST /api/token" "on_authentication_attempt"
}

register_handler "authentication_attempt_handler"

init "flatnotes"
