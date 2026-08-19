#!/bin/bash
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
      # has to attempt to install missing dependencies.
      sudo pacman -S --needed --noconfirm "$missing_dependency"
    done
  else
    echo_red "missing_dependencies array is not working. Array:"
    "${missing_dependencies[@]}"
    exit
  fi

}
closetabs() {
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
    fi
  done
}
# assumes that the /etc/focus.txt has this in the following order
# "website" "round"
closetabs_focus() {
  local file="/etc/website-focus.txt"
  local -a domains=() ids=()
  # check if there is any outdate websites existing
  current_round=$(curl -Ss https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/public/latest | awk -F '[\":,]' '{print $4}')
  awk -v current_round="$current_round" -v file="$file" -F '\"' '{
    round_to_end = $4
    if (round_to_end < current_round) {
        cmd = "sudo sed -i '"'"'/" round_to_end "/d'"'"' " file
        system(cmd)
    }
}' "$file"

  # get the existing domains
  while IFS=$'\t' read -r domain id; do
    domains+=("$domain")
    ids+=("$id")
  done < <(
    curl -s http://localhost:9222/json/list | awk -F '"' '
    /"id":/ { id = $4 }
    /"url": "https?:\/\// { sub(/^https?:\/\//, "", $4); print $4 "\t" id }
    '
  )
  for i in "${!domains[@]}"; do
    if grep -qF "${domains[$i]}" "$file"; then
      curl -s "http://localhost:9222/json/close/${ids[$i]}" >/dev/null
    fi
  done

}
focus() {
  local file="/etc/process-focus.txt"
  process=$(awk -F '"' '{print $2}' "$file")
  PIDS=()
  # claude helped with parsing multiple entries. This whole mess is claude's.
  # It is this complicated to ensure it can manage any character in a file(except newlines)
  while IFS= read -r process; do
    [[ -z "$process" ]] && continue
    escaped=$(printf '%s' "$process" | sed -e 's/[.[\*^$()+?{|\\]/\\&/g')
    [[ -z "$escaped" ]] && continue # i ain't taking any risks. I don't want any empty strings.
    mapfile -t -O "${#PIDS[@]}" PIDS < <(pgrep -f -- "$escaped")
  done < <(awk -F '\"' '{print $2}' "$file")
  # dedupe, since two names could theoretically match overlapping PIDs
  mapfile -t PIDS < <(printf '%s\n' "${PIDS[@]}" | sort -un)
  for pid in "${PIDS[@]}"; do
    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
      return
    fi
  done
  current_round=$(curl -Ss https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/public/latest | awk -F '[\":,]' '{print $4}')
  awk -v current_round="$current_round" -v file="$file" -F '\"' '{
      round_to_end = $4
      if (round_to_end < current_round) {
      cmd = "sudo sed -i '"'"'/" round_to_end "/d'"'"' " file
      system(cmd)
      }
      }' "$file"
  for pid2 in "${PIDS[@]}"; do
    kill "$pid2"
  done
}
focus_attr() {
  local file="/etc/file-focus.txt"
  current_round=$(curl -Ss https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/public/latest | awk -F '[\":,]' '{print $4}')
  awk -v current_round="$current_round" -v file="$file" -F '\"' '{
  focus_file = $2
  round_to_end = $4
  if (round_to_end < current_round) {
  cmd2 = "sudo chattr -i " focus_file
  cmd = "sudo sed -i '"'"'/" round_to_end "/d'"'"' " file
  system(cmd2)
  system(cmd)
 } else {
  cmd3 = "sudo chattr +i " focus_file
  system(cmd3)
  }
  }' "$file"
}

check_browser() {
  local browser="$1"
  local cmdline

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
    # apparantely, i can see these echos in journalctl so i am going to add them even if they aren't really ever seen
    echo "started closetabs"
    closetabs
    echo "started closetabs_focus"
    closetabs_focus
  fi
  echo "started focus_attr"
  focus_attr
  echo "started focus"
  focus
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
      browsers+=("$b2")
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
