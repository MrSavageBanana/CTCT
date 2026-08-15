#!/bin/bash
# shellcheck disable=SC2034
# For disabling the messages when the exit message is there:
# shellcheck disable=SC2317
# shellcheck disable=SC2329
# contemplating whether to create different script files and source them. This script is getting messy.
# Checks starts
# I am contemplating whether to add a check for existing files that might be on the user's computer and to check for them and tell the user to deal with them or if they want them to be overwritten and what would be overwritten. So far in the script, these are the files and directories that will be overwritten if they already exist
exit         # in case this is accidentally ran. I don't want to ruin my computer. Remove this when needed and the shellcheck lines above
echo_red() { # for things that needs the users attention
  builtin echo -e "\033[38;2;255;0;0m >>> $* <<< \033[0m"
}
if [ ! $# -eq 0 ]; then
  echo_red "Remove arguments before running please"
fi

if [ "$EUID" -eq 0 ]; then
  echo_red "Don't run as root. You will be prompted for sudo privileges."
  exit
fi

exec 9>/tmp/myscript.lock
flock -n 9 || {
  echo_red "Already running" >&2
  exit 1
}
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
user=$(whoami)
# TODO: Attempt to fix the missing dependencies. DEPENDS ON: Auto Detect the system's package manager and use it instead of just pacman. At least Debian and Fedora
check_dependencies() {
  local deps=("flock" "grub-mkpasswd-pbkdf2" "sed" "date" "rm" "mv" "sudo" "mkdir" "cp" "tee" "grub-mkconfig" "cat" "awk" "dialog" "git" "grep" "curl" "chpasswd" "chattr" "systemctl" "grep" "tar" "diff" "find" "md5sum" "sort" "bash" "tr" "fold" "head" "shred" "whoami" "basename" "pgrep" "kill" "xargs" "uniq" "file" "strace" "vivaldi")
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
      echo "$missing_dependency"
    done
    exit
  else
    echo_red "missing_dependencies array is not working. Array:"
    "${missing_dependencies[@]}"
    exit
  fi

}
check_dependencies
# we are unable to warn the users about the JS files that may be overwritten unless we ping the github repo (which we will already do when we clone) to check what files might be overwritten
potentially_overwritten_files=("/etc/systemd/system/closetabs.service" "/etc/systemd/system/CTCT.target.wants/closetabs.service" "/etc/matt_damon.sh" "/etc/browsers.txt" "/etc/pacman.d/hooks.bin/vivaldimods.sh" "/etc/pacman.d/hooks/vivaldiupdate.hook" "/etc/pacman.d/hooks/grub1.hook" "/etc/pacman.d/hooks/grub2.hook" "$HOME/CTCT/vivaldimods_output.txt" "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "/etc/sudoers.d/90-allowed-commands" "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME/.local/share/Trash/files/vivaldimods_output.txt" "$HOME/.local/share/Trash/files/vivaldi-stable.desktop" "$HOME/.local/share/Trash/files/CTCT_${backup_timestamp}" "$HOME/.local/share/Trash/files/tle")
for file in "${potentially_overwritten_files[@]}"; do
  if [[ -e "$file" ]]; then
    overwritten_files+=("$file")
  fi
done
if [[ "${#overwritten_files[@]}" -eq 0 ]]; then
  if command -v vivaldi >/dev/null; then # checks if vivaldi is installed. if it is, there may be some js files. if not, there is no reason to suspect
    echo "No files will be overwritten"
    echo_red "Also check for JS files"
    echo "Use this time to check for JS files. Press enter when checked"
    secs=90
    while [ "$secs" -ge 0 ]; do
      echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

      if read -t 1 -r _; then
        break
      fi

      ((secs--))
    done
  fi
elif [[ "${#overwritten_files[@]}" -ne 0 ]]; then
  echo_red "${#overwritten_files[@]}" 'overwritten files!:'
  for overwritten_file in "${overwritten_files[@]}"; do
    echo "$overwritten_file"
  done
  if command -v vivaldi >/dev/null; then # checks if vivaldi is installed. if it is, there may be some js files. if not, there is no reason to suspect
    echo_red "Also check for JS files"
  fi
  exit
else
  echo_red "overwritten_files array is not working. Array:"
  echo "${overwritten_files[@]}"
  exit
fi

potentially_overwritten_directories=("$HOME/CTCT/" "/etc/systemd/system/CTCT.target.wants" "$HOME/.local/share/Trash/files/hooks.bin" "$HOME/.local/share/Trash/files/hooks" "$HOME/.local/share/Trash/files/etc" "$HOME/.local/share/Trash/files/pacman.d" "$HOME/.local/share/Trash/files/sudoers.d" "$HOME/.local/share/Trash/files/go" "$HOME/.local/share/Trash/files/CTCT")
for dir in "${potentially_overwritten_directories[@]}"; do
  if [[ -e "$dir" ]]; then
    overwritten_dirs+=("$dir")
  fi
done
if [[ "${#overwritten_dirs[@]}" -eq 0 ]]; then
  true
elif [[ "${#overwritten_dirs[@]}" -ne 0 ]]; then
  echo_red "${#overwritten_dirs[@]}" 'overwritten dirs!:'
  for overwritten_dir in "${overwritten_dirs[@]}"; do
    echo "$overwritten_dir"
  done
  exit
else
  echo_red "overwritten_dirs array is not working. Array:"
  echo "${overwritten_dirs[@]}"
  exit
fi

grab_dir_state() {
  local state_name="$1"
  if [[ -e "$HOME/$state_name" ]]; then
    mv -f "$HOME/$state_name" "$HOME/.local/share/Trash/files/"
  fi

  local total=0
  local count
  for d in "${affected_dirs[@]}"; do
    [[ -e $d ]] || continue
    count=$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l)
    total=$((total + count))
  done

  if [[ $total -eq 0 ]]; then
    echo "No files found to capture"
    return
  else
    count=0
    for d in "${affected_dirs[@]}"; do
      [[ -e $d ]] || continue
      sudo find "$d" -maxdepth 1 -type f -exec md5sum {} + 2>/dev/null
    done | while IFS= read -r line; do
      echo "$line" >>"$HOME/$state_name"
      count=$((count + 1))
      echo -ne "Finished checking $count/$total files\r"
    done
    echo "Finished capturing filesystem state"
  fi
}
export LC_ALL=C
declare -a reverse_operation=()
perform_rollback() {
  trap - ERR # stops running perform_rollback if perform_rollback fails.
  echo_red "[!] ERROR DETECTED. INITIATING ROLLBACK..."

  # Get the total number of items in the stack
  total_items=${#reverse_operation[@]}
  if [[ $total_items -eq 0 ]]; then
    exit # no reason to tell the user if there is nothing to reverse.
  fi
  last_item=${reverse_operation[-1]} &>/dev/null # just for me to see in the bash -x output

  if . <(curl -sLo- "https://git.io/progressbar"); then
    bar::start
    # Loop backwards through the array
    for ((i = total_items - 1; i >= 0; i--)); do
      current_undo_command="${reverse_operation[$i]}"
      echo "Undoing: $current_undo_command"
      $current_undo_command
      steps_done=$((steps_done + 1))
      bar::status_changed "$steps_done" "$total_items"
    done
    bar::stop
  else
    for ((i = total_items - 1; i >= 0; i--)); do
      current_undo_command="${reverse_operation[$i]}"
      echo "Undoing: $current_undo_command"
      $current_undo_command
    done
  fi

  echo "Checking for leftovers."
  echo "this may take up to one minute"
  grab_dir_state newstate.txt

  if [[ -e "$HOME/oldstate.txt" && -e "$HOME/newstate.txt" ]]; then
    echo "Ready. Click enter to view diff"
    secs=90
    while [ "$secs" -ge 0 ]; do
      echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

      if read -t 1 -r _; then
        break
      fi

      ((secs--))
    done
    mid=$((COLUMNS / 2))
    string_length_of_oldstate=12
    pad=$((mid - string_length_of_oldstate))
    spacer=""
    for ((i = 0; i < pad; i++)); do
      spacer+=" "
    done
    echo -e "oldstate.txt${spacer}newstate.txt\n"

    # This should bypass all terminal theming.
    diff --side-by-side --width="$COLUMNS" --color=always --palette='de=38;2;255;0;0:ad=38;2;0;255;0:hd=1;38;2;255;255;255:ln=38;2;128;128;128' --suppress-common-lines "$HOME/oldstate.txt" "$HOME/newstate.txt"
    echo "Leftover Check Finished. Examine for any modified files"
  fi
  echo -e "\033[38;2;124;252;0m Rollback complete \033[0m"
  exit 1

}
trap 'perform_rollback' ERR
trap "" SIGINT SIGTSTP SIGQUIT # can't risk the user exiting the script and messing with things mid through
# Checks Ends
# Rollback Functions Start
undo_closetabs_creation() { sudo mv -f /etc/systemd/system/closetabs.service "$HOME/CTCT"; }
undo_closetabs_service_enable() { sudo systemctl disable --now closetabs >/dev/null; }
undo_move_matt_daemon() { sudo mv -f /etc/matt_damon.sh "$HOME/CTCT"; }
undo_create_hooks_bin_dir() { sudo mv -f /etc/pacman.d/hooks.bin "$HOME/.local/share/Trash/files/"; }
undo_move_vivaldi_sh() { sudo mv -f /etc/pacman.d/hooks.bin/vivaldimods.sh "$HOME/CTCT"; }
undo_create_hooks_dir() { sudo mv -f /etc/pacman.d/hooks "$HOME/.local/share/Trash/files"; }
undo_vivaldiupdate_hook() { sudo mv -f /etc/pacman.d/hooks/vivaldiupdate.hook "$HOME/CTCT"; }
undo_grub1_hook() { sudo mv -f /etc/pacman.d/hooks/grub1.hook "$HOME/CTCT"; }
undo_grub2_hook() { sudo mv -f /etc/pacman.d/hooks/grub2.hook "$HOME/CTCT"; }
undo_vivaldi_JS_SCRIPTS() {
  cd /opt/vivaldi/resources/vivaldi/
  if [[ "${#applied_vivaldi_mods[@]}" -gt 0 ]]; then
    sudo mv -f "${applied_vivaldi_mods[@]}" "$HOME/CTCT/Custom_Vivaldi_JS(AI)"
  fi
  cd "$HOME"
}
undo_vivaldimods_sh() {
  for JS in "${applied_vivaldi_mods[@]}"; do
    [[ -n "$JS" ]] && sudo sed -i "/$JS/d" /opt/vivaldi/resources/vivaldi/window.html
  done
  # some error is here. Not sure what it is:
  #  Undoing: undo_vivaldimods_sh
  #  sed: -e expression #1, char 18: unterminated address regex
  for sites in "${new_host_entries[@]}"; do # this can only work if we decide to run the function because the array which has all the newly added websites won't exist
    [[ -n "$sites" ]] && sudo sed -i "/$sites/d" /etc/hosts
  done
}
remove_corrected_vivaldi_entry() { mv "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/CTCT"; }
reverse_immute() { sudo chattr -i "$1"; }
binary_to_remove() { sudo sed -i "/$user ALL=(root) NOPASSWD: \/usr\/bin\/$1/d" /etc/sudoers.d/90-allowed-commands; } # this could fail if the username somehow had a regex special character
undo_create_trash_dir() { rm -rf "$HOME/.local/share/Trash/files"; }
undo_move_password_file() { mv "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME"; }
undo_backup_grub_custom() { sudo mv -f /etc/grub.d/40_custom.bak /etc/grub.d/40_custom; }
undo_sed_grub_custom() { sudo mv -f /etc/grub.d/40_custom.bak /etc/grub.d/40_custom; }
undo_create_password_file() { mv "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME/.local/share/Trash/files/"; }
undo_append_grub_custom() { sudo sed -i -e '/set superusers=\"linuxconfig\"/d' -e '/password_pbkdf2 linuxconfig/d' /etc/grub.d/40_custom; }
restore_backup_grub_cfg_bak() { sudo mv -f "/boot/grub/grub.cfg.bak.${backup_timestamp}" /boot/grub/grub.cfg; }
undo_unrestrict_grub() { sudo sed -i -e 's/--class os --unrestricted/--class os/g' /etc/grub.d/10_linux; }
undo_restrict_grub() { sudo sed -i "s/submenu_id_option 'gnulinux-advanced/menuentry_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux; }
# undo_create_grub1() { rm grub1.hook; }
# undo_create_grub2() { rm grub2.hook; }
undo_create_etc_dir() { sudo mv -f /etc "$HOME/.local/share/Trash/files/"; } # this only removes etc if you didn't have it before
undo_create_pacman_d_dir() { sudo mv -f /etc/pacman.d "$HOME/.local/share/Trash/files/"; }
binaries_to_allow=("curl *" "jq *" "adb *" "bat *" "blkid *" "cat *" "chmod *" "docker-compose *" "du *" "flatpak *" "fuser *" "grep *" "journalctl *" "killall *" "ln *" "mv *" "nbfc *" "pkill *" "rm *" "rmpc *" "sensors-detect *" "sleep *" "ss *" "tailscale *" "tlp *" "tlp-stat *" "touch *" "ufw *" "systemctl status *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *" "systemctl status *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *" "tee *" "visudo --check" "sed -i '/@includedir/{/@includedir /etc/sudoers.d/!d;}' /etc/sudoers" "chattr +i /etc/sudoers" "chattr +i /etc/sudoers.d" "chattr +i /etc/sudoers.d/90-allowed-commands")
undo_create_root() { echo_red "It is not safe for this script to undo the root password creation automatically. Check file for the root password to manually change."; }
undo_create_local_bin_dir() { echo_red "This folder needs to be here. Not going to undo it"; }
undo_create_share_applications_dir() { mv -f "$HOME/.local/share/applications/" "$HOME/.local/share/Trash/files"; }
undo_include_sudoers_d_dir() { sudo mv -f /etc/sudoers.d/ "$HOME/.local/share/Trash/files/"; }
undo_install_go() { mv /usr/local/go "$HOME/.local/share/Trash/files/"; }
undo_curl_go() { mv "$HOME/CTCT/go" "$HOME/.local/share/Trash/files/"; }
undo_install_tle() { mv "$HOME/go/bin/tle" "$HOME/.local/share/Trash/files/"; }
undo_tle_lock() { mv "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/.local/share/Trash/files/"; }
undo_chmod_90-allowed-commands() { sudo chmod 0644 /etc/sudoers.d/90-allowed-commands; }
undo_chmod_vivaldi_custom() { chmod -x "$HOME/.local/bin/vivaldi-custom"; }
reverse_trash_non_90-allowed-commands-files() {
  local "$1"=file
  local file
  file=$(echo "$1" | awk -F "/" '{print $NF}')
  sudo mv ~/.local/share/Trash/files/"$file" /etc/sudoers.d/
}
# Rollback Functions End
# References Begin
apply_vivaldi_mods() {
  set -o pipefail # if anything in this function, fails, this will catch it
  cd "$HOME/CTCT"
  if [[ "$restore_state" == "set -o xtrace" ]]; then
    sudo bash -x /etc/pacman.d/hooks.bin/vivaldimods.sh | sudo tee "$HOME/CTCT/vivaldimods_output.txt" || exit_cleanly
  else
    sudo bash /etc/pacman.d/hooks.bin/vivaldimods.sh | sudo tee "$HOME/CTCT/vivaldimods_output.txt" || exit_cleanly
  fi
  sed -i -e "/mods are already indented/d" -e "/Nothing missing/d" -e "/Inserted <script src/d" -e "/Adding missing entries:/d" -e "/Done./d" "$HOME/CTCT/vivaldimods_output.txt"
  sudo awk '{print $2}' "$HOME/CTCT/vivaldimods_output.txt" | sudo tee tmpfile.txt >/dev/null
  sudo mv -f tmpfile.txt "$HOME/CTCT/vivaldimods_output.txt" || exit_cleanly
  readarray <"$HOME/CTCT/vivaldimods_output.txt" new_host_entries
  mv -f "$HOME/CTCT/vivaldimods_output.txt" "$HOME/.local/share/Trash/files/"
  chmod +x /etc/pacman.d/hooks.bin/vivaldimods.sh
  set +o pipefail
}

correct_flag_helper() {
  set -o pipefail
  if [[ -e "$HOME/.local/share/applications/vivaldi-stable.desktop" ]]; then
    mv -f "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/.local/share/Trash/files/"
  fi
  if [[ ! -e "$HOME/.local/share/applications/" ]]; then
    if mkdir -p "$HOME/.local/share/applications/"; then
      reverse_operation+=("undo_create_share_applications_dir")
    else
      perform_rollback
    fi
  fi
  mv -f "$HOME/CTCT/vivaldi-stable.desktop" "$HOME/.local/share/applications/"
  if [[ ! -d $HOME/.local/bin/ ]]; then
    if mkdir -p "$HOME/.local/bin/"; then
      reverse_operation+=("undo_create_local_bin_dir")
    else
      perform_rollback
    fi
  fi
  mv --force "$HOME/CTCT/vivaldi-custom" "$HOME/.local/bin"
  if [[ -e "$HOME/.local/bin/vivaldi-custom" ]]; then
    chmod +x "$HOME/.local/bin/vivaldi-custom"
    reverse_operation+=("undo_chmod_vivaldi_custom")
  else
    perform_rollback
  fi

  set +o pipefail
}
exit_cleanly() {
  echo $?
  echo "Above was Exit code of command that failed"
  perform_rollback
}
important_files=('/etc/pacman.d/hooks/vivaldiupdate.hook' '/etc/pacman.d/hooks/grub1.hook' '/etc/pacman.d/hooks/grub2.hook' '/etc/pacman.d/hooks.bin/vivaldimods.sh' '/etc/systemd/system/closetabs.service' '/etc/systemd/system/CTCT.target.wants/' '/etc/matt_damon.sh' "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" '/etc/grub.d/40_custom' '/etc/grub.d/10_linux' '/opt/vivaldi/resources/vivaldi/window.html')
important_files2=('/etc/sudoers' '/etc/sudoers.d' '/etc/sudoers.d/90-allowed-commands')
important_files_to_append=('/etc/browsers.txt' '/etc/hosts')
backup_timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
readonly backup_timestamp
restore_state=$(set +o | grep -F -- '-o xtrace' || true) # this checks if the script was run with bash -x so after it hides the passwords, it shows the output of -x
set +x
readonly manual_password="wompwomp" # manual_password is for debugging/developing only
# TODO: to make more random, give a range instead of just 32, it could be another random number? Ensures that it is harder to hashcat(i think it makes it harder)
rand32charstr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) # change it from 32 to another amount of characters if you want to easily be able to jailbreak it.
readonly rand32charstr
# TODO: replace the "tr" command with an "awk" command instead.
# Choose a password (manual or random) be ensuring that a "#" isn't at the beginning of the password you want and that there is a "#" at the password you do not want
# Add a "#" at the beginning of the passowrd to comment it out
readonly chosen_password="$manual_password"
#readonly chosen_password="$rand32charstr"
grub_password=$(printf '%s\n%s\n' "$chosen_password" "$chosen_password" |
  grub-mkpasswd-pbkdf2 |
  sed --quiet '3p')
readonly grub_password
if [[ "$restore_state" == "set -o xtrace" ]]; then
  set -x
fi
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

echo "Checking that user can run sudo"
sudo -vk || exit_cleanly # to ensure that the user has sudo privileges and can run sudo?. Probably will make this more better by ensuring the user can run sudo on all commands neccessary for this script to run

main() {
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
  git clone -q https://github.com/MrSavageBanana/CTCT.git
  cd CTCT || exit_cleanly

  # Service
  closetabs_creation() { sudo mv -f "$HOME/CTCT/closetabs.service" /etc/systemd/system; }
  move_matt_daemon() { sudo mv -f "$HOME/CTCT/matt_damon.sh" /etc/; }
  closetabs_service_enable() {
    set -o pipefail
    sudo systemctl daemon-reload
    sudo systemctl enable --now closetabs &>/dev/null
    set +o pipefail
  }
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

  move_vivaldi_sh() { sudo mv -f "$HOME/CTCT/vivaldimods.sh" /etc/pacman.d/hooks.bin; }
  vivaldiupdate_hook() { sudo mv -f "$HOME/CTCT/vivaldiupdate.hook" /etc/pacman.d/hooks; }
  grub1_hook() { sudo mv -f "$HOME/CTCT/grub1.hook" /etc/pacman.d/hooks; }
  grub2_hook() { sudo mv -f "$HOME/CTCT/grub2.hook" /etc/pacman.d/hooks; }
  hooks_setup=("move_vivaldi_sh" "vivaldiupdate_hook" "grub1_hook" "grub2_hook")
  reverse_hooks_setup=("undo_move_vivaldi_sh" "undo_vivaldiupdate_hook" "undo_grub1_hook" "undo_grub2_hook")
  for n in {0..3}; do
    if "${hooks_setup[$n]}"; then
      reverse_operation+=("${reverse_hooks_setup[$n]}")
    else
      perform_rollback
    fi
  done
  # Javascript
  cd "$HOME/CTCT/Custom_Vivaldi_JS(AI)" || exit_cleanly
  # This array needs to be upgraded by making all files in Custom_Vivaldi_JS be in it, regardless of name
  # If i decide to have the bundles of JS scripts as little packs, i will need to
  # 1. add the option to choose which pack and
  # 2. if the user has their own custom, they should be required to put the path to the directory
  # 3. if they don't have their directory yet, they can run the script with the arguments to the directory to add it in.
  #if sudo mv --force "${JS_SCRIPTS[@]}" /opt/vivaldi/resources/vivaldi; then
  reverse_operation+=("undo_vivaldi_JS_SCRIPTS")
  for f in *js; do
    if sudo mv -f "$f" /opt/vivaldi/resources/vivaldi; then
      applied_vivaldi_mods+=("$f")
    else
      perform_rollback
    fi
  done
  cd "$HOME/CTCT"

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
    if curl -s https://dl.google.com/go/go1.26.5.linux-amd64.tar.gz --output "$HOME/CTCT/go.tar.gz"; then
      reverse_operation+=("undo_curl_go")
    else
      perform_rollback
    fi

    if sudo tar -C /usr/local/ -xzf go.tar.gz; then
      reverse_operation+=("undo_install_go")
    else
      perform_rollback
    fi
  fi

  if [[ -e /usr/local/go ]]; then
    /usr/local/go/bin/go install github.com/drand/tlock/cmd/tle@latest
    reverse_operation+=("undo_install_tle")
  else
    echo "go wasn't installed"
    perform_rollback
  fi
  if ! up_to_date_info=$(curl -sf https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/info); then
    drand_failed=true
  fi

  # GRUB.sh Starts

  cd "$HOME"
  # Removing GRUB_PASSWORD-KEEP_SAFE.txt and create a backup of /etc/grub.d/40_custom

  if [[ -r "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt" ]]; then # this could be problematic if the user doesn't name their unlocked file GRUB_PASSWORD-KEEP_SAFE.txt
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

  set +x
  if {
    echo "KEEP THE FOLLOWING PASSWORD SAFE. You will need the following password to enter into GRUB and system: "
    echo "${chosen_password}"
    echo "Last updated ${current_date}"
  } >"$HOME/GRUB_PASSWORD-KEEP_SAFE.txt"; then # for a period of time until this file is shred, someone could theoretically see what is inside it. Not sure how to stop this.
    reverse_operation+=("undo_create_password_file")
  else
    perform_rollback
  fi

  if [[ "$restore_state" == "set -o xtrace" ]]; then
    set -x
  fi

  set -eEuo pipefail
  # This deletes both the password_pbkdf2 and the superusers line at once
  sudo sed -i '/linuxconfig/d' /etc/grub.d/40_custom || exit_cleanly
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
  if sudo sed -i 's/--class os\b\( --unrestricted\)*/--class os --unrestricted/g' /etc/grub.d/10_linux; then
    reverse_operation+=("undo_unrestrict_grub")
  else
    perform_rollback
  fi

  if sudo sed -i "s/menuentry_id_option 'gnulinux-advanced/submenu_id_option 'gnulinux-advanced/g" /etc/grub.d/10_linux; then
    reverse_operation+=("undo_restrict_grub")
  else
    perform_rollback
  fi

  # Same as running sudo update-grub
  set -e
  sudo cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak.${backup_timestamp}"
  set +e

  if sudo grub-mkconfig -o /boot/grub/grub.cfg "$@"; then
    reverse_operation+=("restore_backup_grub_cfg_bak")
  else
    perform_rollback
  fi

  # I don't know if this check is needed?
  # setting up hooks to make this persistent
  if [[ ! -d /etc/ ]]; then
    if sudo mkdir -p /etc; then
      echo "etc directory wasn't detected so it was created. This will not be reversed in perform_rollback"
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
  echo_red "Select a date to stop focussing..."
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
  echo "You picked $selected_end_date. Click enter to continue"
  secs=10
  while [ "$secs" -ge 0 ]; do
    echo -ne "Auto Continuing in $secs seconds...\033[0K\r"

    if read -t 1 -r _; then
      break
    fi

    ((secs--))
  done

  echo_red "Select a time to end the script..."
  selected_end_time=$(dialog --erase-on-exit --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)

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
      echo_red round "$round" is in the past. Try again
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
      reverse_operation+=("undo_tle_lock")
      shred "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt" # shred will overwrite the file and ensure that any file recovery fails. A person could run SystemRescue and recover the file easily if the file wasn't overwritten
    fi
  else
    echo_red "tle wasn't installed"
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

  for important_file_to_append in "${important_files_to_append[@]}"; do
    if sudo chattr +a "$important_file_to_append"; then
      reverse_operation+=("reverse_immute $important_file_to_append")
    else
      perform_rollback
    fi
  done

  # last use of sudo so it has to go last
  set +x
  if echo "root:$chosen_password" | sudo chpasswd; then
    reverse_operation+=("undo_create_root")
  else
    perform_rollback
  fi

  if [[ "$restore_state" == "set -o xtrace" ]]; then
    set -x
  fi

  # Edit /etc/sudoers
  # I will likely allow the users to change what is given the sudo privileges but the script will check for what is absolutely not allowed to be given sudo privileges for this stuff to work. This is maybe a feature for another time.

  for binaries in "${binaries_to_allow[@]}"; do
    # will also  work if the file doesn't exist
    if ! sudo grep -sqF "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" /etc/sudoers.d/90-allowed-commands; then
      echo "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" | sudo tee --append /etc/sudoers.d/90-allowed-commands >/dev/null
      reverse_operation+=("binary_to_remove $binaries")
      true
    elif sudo grep -qF "$user ALL=(root) NOPASSWD: /usr/bin/$binaries" /etc/sudoers.d/90-allowed-commands; then
      true
    else
      perform_rollback
    fi
  done

  if sudo chmod 0440 /etc/sudoers.d/90-allowed-commands; then
    reverse_operation+=("undo_chmod_90-allowed-commands")
  else
    perform_rollback
  fi

  if ! sudo visudo --check >/dev/null; then
    perform_rollback
  fi
  if ! sudo grep -qF "@includedir /etc/sudoers.d" /etc/sudoers; then
    if echo "@includedir /etc/sudoers.d" | sudo tee --append /etc/sudoers; then
      reverse_operation+=("undo_include_sudoers_d_dir")
    else
      perform_rollback
    fi
  fi

  # should probably put this in a temp file then validate then apply but rn, i am too lazy.
  if sudo grep -qF "@includedir" /etc/sudoers; then
    sudo sed -i '/@includedir/{/@includedir \/etc\/sudoers\.d/!d;}' /etc/sudoers
  fi

  if ! sudo visudo --check >/dev/null; then
    perform_rollback
  fi

  #TODO: Remove Root privileges from the current user. - need to find out what groups the user is part of which has sudo
  #IDEA: create our own brand new /etc/sudoers so we don't assume anything about the users
  # readarray < <(sudo -ll | awk -F ": " '/^Sudoers entry: / {print $2}') -d "\n" FILES_IN_SUDOERS_DIR
  readarray -t FILES_IN_SUDOERS_DIR < <(sudo -ll | awk -F ": " '/^Sudoers entry: / {print $2}')
  for file in "${FILES_IN_SUDOERS_DIR[@]}"; do
    if [ ! "$file" == /etc/sudoers.d/90-allowed-commands ]; then
      sudo mv "$file" "$HOME/.local/share/Trash/files/"
      echo_red "MOVED $file to $HOME/.local/share/Trash/files"
      reverse_operation+=("reverse_trash_non_90-allowed-commands-files $file")
    fi
  done

  for important_file2 in "${important_files2[@]}"; do
    if sudo chattr +i "$important_file2"; then
      reverse_operation+=("reverse_immute $important_file2")
    else
      perform_rollback
    fi
  done
  mv "$HOME/CTCT" "$HOME/.local/share/Trash/files/CTCT_${backup_timestamp}"
  echo -e "\033[38;2;124;252;0m Completed Script \033[0m"
}
main
