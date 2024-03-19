# Sourceable bash file that serves as the "shell" for monitoring scripts.
# Provides core functions and abstracts notification channels.

# Configuration variables in regards to which Telegram chat to use to notify server owners of server events.
declare chat_id=
declare topic_id=
declare bot_token=

# Configuration variables in regards to special requests that the monitoring instance can receive.
declare allow_cgi=false

# A map/table that registers IPs of clients that triggered detection & prevention.
# Each key is an unique IPv4 address and the mapped value represents how many times it triggered the mechanism of detection & prevention.
# Example: intrusions[34.92.41.111]=3
declare -A intrusions

# An array of callbacks that server owners register to handle a request log.
declare -a handlers

# Absolute path of the directory this file exists.
script_dir_path=$(dirname $(realpath "$0"))

# Maximum number of events until a prevention mechanism is triggered.
max_failure_events=5

# Time until intrusions table is flushed (in seconds).
flush_intrusions_time_sec=$((5 * 60))

# Loads environment variables defined on the .env file.
load_env() {
	topic="$1"

	env_path="$script_dir_path/.env"

	if [ ! -f $env_path ]; then
		echo '.env file is not present.'
		exit 1
	fi

	source $env_path

	chat_id="$telegram_chat_id"
	topic_id_key=telegram_"$topic"_topic_id
	topic_id="${!topic_id_key}"
	bot_token="$telegram_bot_token"
}

# Notifies server owners of an event.
alert_message() {
	message=$1
	message_escaped=$(echo "${message//\"/"\\\""}")

	curl -X POST \
		-H 'Content-Type: application/json' \
		-d "{\"chat_id\": \"$chat_id\", \"text\": \"$message_escaped\", \"message_thread_id\": \"$topic_id\"}" \
		"https://api.telegram.org/$bot_token/sendMessage" \
		-o /dev/null -s
}

# Notifies server owners of an error event.
alert_error() {
	error_message=$1
	uuid=$(cat /proc/sys/kernel/random/uuid)

	echo "error: $error_message ($uuid)"

	alert_message "🚨⛔️ Something went wrong processing a log message!\nPlease check the logs for transaction id: $uuid."
}

# Prevents intrusors of establishing new connections with the server.
prevent() {
	ip="$1"

	if [ ${intrusions[$ip]} -gt $max_failure_events ]; then
		echo "blocking IP ($1)!"

		# sudo iptables -A INPUT $ip -j DROP
		# sudo iptables -A OUTPUT $ip -j DROP
	fi
}

# Detects if a request had origin from an intruder.
detection() {
	read ip user_agent status endpoint < <(echo $(echo "$1" | jq -r '.IP, ."User-Agent", .Status, .Endpoint'))

	if [ $status -gt 399 ]; then
		intrusions[$ip]=$((intrusions[$ip] + 1))
	fi

	if [ $(
		echo $endpoint | grep -q -Ev "* /cgi-bin"
		echo $?
	) != 0 && !$allow_cgi ]; then
		intrusions[$ip]=$max_failure_events
	fi

	prevent $ip
}

# Spawns a scheduler that periodically flushes the intrusions table.
schedule_flush_intrusions() {
	while [ true ]; do
		sleep $flush_intrusions_time_sec
		unset intrusions

		echo "Flushed intrusions table."
	done &
}

# Registers a callback that handles a request log.
register_handler() {
	callback="$1"

	handlers+=("$callback")
}

# The most basic request log handler that simlpy alerts server owners of a new request.
default_handler() {
	request_log="$1"

	alert_message "ℹ️ New request!\n$request_log"
}

# A request log handler that checks if a request matches a regex pattern. If so, executes a callback.
pattern_handler() {
	request_log="$1"
	pattern="$2"
	on_match_callback="$3"

	if [ $(
		echo $request_log | grep -q -Ev "$pattern"
		echo $?
	) != 0 ]; then
		"${on_match_callback}" "${request_log}"
	fi
}

# A request log handler that sends a request to detection phase.
detection_handler() {
	request_log="$1"

	detection $request_log
}

# Initializes the monitoring script. This function should be the last call of each monitoring scripts.
init() {
	topic="$1"

	load_env $topic
	register_handler "default_handler"
	register_handler "detection_handler"

	tail -fn0 /var/log/nginx/$topic.access.log |
		while read line; do
			log_message=$(echo "$line" | jq)
			if [ $? != 0 ]; then
				alert_error "(jq) failed to parse line: $line"
				continue
			else
				for handler in "${handlers[@]}"; do
					"${handler}" "${log_message}"
				done
			fi
		done
}
