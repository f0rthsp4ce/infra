#!/usr/bin/env bash

filter_papermc() {
	sed -u '
		# Strip time.
		# "[21:15:09 INFO]" -> "INFO"
		s/^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9] \([A-Z]\+\)\]/\1/

		# Strip IP addresses
		# "INFO: nickname[/10.0.0.1:1234] " -> "INFO: nickname "
		s/^INFO: \([a-zA-Z0-9_-]\+\)\[\/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:[0-9]\+\] /INFO: \1 /

		# Strip "[Not Secure]"
		# "INFO: [Not Secure] <nickname> hello" -> "INFO: <nickname> hello"
		s/^INFO: \[Not Secure\] <\([a-zA-Z0-9_-]\+\)> /INFO: <\1> /

		# Delete messages created during backup
		/Thread RCON Client \/192\.168\.16\.5 shutting down$/d
		/Thread RCON Client \/192\.168\.16\.5 started$/d
		/\[Rcon: Automatic saving is now disabled\]$/d
		/\[Rcon: Automatic saving is now enabled\]$/d
		/\[Rcon: Saved the game\]$/d

		# Strip "INFO:"
		# "INFO: ..." -> "..."
		s/^INFO: //
	'
}

case "$1" in
	telegram-bot)
		journalctl --unit f0rthsp4ce-bot-v1.service \
			--output=cat \
			--lines 0 --follow | \
			sed -u 's/bot[0-9]\+:[0-9a-zA-Z_-]\{35\}\b/[redacted]/' | \
			$SENDER_PATH "https://t.me/c/2070662990/8944"
			# $SENDER_PATH "https://t.me/c/1909689525/773"
		;;

	papermc)
		while :;do
			until [ "$(docker ps --quiet --filter 'name=^/papermc-papermc-1$')" ]; do sleep 1; done
			sleep 0.5
			echo minecraft server is up
			docker logs --follow --tail 0 papermc-papermc-1 | filter_papermc || true
			echo minecraft server is down
			sleep 0.5
		done | $SENDER_PATH "https://t.me/c/2070662990/197"
		;;

	filter_papermc) filter_papermc;;
	*) echo ":(";;
esac

exit 1 # unreachable in normal circumstances