#!/usr/bin/env bash
#
# This script will generate a random grub_password and set it as the password for the advanced section in bash
set -e
# Yes, i could just generate a static password to put into grub-mkpasswd-pbkdf2 and then put the output into grub-mkpasswd-pbkdf2 but then it is really hard to jail break if this script fails
# random_32_character_string from https://gist.github.com/earthgecko/3089509
# rand32charstr=$(cat /dev/urandom \
#   | tr -dc 'a-zA-Z0-9' \ | fold -w 32 \
#   | head -n 1)
# grub_password=$(printf '%s\n%s\n' "$rand32charstr" "$rand32charstr" \
#   | grub-mkpasswd-pbkdf2 \
#   | sed --quiet '3p')
manual_password="wompwomp"
grub_password=$(printf '%s\n%s\n' "$manual_password" "$manual_password" \
  | /usr/bin/grub-mkpasswd-pbkdf2 \
  | /usr/bin/sed --quiet '3p')
current_date=$(date)
proper_format_grub_password="${grub_password/PBKDF2 hash of your password is /}"
set +e
set -eu
if [[ -r GRUB_PASSWORD-KEEP_SAFE.txt ]]; then
  echo "Removing existing password"
  /usr/bin/rm GRUB_PASSWORD-KEEP_SAFE.txt
  /usr/bin/sed -i.bak -e '/linuxconfig/d' -e '/grub.pbkdf2.sha512/d' /etc/grub.d/40_custom
fi

echo "Storing GRUB password..."
{ 
  echo "KEEP THE FOLLOWING PASSWORD SAFE. You will need the following password to enter into GRUB: "
  echo ${manual_password}
  echo "Last updated ${current_date}"
} >> GRUB_PASSWORD-KEEP_SAFE.txt 

{ 
  echo "set superusers=\"linuxconfig\""
  echo "password_pbkdf2 linuxconfig ${proper_format_grub_password}"
} | sudo tee -a /etc/grub.d/40_custom > /dev/null
 set +eu
# Same as running sudo update-grub
set -e
/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg "$@"
# Same as running the commands in the hooks
echo "Unrestricting GRUB's linux boot entries..."
/usr/bin/sed -i -e 's/--class os/--class os --unrestricted/g' /etc/grub.d/10_linux
echo "Restricting GRUB's submenus..."
/usr/bin/sed -i "s/menuentry_id_option 'gnulinux-advanced/submenu_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux
# setting up hooks to make this persistent
/usr/bin/sudo pacman -S --needed git
cd ~
echo "fetching hooks..."
/usr/bin/git clone https://github.com/MrSavageBanana/CTCT.git
/usr/bin/mv CTCT/grub1.hook CTCT/grub2.hook /etc/pacman.d/hooks
/usr/bin/rm --dir ~/CTCT
