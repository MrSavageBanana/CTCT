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
# created with Claude. Account: Burhan Ra'if Kouri
check_dependencies() {
  # just the dependencies that vivaldimods and matt_damon rely on.
  local deps=("awk" "basename" "bash" "chattr" "curl" "diff" "echo" "file" "grep" "kil" "mapfile" "pgrep" "readarray" "rm" "sed" "strace" "sudo" "systemctl" "tee" "uniq" "xargs")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing_dependencies+=("$dep")
    fi
  done
  if [[ "${#missing_dependencies[@]}" -eq 0 ]]; then
    echo "No Dependencies Missing"
  elif [[ "${#missing_dependencies[@]}" -ne 0 ]]; then
    echo_red "${#missing_dependencies[@]}" 'missing dependencies!:'
    for missing_dependency in "${missing_dependencies[@]}"; do
      sudo pacman -S --needed --noconfirm "$missing_dependency" # has to attempt to install missing dependencies.
    done
  else
    echo_red "missing_dependencies array is not working. Array:"
    "${missing_dependencies[@]}"
    exit
  fi

}
closetabs2() {
  domains=()
  ids=()

  while IFS=$'\t' read -r domain id; do
    domains+=("$domain")
    ids+=("$id")
  done < <(curl -s http://localhost:9222/json/list | awk -F '"' '
    /"id":/ { id = $4 }
    /"url": "https?:\/\// { split($4, a, "/"); print a[3] "\t" id } 
    ')
  for i in "${!domains[@]}"; do
    if awk '!/#/ && /0.0.0.0/ {print $2}' /etc/hosts | grep -qFx "${domains[$i]}"; then
      curl -s "http://localhost:9222/json/close/${ids[$i]}" >/dev/null
    else
      # if the user has many links from the same domain but they aren't in the /etc/hosts, just remove all of them.
      for dom in "${domains[@]}"; do
        if [[ "$dom" == "${domains[$i]}" ]]; then
          unset "domains[$i]"
          unset "ids[$i]"
        fi
      done
    fi
  done
}

check_browser() {
  local browser="$1"
  local cmdline

  # Turn this into an array then talk to unscripted about problems
  mapfile -t PIDS < <(pgrep -f "$browser")
  # Browser isn't running, nothing to do
  for pid in "${PIDS[@]}"; do
    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
      return
    fi
  done

  # Any browser that isn't vivaldi gets killed immediately
  if [[ "$browser" != *"vivaldi"* ]]; then

    for pid2 in "${PIDS[@]}"; do
      kill "$pid2"
    done
    return
  fi

  # Vivaldi must have the flag or it gets killed
  cmdline=$(pgrep -fa "$browser" | grep -v "type" | awk '{$1=""; print $0}' | grep --only-matching -- "--remote-debugging-port=9222")
  if [[ "$cmdline" != "--remote-debugging-port=9222" ]]; then
    for pid3 in "${PIDS[@]}"; do
      kill "$pid3"
    done
  elif [[ "$cmdline" == "--remote-debugging-port=9222" ]]; then
    closetabs2
  fi
}

read_desktop_files() {
  grep -Rl "Categories=.*WebBrowser" /usr/share/applications \
    ~/.local/share/applications /var/lib/flatpak/app/*/current/active/files/share/applications 2>/dev/null | xargs awk -F'[= ]' \
    '/^Exec=/{print $2}' /usr/share/applications/vivaldi-stable.desktop | uniq
}

load_browsers() {
  mapfile -t browsers < <(read_desktop_files)
  # readarray -t -O "${#browsers[@]}" browsers < "/etc/browsers.txt" # this will add duplicates likely but it isn't that big of a deal.
  # This is from gemini and will remove duplicates
  readarray -t browsers < <(
    {
      for item in "${browsers[@]}"; do
        echo "$item"
      done
      cat "/etc/browsers.txt" 2>/dev/null
    } | awk '!seen[$0]++'
  )

  for b in "${browsers[@]}"; do
    b2=$(command -v "$b")
    b3=$(file --mime-type -bL "$b2" | awk '{split($NF, a, "/"); print a[1]}')
    if [[ $b3 = 'text' ]]; then
      # b4=$(strace -e trace=execve "$b2" --version |& awk -F "\"" '/^execve/ && /0$/ {print $2}' | awk -F "/" '{print $NF}' | tail -n 1) # same as below but less pipes. Used AI to make the single awk command below
      b4=$(strace -e trace=execve "$b2" --version |& awk -F'"' '/^execve/ && /0$/ { n = split($2, arr, "/"); result = arr[n] } END { if (result) print result }')
      browsers+=("$b4")
    elif [[ $b3 = 'application' ]]; then
      browsers+=("$b3")
    fi
  done
  for bro in "${browsers[@]}"; do
    if ! grep "$bro" /etc/browsers.txt &>/dev/null; then
      echo "$bro" | sudo tee --append /etc/browsers.txt >/dev/null
    fi
  done
}
i=0
while [[ $i -lt 2 ]]; do
  if [[ ! -e /etc/browsers.txt ]]; then
    load_browsers
  elif [[ -e /etc/browsers.txt ]]; then
    if [[ "${#browsers[@]}" -eq 0 ]]; then
      load_browsers
    fi
  fi
  for browser in "${browsers[@]}"; do
    check_browser "$browser"
  done
  ((i++))
done
