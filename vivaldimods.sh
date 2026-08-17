#!/bin/bash
read_desktop_files() {
  grep -Rl "Categories=.*WebBrowser" /usr/share/applications \
    ~/.local/share/applications 2>/dev/null | xargs awk -F'[= ]' \
    '/^Exec=/{print $2}' /usr/share/applications/vivaldi-stable.desktop | uniq
}

load_browsers() {
  mapfile -t browsers < <(read_desktop_files)
  for b in "${browsers[@]}"; do
    b2=$(command -v "$b")
    b3=$(file --mime-type -b "$b2" | awk '{split($NF, a, "/"); print a[1]}')
    if [[ $b3 = 'text' ]]; then
      b4=$(strace -e trace=execve "$b2" --version |& awk -F'"' '/^execve/ && /0$/ { n = split($2, arr, "/"); result = arr[n] } END { if (result) print result }')
      browsers+=("$b4")
    fi
  done
  for bro in "${browsers[@]}"; do
    if ! grep "$bro" /etc/browsers.txt &>/dev/null; then
      echo "$bro" | sudo tee --append /etc/browsers.txt >/dev/null
      missing_browser_entries+=("$bro")
    fi
  done
  if [ "${#missing_browser_entries[@]}" -eq 0 ]; then
    echo "Nothing missing. /etc/browsers.txt is up to date."
  fi
}
load_browsers
enable_closetabs() {
  if [[ ! -e /etc/systemd/system/CTCT.target.wants/closetabs.service ]]; then
    systemctl enable --now closetabs &>/dev/null
  fi
}
enable_closetabs
# --- VARIABLES ---
FILE="/opt/vivaldi/resources/vivaldi/window.html"
ANCHOR="<body>"
INSERTS=(

)
INSERT_END=("${INSERTS[@]/%/\"></script>}")
INSERT_BEGIN=("${INSERT_END[@]/#/<script src=\"}")
# DEBUG MESSAGES
# echo "${INSERT_BEGIN[@]}"
# echo 'EXECUTION COMMENCE!'
# --- EXECUTION BLOCKS ---
for item in "${INSERT_BEGIN[@]}"; do
  if grep -qF "$item" "$FILE"; then
    DUPLICATE_MODS+=("$item")
  else
    sed -i "s|$ANCHOR|&\n\t$item|" "$FILE"
    echo "Inserted $item with indentation."
  fi
done

echo "${#DUPLICATE_MODS[@]}" 'mods are already indented.'
# Check that /etc/hosts isn't missing anything from the mirror, and add what's missing
extra_mirrors=(
)
cleanup() {
  curl -fSs --connect-timeout 20 --max-time 30 "$1" |
    sed 's/#.*//' |
    sed 's/[[:space:]]*$//' |
    sed '/^[[:space:]]*$/d' |
    sort
}
mirror=$(curl -fSs --connect-timeout 20 --max-time 30 https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts |
  sed 's/#.*//' |
  sed 's/[[:space:]]*$//' |
  sed '/^[[:space:]]*$/d' |
  sort)

current=$(awk '/0.0.0.0/ { count++ } count >= 2' /etc/hosts |
  sed 's/#.*//' |
  sed 's/[[:space:]]*$//' |
  sed '/^[[:space:]]*$/d' |
  sort)

custom_websites=(
)
for custom_websites_to_block in "${custom_websites[@]}"; do
  if ! grep -qF "$custom_websites_to_block" /etc/hosts; then
    mirror="$mirror"$'\n'"$custom_websites_to_block" # gemini told me this is how to make each result on a new line
  fi
done
for extra_mirror in "${extra_mirrors[@]}"; do
  extra_mirror=$(cleanup "$extra_mirror")
  if ! grep -qF "$extra_mirror" /etc/hosts; then
    mirror="$mirror"$'\n'"$extra_mirror"
  fi
done
# Lines marked with < are in mirror but not in current
missing=$(diff <(echo "$mirror") <(echo "$current") | grep '^<' | sed 's/^< //')
if [ -z "$missing" ]; then
  echo "Nothing missing. /etc/hosts is up to date."
else
  # Claude gave me this idea for implementing my  countdown
  count=0
  while IFS= read -r; do
    echo -ne "Added $count entries\r"
    ((count++))
  done <<<"$missing"

  echo
  chattr -a /etc/hosts
  echo "$missing" | sudo tee -a /etc/hosts >/dev/null
  chattr +a /etc/hosts
  echo "Done."
fi
