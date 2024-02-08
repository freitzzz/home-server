#!/usr/bin/env bash

# Monitors NGINX access logs for immich.joaomagfreitas.link

file=/var/log/nginx/immich.access.log

chat_id="<telegram-monitoring-chat-id>"
topic_id="<telegram-monitoring-channel-id>"
bot_token="<telegram-monitoring-bot-token>"

auth_attempt_pattern="POST /api/auth"

send_message() {
	message=$1
	message_escaped=$(echo "${message//\"/"\\\""}")

	curl -X POST \
        	-H 'Content-Type: application/json' \
        	-d "{\"chat_id\": \"$chat_id\", \"text\": \"$message_escaped\", \"message_thread_id\": \"$topic_id\"}" \
        	"https://api.telegram.org/$bot_token/sendMessage" \
		-o /dev/null -s
}

alert_error() {
	error_message=$1
	uuid=$(cat /proc/sys/kernel/random/uuid)

	echo "error: $error_message ($uuid)"

	send_message "🚨⛔️ Something went wrong processing a log message!\nPlease check the logs for transaction id: $uuid."
}


tail -fn0 $file | \
while read line ; do
	log_message=$(echo "$line" | jq)
	if [ $? != 0 ];
	then
		alert_error "(jq) failed to parse line: $line"
		continue
	elif [ $(echo $log_message | grep -q -Ev "$auth_attempt_pattern"; echo $?) != 0 ];
	then
		send_message "🚨 New authentication attempt to immich.joaomagfreitas.link! 🚨\n$log_message"
		continue
	fi

	send_message "ℹ️ New request to immich.joaomagfreitas.link!\n$log_message"
done