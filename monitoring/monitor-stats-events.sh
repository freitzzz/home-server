#!/usr/bin/env bash

# Monitors NGINX access logs for stats.joaomagfreitas.link

script_dir_path=$(dirname $(realpath "$0"))

file=/var/log/nginx/stats.access.log

count_hit_pattern="POST /count"

declare chat_id=
declare topic_id=
declare bot_token=

load_env() {
	env_path="$script_dir_path/.env"

	if ! -f $env_path;
	then
		echo '.env file is not present.'
		exit 1
	fi

	source $env_path

	chat_id="$telegram_chat_id"
	topic_id="$telegram_stats_topic_id"
	bot_token="$telegram_bot_token"
}

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

load_env

tail -fn0 $file | \
while read line ; do
	log_message=$(echo "$line" | jq)
	if [ $? != 0 ];
	then
		alert_error "(jq) failed to parse line: $line"
		continue
	elif [ $(echo $log_message | grep -q -Ev "$count_hit_pattern"; echo $?) != 0 ];
	then
		send_message "📈 New count hit has been recorded!\n$log_message"
		continue
	fi

	send_message "ℹ️ New request to stats.joaomagfreitas.link!\n$log_message"
done