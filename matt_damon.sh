#!/bin/bash
# This works just for vivaldi

# while true; do
# PID=$(pgrep --list-full vivaldi-bin | grep -v "type" | awk '{print $1}')
# cmdline=$(pgrep --list-full vivaldi-bin | grep -v "type" | awk '{$1=""; print $0}' | grep --only-matching -- "--remote-debugging-port=9222")
# 
# if [[ "$cmdline" != "--remote-debugging-port=9222" && "$PID" =~ ^[0-9]+$ ]]; then # If $cmdline ≠ "--remote-debugging-port=9222" and $PID is a number then kill the PID
#     kill "$PID"
# elif [[ "$cmdline" == "--remote-debugging-port=9222" ]]; then 
# 	echo ""
# else
# 	echo ""
# fi
# done

# This works for all browsers which display their browser status in a .desktop file
# The working script as a function we can call
close_tab() {
	TMPFILE=$(mktemp)
	trap "rm -f $TMPFILE" EXIT

	cat /etc/hosts | sed '/#/d' | awk '/0.0.0.0/ { count++ } count >= 2' | awk '{print $2}' | sed '/^$/d' > "$TMPFILE"

		curl -s http://localhost:9222/json/list | jq -r '.[] | select(.type=="page") | .url + " " + .id' | while read -r url id; do
		if grep -qFf "$TMPFILE" <<< "$url"; then
			curl -s "http://localhost:9222/json/close/$id" >/dev/null
		fi
	done
}

check_browser() {
    local browser="$1"
    local PID
    local cmdline

    PID=$(pgrep --list-full "$browser" | grep -v "type" | awk '{print $1}')

    # Browser isn't running, nothing to do
    if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
        return
    fi

    # Any browser that isn't vivaldi gets killed immediately
    if [[ "$browser" != *"vivaldi"* ]]; then
        kill "$PID"
        return
    fi

    # Vivaldi must have the flag or it gets killed
    cmdline=$(pgrep --list-full "$browser" | grep -v "type" | awk '{$1=""; print $0}' | grep --only-matching -- "--remote-debugging-port=9222")
    if [[ "$cmdline" != "--remote-debugging-port=9222" ]]; then
        kill "$PID"
    elif [[ "$cmdline" == "--remote-debugging-port=9222" ]]; then
        close_tab
    fi
}

load_browsers() {
    touch browsers.txt # It will create it if it doesn't exist. won't rewrite the file if it exists
    grep -Rl "Categories=.*WebBrowser" /usr/share/applications ~/.local/share/applications 2>/dev/null \
        | xargs awk -F= '/^Exec=/{print $2}' \
        | awk '{print $1}' \
        | awk -F/ '{print $NF}' \
        | sort -u \
        | grep -Fxvf browsers.txt >> browsers.txt

    browsers=()
    if [[ -f "browsers.txt" && -s "browsers.txt" ]]; then
        mapfile -t browsers < <(grep -v '^\s*$' browsers.txt)
    fi
    if [[ ${#browsers[@]} -eq 0 ]]; then
        browsers=("vivaldi-bin")
    fi
}

while true; do
    load_browsers
    for browser in "${browsers[@]}"; do
        check_browser "$browser"
    done
done
