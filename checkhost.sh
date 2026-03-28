#!/bin/bash
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
  echo "$missing" | sudo tee -a /etc/hosts > /dev/null
  echo "Done."
fi
