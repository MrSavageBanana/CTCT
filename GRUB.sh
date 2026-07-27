#!/bin/bash
#!/usr/bin/env bash
#
# This script will generate a random grub_password and set it as the password for the advanced section in bash
# Yes, i could just generate a static password to put into grub-mkpasswd-pbkdf2 and then put the output into grub-mkpasswd-pbkdf2 but then it is really hard to jail break if this script fails
# random_32_character_string from https://gist.github.com/earthgecko/3089509
# rand32charstr=$(cat /dev/urandom \
#   | tr -dc 'a-zA-Z0-9' \ | fold -w 32 \
#   | head -n 1)
# grub_password=$(printf '%s\n%s\n' "$rand32charstr" "$rand32charstr" \
#   | grub-mkpasswd-pbkdf2 \
#
#   | sed --quiet '3p')

exec 9>/tmp/myscript.lock
flock -n 9 || { echo "Already running" >&2; exit 1; }

if [ "$EUID" -eq 0 ]
  then echo "Don't run as root. You will be prompted for sudo privileges."
  exit
fi
sudo -vk

check_dependencies() {
    local deps=("flock" "grub-mkpasswd-pbkdf2" "sed" "date" "rm" "mv" "sudo" "mkdir" "cp" "tee" "grub-mkconfig" "cat" )
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
		missing_dependencies+=("$dep")
        fi
    done
    if [[ "${#missing_dependencies[@]}" -eq 0 ]] ; then
	    echo "No Dependencies Missing"
    elif [[ "${#missing_dependencies[@]}" -ne 0 ]]; then
	    echo "${#missing_dependencies[@]}" 'missing dependencies!:'
		    for missing_dependency in "${missing_dependencies[@]}"; do
			    echo "$missing_dependency" 
		    done
		    exit
	    else 
		    echo "missing_dependencies array is not working. Array:"
		    "${missing_dependencies[@]}"; exit
    fi

}
check_dependencies

export LC_ALL=C
declare -a reverse_operation=()


