#!/bin/bash

# --- VARIABLES ---
FILE="/opt/vivaldi/resources/vivaldi/window.html"
ANCHOR="<body>"

INSERTS=('video.js' 'shorts.js' 'youtube.js' 'reddit_hp.js' 'reddit.js' 'startpage-wallpaper.js' 'bridge.js' 'autosave.js' 'loading.js' 'custom.js' 'dialogTab.js' 'tree.js' 'monochrome-icons.js' 'todoistDialog.js' 'youtubeNU.js' 'autocomplete-domain.js' 'toast.js' 'yandex.js' 'HibernatePanels.js' 'Markdown.js' 'Media.js')
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
mirror=$(curl -s https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts \
  | sed 's/#.*//' \
  | sed 's/[[:space:]]*$//' \
  | sed '/^[[:space:]]*$/d' \
  | sort)

current=$(awk '/0.0.0.0/ { count++ } count >= 2' /etc/hosts \
  | sed 's/#.*//' \
  | sed 's/[[:space:]]*$//' \
  | sed '/^[[:space:]]*$/d' \
  | sort)

# Lines marked with < are in mirror but not in current
missing=$(diff <(echo "$mirror") <(echo "$current") | grep '^<' | sed 's/^< //')

if [ -z "$missing" ]; then
  echo "Nothing missing. /etc/hosts is up to date."
else
  echo "Adding missing entries:"
  echo "$missing"
  chattr -i /etc/hosts
  echo "$missing" | sudo tee -a /etc/hosts > /dev/null
  chattr +ia /etc/hosts
  echo "Done."
fi
