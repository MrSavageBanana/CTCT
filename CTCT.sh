#!/bin/bash
# shellcheck disable=SC2317
# shellcheck disable=SC2329
# contemplating whether to create different script files and source them. This script is getting messy.
# Checks starts
# I am contemplating whether to add a check for existing files that might be on the user's computer and to check for them and tell the user to deal with them or if they want them to be overwritten and what would be overwritten. So far in the script, these are the files and directories that will be overwritten if they already exist

exit # in case this is accidentally ran. I don't want to ruin my computer. Remove this when needed and the shellcheck lines above
if [ ! $# -eq 0 ]; then
  echo "Remove arguments before running please"
fi

exec 9>/tmp/myscript.lock
flock -n 9 || {
  echo "Already running" >&2
  exit 1
}

if [ "$EUID" -eq 0 ]; then
  echo "Don't run as root. You will be prompted for sudo privileges."
  exit
fi
declare -a missing_dependencies=()
declare -a overwritten_files=()
declare -a applied_vivaldi_mods=()
declare -a potentially_overwritten_files=()
declare -a binaries_to_allow=()
declare -a important_files=()
declare -a affected_dirs=()
declare -a service_setup=()
declare -a reverse_service_setup=()
declare -a hooks_setup=()
declare -a reverse_hooks_setup=()
# TODO: Attempt to fix the missing dependencies. DEPENDS ON: Auto Detect the system's package manager and use it instead of just pacman. At least Debian and Fedora
check_dependencies() {
  local deps=("flock" "grub-mkpasswd-pbkdf2" "sed" "date" "rm" "mv" "sudo" "mkdir" "cp" "tee" "grub-mkconfig" "cat" "awk" "dialog" "git" "grep" "curl" "chpasswd" "chattr" "systemctl" "grep" "tar" "diff" "find" "md5sum" "sort" "bash" "tr" "fold" "head" "shred" "whoami" "pacman" "basename" "pgrep" "kill" "xargs" "uniq" "file" "strace")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing_dependencies+=("$dep")
    fi
  done
  if [[ "${#missing_dependencies[@]}" -eq 0 ]]; then
    echo "No Dependencies Missing"
  elif [[ "${#missing_dependencies[@]}" -ne 0 ]]; then
    echo "${#missing_dependencies[@]}" 'missing dependencies!:'
    for missing_dependency in "${missing_dependencies[@]}"; do
      echo "$missing_dependency"
    done
    exit
  else
    echo "missing_dependencies array is not working. Array:"
    "${missing_dependencies[@]}"
    exit
  fi

}
check_dependencies
# we are unable to warn the users about the JS files that may be overwritten unless we ping the github repo (which we will already do when we clone) to check what files might be overwritten
potentially_overwritten_files=("/etc/systemd/system/closetabs.service" "/etc/matt_damon.sh" "/etc/pacman.d/hooks.bin/vivaldimods.sh" "/etc/pacman.d/hooks/vivaldiupdate.hook" "/etc/pacman.d/hooks/grub1.hook" "/etc/pacman.d/hooks/grub2.hook" "$HOME/CTCT/vivaldimods_output.txt" "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/oldstate.txt" "$HOME/newstate.txt")
for file in "${potentially_overwritten_files[@]}"; do
  if [[ -e "$file" ]]; then
    overwritten_files+=("$file")
  fi
done
if [[ "${#overwritten_files[@]}" -eq 0 ]]; then
  echo "No files will be overwritten"
elif [[ "${#overwritten_files[@]}" -ne 0 ]]; then
  echo "${#overwritten_files[@]}" 'overwritten_files!:'
  for overwritten_file in "${overwritten_files[@]}"; do
    echo "$overwritten_file"
  done
  exit
else
  echo "overwritten_files array is not working. Array:"
  "${overwritten_files[@]}"
  exit
fi

if [[ -d $HOME/CTCT ]]; then
  echo "$HOME/CTCT directory already exists"
  exit
elif [[ ! -d $HOME/CTCT ]]; then
  echo "No directories will be overwritten"
fi

export LC_ALL=C
declare -a reverse_operation=()
perform_rollback() {
  echo -e "\n[!] ERROR DETECTED. INITIATING ROLLBACK..."

  # Get the total number of items in the stack
  total_items=${#reverse_operation[@]}

  # Loop backwards through the array
  for ((i = total_items - 1; i >= 0; i--)); do
    current_undo_command="${reverse_operation[$i]}"
    echo "Undoing: $current_undo_command"

    # Execute the command
    $current_undo_command
  done

  echo "Rollback complete. Checking for leftovers."
  echo "this may take up to one minute"
  grab_dir_state newstate.txt
  echo "Ready. Click enter to view diff"
  secs=90
  while [ "$secs" -ge 0 ]; do
    echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

    if read -t 1 -r _; then
      break
    fi

    ((secs--))
  done
  diff --side-by-side --color=always --suppress-common-lines "$HOME/oldstate.txt" "$HOME/newstate.txt"
  echo "Leftover Check Finished. Examine for any modified files"
  exit 1
}
trap 'perform_rollback' ERR
trap "" SIGINT SIGTSTP SIGQUIT # can't risk the user exiting the script and messing with things mid through
# Checks Ends
# Rollback Functions Start
undo_closetabs_creation() { sudo mv /etc/systemd/system/closetabs.service "$HOME/CTCT"; }
undo_closetabs_service_enable() { sudo systemctl disable --now closetabs; }
undo_move_matt_daemon() { sudo mv /etc/matt_damon "$HOME/CTCT"; }
undo_create_hooks_bin_dir() { sudo mv /etc/pacman.d/hooks.bin /; }
undo_move_vivaldi_sh() { sudo mv /etc/pacman.d/hooks.bin/vivaldimods.sh "$HOME/CTCT"; }
undo_create_hooks_dir() {
  sudo mv /etc/pacman.d/hooks "$HOME/.local/share/Trash/files"
}
undo_vivaldiupdate_hook() { sudo mv /etc/pacman.d/hooks/vivaldiupdate.hook "$HOME/CTCT"; }
undo_grub1_hook() { sudo mv /etc/pacman.d/hooks/grub1.hook "$HOME/CTCT"; }
undo_grub2_hook() { sudo mv /etc/pacman.d/hooks/grub2.hook "$HOME/CTCT"; }
undo_vivaldi_JS_SCRIPTS() {
  cd /opt/vivaldi/resources/vivaldi/
  sudo mv "${applied_vivaldi_mods[@]}" "$HOME/CTCT/Custom_Vivaldi_JS(AI)"
  cd -
}
undo_vivaldimods_sh() {
  for JS in "${applied_vivaldi_mods[@]}"; do
    sudo sed "/$JS/d" /opt/vivaldi/resources/vivaldi/window.html
  done
  for sites in "${new_host_entries[@]}"; do # this can only work if we decide to run the function because the array which has all the newly added websites won't exist
    sudo sed "/$sites/d" /etc/hosts
  done
}
remove_corrected_vivaldi_entry() { mv "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/CTCT"; }
reverse_immute() { sudo chattr -i "$1"; }
binary_to_remove() { sudo sed "/$user ALL=(root) NOPASSWD: /usr/bin/$1/d" /etc/sudoers.d/90-allowed-commands; } # this could fail if the username somehow had a regex special character
undo_create_trash_dir() { rm -rf "$HOME/.local/share/Trash/files"; }
undo_move_password_file() { mv "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME"; }
undo_backup_grub_custom() { sudo mv --force /etc/grub.d/40_custom.bak /etc/grub.d/40_custom; }
undo_sed_grub_custom() { sudo mv /etc/grub.d/40_custom.bak /etc/grub.d/40_custom; }
undo_create_password_file() { mv GRUB_PASSWORD-KEEP_SAFE.txt "$HOME/.local/share/Trash/files/"; }
undo_append_grub_custom() { sudo sed -i -e '/set superusers=\"linuxconfig\"/d' -e '/password_pbkdf2 linuxconfig/d' /etc/grub.d/40_custom; }
restore_backup_grub_cfg_bak() { sudo mv "/boot/grub/grub.cfg.bak.${backup_timestamp}" /boot/grub/grub.cfg; }
undo_unrestrict_grub() { sudo sed -i -e 's/--class os --unrestricted/--class os/g' /etc/grub.d/10_linux; }
undo_restrict_grub() { sudo sed -i "s/submenu_id_option 'gnulinux-advanced/menuentry_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux; }
# undo_create_grub1() { rm grub1.hook; }
# undo_create_grub2() { rm grub2.hook; }
undo_create_etc_dir() { sudo mv /etc "$HOME/.local/share/Trash/files/"; } # this only removes etc if you didn't have it before
undo_create_pacman_d_dir() { sudo mv /etc/pacman.d "$HOME/.local/share/Trash/files/"; }
#undo_move_hooks() {
#    sudo mv /etc/pacman.d/hooks/grub1.hook "$HOME"
#    sudo mv /etc/pacman.d/hooks/grub2.hook "$HOME"
#}
#binaries_to_allow=("curl" "jq" "adb" "bat" "blkid" "cat " "chmod" "docker-compose " "du" "flatpak" "fuser" "grep" "journalctl " "killall" "ln" "make" "micro" "mv" "nano " "nbfc" "pacman " "pkill" "rm" "rmpc" "sed" "sensors-detect " "sleep" "ss" "tailscale" "tlp " "tlp-stat" "touch" "ufw " "yay" "systemctl status" "systemctl start" "systemctl restart" "systemctl enable" "systemctl is-active" "systemctl list-units" "systemctl list-unit-files" "systemctl show" "systemctl status *" "systemctl start *" "systemctl restart *" "systemctl enable *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *")
# why the following weren't included
# make: Can create a simple makefile such as the following to run any command
# ```make
# hello:
# sudo echo "Hello, World"
# ```
# micro/nvim/: when a user opens a terminal in micro launched with sudo, they get access to a root terminal
# nano: a user can run ^R and then ^X to launch any command
# sed: a user can run the following command (the file can be any file. not just 10_linux )
# ```bash
# sudo sed -e '1e chattr -i /etc/grub.d/10_linux' /etc/hostname
# ```
# yay: user can create their own dummy package with commands such as `sudo chattr -i ` and submit to AUR and can run those commands
# pacman: user can download their own script using pacman -U to install a local package, also allowing a way to run commands
# systemctl start/restart/enable: user can create their own service, with their own Exec line to run any command using systemctl enable and start the service using systemctl start. systemctl restart does the same thing to a newly created service as systemctl enable and systemctl start so we have to stop it for the same reason. We can also block the `mv` command  instead stopping the user from ever creating their own services but the mv command is used more than the systemctl commands
binaries_to_allow=("curl" "jq" "adb" "bat" "blkid" "cat" "chmod" "docker-compose" "du" "flatpak" "fuser" "grep" "journalctl" "killall" "ln" "mv" "nbfc" "pkill" "rm" "rmpc" "sensors-detect" "sleep" "ss" "tailscale" "tlp" "tlp-stat" "touch" "ufw" "systemctl status" "systemctl is-active" "systemctl list-units" "systemctl list-unit-files" "systemctl show" "systemctl status *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *")
undo_create_root() { echo "It is not safe for this script to undo the root password creation automatically. Check file for the root password to manually change."; }
undo_create_local_bin_dir() { echo "This folder needs to be here. Not going to undo it"; }
undo_include_sudoers_d_dir() { sudo mv /etc/sudoers.d/ "$HOME/.local/share/Trash/files/"; }
undo_install_go() { rm -rf /usr/local/go; }
undo_curl_go() { rm "$HOME/CTCT/go"; }
undo_install_tle() { rm "$HOME/go/bin/tle"; }
undo_tle_lock() { mv "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/.local/share/Trash/files/"; }
# Rollback Functions End
# References Begin
user=$(whoami)
apply_vivaldi_mods() {
  cd "$HOME/CTCT"
  sudo bash /etc/pacman.d/hooks.bin/vivaldimods.sh | sudo tee vivaldimods_output.txt
  sed -i -e "/mods are already indented/d" -e "/Nothing missing/d" -e "/Inserted <script src/d" -e "/Adding missing entries:/d" -e "/Done./d" vivaldimods_output.txt
  sudo awk '{print $2}' vivaldimods_output.txt | sudo tee tmpfile.txt >/dev/null && sudo mv -f tmpfile.txt vivaldimods_output.txt
  readarray <vivaldimods_output.txt new_host_entries
  mv vivaldimods_output.txt "$HOME/.local/share/Trash/files/"
}

correct_flag_helper() { # 189
  if [[ -e "$HOME/.local/share/applications/vivaldi-stable.desktop" ]]; then
    mv "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/.local/share/Trash/files/"
    cp -f vivaldi-stable.desktop "$HOME/.local/share/applications"
  fi
  if [[ ! -d $HOME/.local/bin/ ]]; then
    if mkdir -p "$HOME/.local/bin/"; then
      reverse_operation+=("undo_create_local_bin_dir")
    else
      perform_rollback
    fi
  fi
  mv --force vivaldi-custom "$HOME/.local/bin"
}
exit_cleanly() {
  echo $?
  exit
}
important_files=('/etc/hosts' '/etc/pacman.d/hooks/vivaldiupdate.hook' '/etc/pacman.d/hooks/grub1.hook' '/etc/pacman.d/hooks/grub2.hook' '/etc/pacman.d/hooks.bin/vivaldimods.sh' '/etc/systemd/system/closetabs.service' '/etc/matt_damon.sh' '/etc/sudoers' '/etc/sudoers.d' "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock")
backup_timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
readonly backup_timestamp
readonly manual_password="wompwomp"                                                      # manual_password is for debugging/developing only
readonly rand32charstr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) # change it from 32 to another amount of characters if you want to easily be able to jailbreak it.
# TODO: replace the "tr" command with an "awk" command instead.
readonly chosen_password="$manual_password"
grub_password=$(printf '%s\n%s\n' "$chosen_password" "$chosen_password" |
  grub-mkpasswd-pbkdf2 |
  sed --quiet '3p')
readonly grub_password
current_date=$(date)
readonly current_date
proper_format_grub_password="${grub_password/PBKDF2 hash of your password is /}"
readonly proper_format_grub_password
affected_dirs=(
  "/tmp"
  "/etc/systemd/system/"
  "/etc"
  "/etc/pacman.d/hooks/"
  "/etc/pacman.d/hooks.bin/"
  "$HOME/.local/share/applications/"
  "$HOME"
  "/opt/vivaldi/resources/vivaldi/"
  "/etc/sudoers.d/"
  "$HOME/.local/share/Trash/files/"
  "/etc/grub.d/"
  "/boot/grub/"
  "/usr/local"
)
grab_dir_state() {
  local state_name="$1"
  for d in "${affected_dirs[@]}"; do
    if [[ -e $d ]]; then
      echo "$d"
      sudo find "$d" -maxdepth 1 -type f -exec md5sum {} + | sort >>"$HOME/$state_name"
    fi
  done
  echo "Finished capturing filesystem state"
}
set +eEuo pipefail # turns off pipefail now that the script didn't fail to create the variables
# References End
set -eEu
# Start of script
# I am contemplating simplifying the script by turning the \
# for commands in "${commands[@]}"
# if <command>; then
# reverse_operation+=("<reverse_command>")
# else
#	perform_rollback
# fi
# But that is not a priority. Priority is making sure that this script works with it's 500 lines then reducing it using this method.

echo "Grabbing current filesystem state"
grab_dir_state oldstate.txt
# this directory is referenced so much that i decided to just check for it's existency almost immediately
if [[ ! -d $HOME/.local/share/Trash/files ]]; then
  if mkdir -p "$HOME/.local/share/Trash/files"; then
    reverse_operation+=("undo_create_trash_dir")
  else
    perform_rollback
  fi
fi
# Get repo
cd "$HOME"
git clone https://github.com/MrSavageBanana/CTCT.git 1>/dev/null || exit
cd CTCT || exit

# Service
closetabs_creation() { sudo cp -f closetabs.service /etc/systemd/system; }
move_matt_daemon() { sudo mv --force matt_damon.sh /etc/; }
closetabs_service_enable() { sudo systemctl enable --now closetabs; }
service_setup=("closetabs_creation" "move_matt_daemon" "closetabs_service_enable")
reverse_service_setup=("undo_closetabs_creation" "undo_move_matt_daemon" "undo_closetabs_service_enable")
for n in {0..2}; do
  if "${service_setup[$n]}"; then
    reverse_operation+=("${reverse_service_setup[$n]}")
  else
    perform_rollback
  fi
done
# Hooks
if [[ ! -d /etc/pacman.d/hooks.bin ]]; then
  if sudo mkdir -p /etc/pacman.d/hooks.bin; then
    reverse_operation+=("undo_create_hooks_bin_dir")
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

move_vivaldi_sh() { sudo mv --force vivaldimods.sh /etc/pacman.d/hooks.bin; }
vivaldiupdate_hook() { sudo mv --force vivaldiupdate.hook /etc/pacman.d/hooks; }
grub1_hook() { sudo mv --force grub1.hook /etc/pacman.d/hooks; }
grub2_hook() { sudo mv --force grub2.hook /etc/pacman.d/hooks; }
hooks_setup=("move_vivaldi_sh" "vivaldiupdate_hook" "grub1_hook" "grub2_hook")
reverse_hooks_setup=("undo_move_vivaldi_sh" "undo_vivaldiupdate_hook" "undo_grub1_hook" "undo_grub2_hook")
for n in {0..2}; do
  if "${hooks_setup[$n]}"; then
    reverse_operation+=("${reverse_hooks_setup[$n]}")
  fi
done
# Javascript
sudo pacman -S --needed --noconfirm vivaldi
cd "Custom_Vivaldi_JS(AI)" || exit
# This array needs to be upgraded by making all files in Custom_Vivaldi_JS be in it, regardless of name
# If i decide to have the bundles of JS scripts as little packs, i will need to
# 1. add the option to choose which pack and
# 2. if the user has their own custom, they should be required to put the path to the directory
# 3. if they don't have their directory yet, they can run the script with the arguments to the directory to add it in.
#if sudo mv --force "${JS_SCRIPTS[@]}" /opt/vivaldi/resources/vivaldi; then
for f in *js; do
  if sudo mv --force "$f" /opt/vivaldi/resources/vivaldi; then
    reverse_operation+=("undo_vivaldi_JS_SCRIPTS")
    applied_vivaldi_mods+=("$f")
  else
    perform_rollback
  fi
done
cd "$HOME/CTCT"

echo "Applying JS and hosts"
if apply_vivaldi_mods; then
  reverse_operation+=("undo_vivaldimods_sh")
else
  perform_rollback
fi

if correct_flag_helper; then
  reverse_operation+=("remove_corrected_vivaldi_entry")
else
  perform_rollback
fi

# since the vivaldimods.sh was just run, the user likely has an internet connection at this point and it is safer to install go and tle right now
if [[ ! -e /usr/local/go ]]; then
  echo "Downloading go zip"
  curl -s https://dl.google.com/go/go1.26.5.linux-amd64.tar.gz --output "$HOME/CTCT/go.tar.gz"
  reverse_operation+=("undo_curl_go")
  sudo tar -C /usr/local/ -xzf go.tar.gz
  reverse_operation+=("undo_install_go")
else
  perform_rollback
fi
if [[ -e /usr/local/go ]]; then
  /usr/local/go/bin/go install github.com/drand/tlock/cmd/tle@latest
  reverse_operation+=("undo_install_tle")
else
  echo "go wasn't installed"
  perform_rollback
  exit
fi
if ! up_to_date_info=$(curl -sf https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/info); then
  drand_failed=true
fi

# Edit /etc/sudoers
# I will likely allow the users to change what is given the sudo privileges but the script will check for what is absolutely not allowed to be given sudo privileges for this stuff to work. This is maybe a feature for another time.

for binaries in "${binaries_to_allow[@]}"; do
  if ! grep -qF "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" /etc/sudoers.d/90-allowed-commands; then
    echo "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" | sudo tee --append /etc/sudoers.d/90-allowed-commands || exit_cleanly
    reverse_operation+=("binary_to_remove $binaries")
  elif grep -qF "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" /etc/sudoers.d/90-allowed-commands; then
    echo "$binaries" already exists
  else
    perform_rollback
  fi
done

if ! grep -qF "@includedir /etc/sudoers.d" /etc/sudoers; then
  echo "@includedir /etc/sudoers.d" | sudo tee --append /etc/sudoers || exit_cleanly
  reverse_operation+=("undo_include_sudoers_d_dir")
elif grep -qF "@includedir /etc/sudoers.d" /etc/sudoers; then
  echo "includedir line exists"
else
  perform_rollback
fi

#TODO: Remove Root privileges from the current user. - need to find out what groups the user is part of which has sudo

# GRUB.sh Starts

cd "$HOME"
# Removing GRUB_PASSWORD-KEEP_SAFE.txt and create a backup of /etc/grub.d/40_custom

if [[ -r GRUB_PASSWORD-KEEP_SAFE.txt ]]; then # this could be problematic if the user doesn't name their unlocked file GRUB_PASSWORD-KEEP_SAFE.txt
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
  echo "KEEP THE FOLLOWING PASSWORD SAFE. You will need the following password to enter into GRUB and system: "
  echo "${chosen_password}"
  echo "Last updated ${current_date}"
} >>GRUB_PASSWORD-KEEP_SAFE.txt; then # for a period of time until this file is shred, someone could theoretically see what is inside it. Not sure how to stop this.
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
} | sudo tee -a /etc/grub.d/40_custom >/dev/null; then
  reverse_operation+=("undo_append_grub_custom")