perform_rollback() {
    echo -e "\n[!] ERROR DETECTED. INITIATING ROLLBACK..."
    
    # Get the total number of items in the stack
    total_items=${#reverse_operation[@]}
    
    # Loop backwards through the array
    for (( i=$total_items-1; i>=0; i-- )); do
        current_undo_command="${reverse_operation[$i]}"
        echo "Undoing: $current_undo_command"
        
        # Execute the command
        $current_undo_command
    done
    
    echo "Rollback complete. Exiting script."
    exit 1
}

set -eEuo pipefail
trap 'perform_rollback' ERR
trap "" SIGINT SIGTSTP SIGQUIT # can't risk the user exiting the script and messing with things mid through
# Declare Variables

backup_timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
readonly backup_timestamp
readonly manual_password="wompwomp"
grub_password=$(printf '%s\n%s\n' "$manual_password" "$manual_password" \
  | grub-mkpasswd-pbkdf2 \
  | sed --quiet '3p')
readonly grub_password
current_date=$(date)
readonly current_date
proper_format_grub_password="${grub_password/PBKDF2 hash of your password is /}"
readonly proper_format_grub_password
set +eEuo pipefail

# Rollback Functions
undo_create_trash_dir() {
    rm -rf "$HOME/.local/share/Trash/files"
}

undo_move_password_file() {
    mv "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME"
}

undo_backup_grub_custom() {
    sudo mv --force /etc/grub.d/40_custom.bak /etc/grub.d/40_custom
}

undo_sed_grub_custom() {
    sudo mv /etc/grub.d/40_custom.bak /etc/grub.d/40_custom
}

undo_create_password_file() {
    rm GRUB_PASSWORD-KEEP_SAFE.txt
}

undo_append_grub_custom() {
    sudo sed -i -e '/set superusers=\"linuxconfig\"/d' -e '/password_pbkdf2 linuxconfig/d' /etc/grub.d/40_custom
}

restore_backup_grub_cfg_bak() {
    sudo mv "/boot/grub/grub.cfg.bak.${backup_timestamp}" /boot/grub/grub.cfg
}

undo_unrestrict_grub() {
    sudo sed -i -e 's/--class os --unrestricted/--class os/g' /etc/grub.d/10_linux
}

undo_restrict_grub() {
    sudo sed -i "s/submenu_id_option 'gnulinux-advanced/menuentry_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux
}

undo_create_grub1() {
    rm grub1.hook
}

undo_create_grub2() {
    rm grub2.hook
}

undo_create_etc_dir() {
    rm -rf /etc
}

undo_create_pacman_d_dir() {
    rm -rf /etc/pacman.d
}

undo_create_hooks_dir() {
    rm -rf /etc/pacman.d/hooks
}

undo_move_hooks() {
    sudo mv /etc/pacman.d/hooks/grub1.hook "$HOME"
    sudo mv /etc/pacman.d/hooks/grub2.hook "$HOME"
}
binary_to_remove(){
	sed "/shayan ALL=(root) NOPASSWD: /usr/bin/$1/d" /etc/90-allowed-commands
}
binaries_to_block=( "curl" "jq" "adb" "bat" "blkid" "cat " "chmod" "docker-compose " "du" "flatpak" "fuser" "grep" "journalctl " "killall" "ln" "make" "micro mv" "nano " "nbfc" "nvim" "pacman " "pkill" "rm" "rmpc" "sed" "sensors-detect " "sleep" "ss" "systemctl" "tailscale" "tlp " "tlp-stat" "touch" "ufw " "yay" "systemctl status" "systemctl start" "systemctl restart" "systemctl enable" "systemctl is-active" "systemctl list-units" "systemctl list-unit-files" "systemctl show" "systemctl status *" "systemctl start *" "systemctl restart *" "systemctl enable *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *" )
undo_create_root(){
	echo "It is not safe for this script to undo the root password creation automatically. Check file for the root password to manually change."
}

set -eu
# Removing GRUB_PASSWORD-KEEP_SAFE.txt and create a backup of /etc/grub.d/40_custom
if [[ ! -d $HOME/.local/share/Trash/files ]]; then
	
	if mkdir -p $HOME/.local/share/Trash/files; then
		reverse_operation+=("undo_create_trash_dir")
	else
		perform_rollback
	fi
fi

if [[ -r GRUB_PASSWORD-KEEP_SAFE.txt ]]; then
  echo "Removing existing password"
  
	if mv "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME/.local/share/Trash/files"; then
		reverse_operation+=("undo_move_password_file")
	else
		perform_rollback
	fi
	if sudo cp /etc/grub.d/40_custom /etc/grub.d/40_custom.bak; then
		reverse_operation+=("undo_backup_grub_custom")
	else
		perform_rollback
	fi
  
	# Deletes lines with the username and password
	if sudo sed -i.bak -e '/linuxconfig/d' -e '/grub.pbkdf2.sha512/d' /etc/grub.d/40_custom; then 
		reverse_operation+=("undo_sed_grub_custom")
	else
		perform_rollback
	fi
fi

echo "Storing GRUB password..."

if {
    echo "KEEP THE FOLLOWING PASSWORD SAFE. You will need the following password to enter into GRUB: "
    echo "${manual_password}"
    # echo "${rand32charstr}"
    echo "Last updated ${current_date}"
} >> GRUB_PASSWORD-KEEP_SAFE.txt; then
	reverse_operation+=("undo_create_password_file")
else
	perform_rollback
fi

set -eEuo pipefail
echo "sudo is needed for appending to /etc/grub.d/40_custom"
# This deletes both the password_pbkdf2 and the superusers line at once
sudo sed -i '/linuxconfig/d' /etc/grub.d/40_custom 
if {
  echo "set superusers=\"linuxconfig\""
  echo "password_pbkdf2 linuxconfig ${proper_format_grub_password}"
} | sudo tee -a /etc/grub.d/40_custom > /dev/null; then
	reverse_operation+=("undo_append_grub_custom")
else
	perform_rollback
fi
set +eEuo pipefail

# Same as running sudo update-grub
set -e
sudo cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak.${backup_timestamp}"

if sudo grub-mkconfig -o /boot/grub/grub.cfg "$@"; then
	reverse_operation+=("restore_backup_grub_cfg_bak")
else
	perform_rollback
fi

# Same as running the commands in the hooks
echo "Unrestricting GRUB's linux boot entries..."

# sudo sed -i -e 's/--class os --unrestricted/--class os/g' -e 's/--class os/--class os --unrestricted/g' /etc/grub.d/10_linux; then # removes it if it exists then adds it back again.
if sudo sed -i 's/--class os\b\( --unrestricted\)*/--class os --unrestricted/g' /etc/grub.d/10_linux; then 
    reverse_operation+=("undo_unrestrict_grub")
else
	perform_rollback
fi

echo "Re-restricting GRUB's submenus..."

if sudo sed -i "s/menuentry_id_option 'gnulinux-advanced/submenu_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux; then
	reverse_operation+=("undo_restrict_grub")
else
	perform_rollback
fi

# setting up hooks to make this persistent
echo "creating hooks..."
if cat << 'EOF' > "$HOME/grub1.hook"
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = grub

[Action]
Description = Unrestricting GRUB's linux boot entries...
Depends = sed
When = PostTransaction
Exec = /usr/bin/sed -i -e 's/--class os/--class os --unrestricted/g' /etc/grub.d/10_linux

EOF
then
	reverse_operation+=("undo_create_grub1")
else
	perform_rollback
fi

# Create grub2.hook
if cat << 'EOF' > "$HOME/grub2.hook"
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = grub
[Action]
Description = Re-restricting GRUB's submenus...
Depends = sed
When = PostTransaction
Exec = /usr/bin/sed -i "s/menuentry_id_option 'gnulinux-advanced/submenu_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux

EOF
then
	reverse_operation+=("undo_create_grub2")
else
	perform_rollback
fi

if [[ ! -d /etc/ ]]; then
  if sudo mkdir -p /etc; then
	echo "this machine is cooked? You don't have etc?"
  	reverse_operation+=("undo_create_etc_dir")
  else
  	perform_rollback
  fi
fi
if [[ ! -d /etc/pacman.d/ ]]; then
  if sudo mkdir -p /etc/pacman.d; then
  	reverse_operation+=("undo_create_pacman_d_dir")
  else
  	perform_rollback
  fi
fi
if [[ ! -d /etc/pacman.d/hooks ]]; then
  if sudo mkdir -p /etc/pacman.d/hooks; then
  	reverse_operation+=("undo_create_hooks_dir")
  else
  	perform_rollback
  fi
fi

if sudo mv "$HOME/grub1.hook" "$HOME/grub2.hook" /etc/pacman.d/hooks; then
	reverse_operation+=("undo_move_hooks")
else
	perform_rollback
fi
 # end of grub setup
exit_cleanly(){
	echo $?; exit
}
for binaries in "${binaries_to_block[@]}"; do
	if ! grep -qF "shayan ALL=(root) NOPASSWD: /usr/bin/$binaries" /etc/90-allowed-commands; then
		echo "shayan ALL=(root) NOPASSWD: /usr/bin/$binaries" | sudo tee --append /etc/90-allowed-commands || exit_cleanly
		reverse_operation+=("binary_to_remove $binaries")
	else
		perform_rollback
	fi
done


if echo "root:$manual_password" | sudo chpasswd; then
	reverse+=("undo_create_root") 
else
	perform_rollback
fi

