#!/bin/bash

# --- VARIABLES ---
FILE="/opt/vivaldi/resources/vivaldi/window.html"
ANCHOR="<body>"

INSERT1='<script src="video.js"></script>'
INSERT2='<script src="shorts.js"></script>'
INSERT3='<script src="youtube.js"></script>'
INSERT4='<script src="search.js"></script>'
INSERT5='<script src="posts.js"></script>'
INSERT6='<script src="reddit_hp.js"></script>'
INSERT7='<script src="reddit.js"></script>'
INSERT8='<script src="startpage-wallpaper.js"></script>'
INSERT9='<script src="bridge.js"></script>'
INSERT10='<script src="autosave.js"></script>'
INSERT11='<script src="loading.js"></script>'
INSERT12='<script src="custom.js"></script>'
INSERT13='<script src="dialogTab.js"></script>'
# --- EXECUTION BLOCKS ---

# INSERT1
if grep -qF "$INSERT1" "$FILE"; then
    echo "$INSERT1 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT1|" "$FILE"
    echo "Inserted $INSERT1 with indentation."
fi

# INSERT2
if grep -qF "$INSERT2" "$FILE"; then
    echo "$INSERT2 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT2|" "$FILE"
    echo "Inserted $INSERT2 with indentation."
fi

# INSERT3 
if grep -qF "$INSERT3" "$FILE"; then
    echo "$INSERT3 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT3|" "$FILE"
    echo "Inserted $INSERT3 with indentation."
fi

# INSERT4
if grep -qF "$INSERT4" "$FILE"; then
    echo "$INSERT4 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT4|" "$FILE"
    echo "Inserted $INSERT4 with indentation."
fi

# INSERT5
if grep -qF "$INSERT5" "$FILE"; then
    echo "$INSERT5 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT5|" "$FILE"
    echo "Inserted $INSERT5 with indentation."
fi

# INSERT6
if grep -qF "$INSERT6" "$FILE"; then
    echo "$INSERT6 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT6|" "$FILE"
    echo "Inserted $INSERT6 with indentation."
fi

# INSERT7
if grep -qF "$INSERT7" "$FILE"; then
    echo "$INSERT7 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT7|" "$FILE"
    echo "Inserted $INSERT7 with indentation."
fi

# INSERT8
if grep -qF "$INSERT8" "$FILE"; then
    echo "$INSERT8 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT8|" "$FILE"
    echo "Inserted $INSERT8 with indentation."
fi

# INSERT9
if grep -qF "$INSERT9" "$FILE"; then
    echo "$INSERT9 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT9|" "$FILE"
    echo "Inserted $INSERT9 with indentation."
fi

# INSERT10
if grep -qF "$INSERT10" "$FILE"; then
    echo "$INSERT10 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT10|" "$FILE"
    echo "Inserted $INSERT10 with indentation."
fi

# INSERT11
if grep -qF "$INSERT11" "$FILE"; then
    echo "$INSERT11 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT11|" "$FILE"
    echo "Inserted $INSERT11 with indentation."
fi

# INSERT12
if grep -qF "$INSERT12" "$FILE"; then
    echo "$INSERT12 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT12|" "$FILE"
    echo "Inserted $INSERT12 with indentation."
fi
# INSERT13
if grep -qF "$INSERT13" "$FILE"; then
    echo "$INSERT13 already exists. Skipping."
else
    sed -i "s|$ANCHOR|&\n\t$INSERT13|" "$FILE"
    echo "Inserted $INSERT13 with indentation."
fi

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
  chattr -i
  echo "$missing" | sudo tee -a /etc/hosts > /dev/null
  chattr +ia
  echo "Done."
fi