else
  perform_rollback
fi
set +eEuo pipefail

# Same as running the commands in the hooks
echo "Unrestricting GRUB's linux boot entries..."

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

# Same as running sudo update-grub
set -e
sudo cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak.${backup_timestamp}"

if sudo grub-mkconfig -o /boot/grub/grub.cfg "$@"; then
  reverse_operation+=("restore_backup_grub_cfg_bak")
else
  perform_rollback
fi

# I don't know if this check is needed?
# setting up hooks to make this persistent
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

# end of grub setup
echo "select a date to stop focussing"
echo "Click enter to continue"
secs=10
while [ "$secs" -ge 0 ]; do
  echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

  if read -t 1 -r _; then
    break
  fi

  ((secs--))
done

selected_end_date=$(dialog --clear --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Ending Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
echo "select a time to end the script"
selected_end_time=$(dialog --clear --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
ending="$selected_end_date $selected_end_time"
ending_epoch=$(date -d "$ending" +%s)
if [[ $drand_failed == "true" ]]; then
  # these are the likely defaults.
  genesis="1692803367"
  period="3"
  hash="52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971"
elif [[ $drand_failed != "true" ]]; then
  genesis=$(echo "$up_to_date_info" | awk -F '[\":,]' '{print $14}')
  period=$(echo "$up_to_date_info" | awk -F '[\":,]' '{print $10}')
  hash=$(echo "$up_to_date_info" | awk -F '[\":,]' '{print $19}')
fi
round=$((((ending_epoch - genesis) / period) + 1))

if [[ -e "$HOME/go/bin/tle" ]]; then
  "$HOME/go/bin/tle" -e -c "$hash" -r "$round" -o "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt"
  if [[ ! -s "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" ]]; then
    echo round "$round" is in the past. Try again
    echo "Click enter to continue"
    secs=10
    while [ "$secs" -ge 0 ]; do
      echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

      if read -t 1 -r _; then
        break
      fi

      ((secs--))
    done
    selected_end_date
  else
    echo "COMPLETE"
    reverse_operation+=("undo_tle_lock")
    shred "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt" # shred will overwrite the file and ensure that any file recovery fails. A person could run SystemRescue and recover the file easily if the file wasn't overwritten
  fi
else
  echo "tle wasn't installed"
  perform_rollback
fi

# Immutable File; last step
for important_file in "${important_files[@]}"; do
  if sudo chattr +i "$important_file"; then
    reverse_operation+=("reverse_immute $important_file")
  else
    perform_rollback
  fi
done

for JS_SCRIPT in "${applied_vivaldi_mods[@]}"; do
  if sudo chattr +i /opt/vivaldi/resources/vivaldi/"$JS_SCRIPT"; then
    reverse_operation+=("reverse_immute /opt/vivaldi/resources/vivaldi/$JS_SCRIPT")
  else
    perform_rollback
  fi
done
sudo chattr +a /etc/browsers.txt

# last use of sudo so it has to go last
if echo "root:$chosen_password" | sudo chpasswd; then
  reverse_operation+=("undo_create_root")
else
  perform_rollback
fi

mv "$HOME/CTCT" "$HOME/.local/share/Trash/files/CTCT_${backup_timestamp}"
