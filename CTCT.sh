#!/bin/bash
# contemplating whether to create different script files and source them. This script is getting messy.
# shellcheck disable=SC2034
# shellcheck disable=SC1090
# For disabling the messages when the exit message is there:
# shellcheck disable=SC2317
# shellcheck disable=SC2329
exit                                                     # if this is accidentally ran. I don't want to ruin my computer. Remove this when needed and the shellcheck lines above
restore_state=$(set +o | grep -F -- '-o xtrace' || true) # this checks if the script was run with bash -x so after it hides the passwords, it shows the output of -x
echo_red() {                                             # for things that needs the users attention
  builtin echo -e "\033[38;2;255;0;0m >>> $* <<< \033[0m"
}
countdown() {
  set +x
  secs="$1"
  while [ "$secs" -ge 0 ]; do
    echo -ne "Auto Continuing in $secs seconds...\033[0K\r"
    if read -t 1 -r _; then
      break
    fi
    ((secs--))
  done
  if [[ "$restore_state" == "set -o xtrace" ]]; then
    set -x
  fi
}
idk_a_good_name() {
  local -n chosen_array="$1"
  local chosen_item
  echo_red "${#chosen_array[@]}" "$2!:"
  for chosen_item in "${chosen_array[@]}"; do
    echo "$chosen_item"
  done
}
immuting() {
  local -n chosen_array="$1"
  local chosen_leading_path="$2"
  local chosen_attribute="$3"
  local chosen_item
  if [[ -z "$chosen_attribute" ]]; then
    chosen_attribute=i
  fi
  for chosen_item in "${chosen_array[@]}"; do
    if sudo chattr +"$chosen_attribute" "$chosen_leading_path$chosen_item"; then
      reverse_operation+=("reverse_immute" "$chosen_leading_path$chosen_item")
    else
      perform_rollback
    fi
  done
}
SCRIPT_NAME=${BASH_SOURCE[0]##*/}
SCRIPT_DIR=$(
  if cd -- "${BASH_SOURCE[0]%/*}" 2>/dev/null; then
    pwd
  else
    pwd
  fi
)
FILE_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
# flag idea: a quiet flag which will remove any output that may show up.
# The users can specify what they want gone and
# it will write to a variable that will be checked before the variable is used
SHORT="vfP:pS:b:Dshd:w:a:F:tc:"
LONG="validate,fix,privileges:,print-privileges,sites:,blocklist:,decrypt,show-password,help,date:,add-website:,add-process:,add-file:,check-current-focus:,show-tabs"
if ! PARSED=$(getopt --options "$SHORT" --longoptions "$LONG" --name "$0" -- "$@"); then
  echo "Try '$FILE_PATH --help' for more information"
  exit 2
fi
eval set -- "$PARSED"

if [ "$EUID" -eq 0 ]; then
  echo_red "Don't run as root. You will be prompted for sudo privileges."
  exit 1
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
declare -a reverse_operation=()
declare -a CUSTOM_SITES=()
declare -a CUSTOM_BLOCKLISTS=()
important_files=('/etc/pacman.d/hooks/vivaldiupdate.hook' '/etc/pacman.d/hooks/grub1.hook' '/etc/pacman.d/hooks/grub2.hook' '/etc/pacman.d/hooks.bin/vivaldimods.sh' '/etc/systemd/system/closetabs.service' '/etc/systemd/system/CTCT.target.wants/' '/etc/matt_damon.sh' "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" '/etc/grub.d/40_custom' '/etc/grub.d/10_linux' '/opt/vivaldi/resources/vivaldi/window.html')
important_files2=('/etc/sudoers' '/etc/sudoers.d' '/etc/sudoers.d/90-allowed-commands')
important_files_to_create=('/etc/file-focus.txt' '/etc/process-focus.txt' '/etc/website-focus.txt')
important_files_to_append=('/etc/browsers.txt' '/etc/hosts' '/etc/file-focus.txt' '/etc/process-focus.txt' '/etc/website-focus.txt')
potentially_overwritten_files=("/etc/systemd/system/closetabs.service" "/etc/systemd/system/CTCT.target.wants/closetabs.service" "/etc/matt_damon.sh" "/etc/browsers.txt" "/etc/pacman.d/hooks.bin/vivaldimods.sh" "/etc/pacman.d/hooks/vivaldiupdate.hook" "/etc/pacman.d/hooks/grub1.hook" "/etc/pacman.d/hooks/grub2.hook" "$HOME/CTCT/vivaldimods_output.txt" "$HOME/.local/share/applications/vivaldi-stable.desktop" "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "/etc/sudoers.d/90-allowed-commands" "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/.local/share/Trash/files/GRUB_PASSWORD-KEEP_SAFE.txt" "$HOME/.local/share/Trash/files/vivaldimods_output.txt" "$HOME/.local/share/Trash/files/vivaldi-stable.desktop" "$HOME/.local/share/Trash/files/CTCT_${backup_timestamp}" "$HOME/.local/share/Trash/files/tle")
user=$(whoami)
export LC_ALL=C
trap 'perform_rollback' ERR
trap "" SIGINT SIGTSTP SIGQUIT # can't risk the user exiting the script and messing with things mid through
# TODO: Attempt to fix the missing dependencies. DEPENDS ON: Auto Detect the system's package manager and use it instead of just pacman. At least Debian and Fedora
deps=("flock" "grub-mkpasswd-pbkdf2" "sed" "date" "rm" "mv" "sudo" "mkdir" "cp" "tee" "grub-mkconfig" "cat" "awk" "dialog" "git" "grep" "curl" "chpasswd" "chattr" "systemctl" "grep" "tar" "diff" "find" "md5sum" "sort" "bash" "tr" "fold" "head" "shred" "whoami" "basename" "pgrep" "kill" "xargs" "uniq" "file" "strace" "vivaldi" "pacman")
check_dependencies() {
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing_dependencies+=("$dep")
    fi
  done
  if [[ "${#missing_dependencies[@]}" -eq 0 ]]; then
    echo "No Dependencies Missing"
  elif [[ "${#missing_dependencies[@]}" -ne 0 ]]; then
    idk_a_good_name "missing_dependencies" 'missing dependencies'
    if [[ ! $VALIDATEOPT -eq 1 ]]; then
      exit
    fi
  fi
}
check_overwritten() {
  # we are unable to warn the users about the JS files that may be overwritten unless we ping the github repo (which we will already do when we clone) to check what files might be overwritten
  for file in "${potentially_overwritten_files[@]}"; do
    if [[ -e "$file" ]]; then
      overwritten_files+=("$file")
    fi
  done
  if [[ "${#overwritten_files[@]}" -eq 0 ]]; then
    if command -v vivaldi >/dev/null; then # checks if vivaldi is installed. if it is, there may be some js files. if not, there is no reason to suspect
      echo "No files will be overwritten"
      echo_red "Also check for JS files at /opt/vivaldi/resources/vivaldi/"
      if [[ ! $VALIDATEOPT -eq 1 ]]; then
        echo "Use this time to check for JS files at /opt/vivaldi/resources/vivaldi/. Press enter when checked"
        countdown 90
      fi
    fi
  elif [[ "${#overwritten_files[@]}" -ne 0 ]]; then
    idk_a_good_name "overwritten_files" "overwritten files"
    if command -v vivaldi >/dev/null; then # checks if vivaldi is installed. if it is, there may be some js files. if not, there is no reason to suspect
      echo_red "Also check for JS files"
    fi
    if [[ ! $VALIDATEOPT -eq 1 ]]; then
      exit
    fi
  fi

  potentially_overwritten_directories=("$HOME/CTCT/" "/etc/systemd/system/CTCT.target.wants" "$HOME/.local/share/Trash/files/hooks.bin" "$HOME/.local/share/Trash/files/hooks" "$HOME/.local/share/Trash/files/etc" "$HOME/.local/share/Trash/files/pacman.d" "$HOME/.local/share/Trash/files/sudoers.d" "$HOME/.local/share/Trash/files/go" "$HOME/.local/share/Trash/files/CTCT")
  for dir in "${potentially_overwritten_directories[@]}"; do
    if [[ -e "$dir" ]]; then
      overwritten_dirs+=("$dir")
    fi
  done
  if [[ "${#overwritten_dirs[@]}" -ne 0 ]]; then
    idk_a_good_name "overwritten_dirs" "overwritten dirs"
    if [[ ! $VALIDATEOPT -eq 1 ]]; then
      exit
    fi
  fi
}
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
    countdown 90
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
fix_overwritten() {
  all_potentially_problomatic_files=(
    "${overwritten_files[@]}"
    "${important_files[@]}"
    "${important_files2[@]}"
    "${important_files_to_append[@]}"
  )
  for f in "${all_potentially_problomatic_files[@]}"; do
    if [[ -e "$f" ]]; then
      sudo chattr -ia "$f" &>/dev/null
    fi
  done
  if [[ ! -e "$HOME/.local/share/Trash/files/" ]]; then
    mkdir -p "$HOME/.local/share/Trash/files/"
  fi
  for f2 in "${potentially_overwritten_files[@]}"; do
    if [[ -e "$f2" ]]; then
      sudo mv -f "$f2" "$HOME/.local/share/Trash/files/"
    fi
  done
  # Deletes lines with the username and password
  sudo sed -i.bak -e '/linuxconfig/d' -e '/grub.pbkdf2.sha512/d' /etc/grub.d/40_custom
  # unrestrict Grub
  sudo sed -i 's/--class os\b\( --unrestricted\)*/--class os --unrestricted/g' /etc/grub.d/10_linux
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}
fix_dependencies() {
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing_dependencies+=("$dep")
    fi
  done
  if [[ "${#missing_dependencies[@]}" -eq 0 ]]; then
    echo "No Dependencies Missing"
  elif [[ "${#missing_dependencies[@]}" -ne 0 ]]; then
    for missing_dependency in "${missing_dependencies[@]}"; do
      sudo pacman -S --noconfirm "$missing_dependency"
    done
    echo_red "Run $FILE_PATH (-v | --validate) to confirm changes."
  fi
  echo -ne '\n'
  echo_red "IF CLEANING ALL LEFTOVER EFFECTS FROM CTCT, THE FOLLOWING APPLY:"
  echo_red "remove entries from /etc/hosts yourself" # since fix_dependencies is always run with fix_overwritten, just put the fix_overwritten messages here
  echo_red "remove leftover JS from /opt/vivaldi/resources/vivaldi/ yourself"
}
anchor() {
  set -o nounset
  local inserts="$1"
  local anchor="$2"
  local instance="$3"
  local file="$4"
  local output="$5"
  if grep -qF "$inserts" "$file"; then
    echo_red "$inserts is a DUPLICATE ENTRY!"
  else
    # change the 1 to another number to get that instance of the $inserts in $file
    awk -v anchor="$anchor" -v insert="\n\t\"$inserts\"" -v n="$instance" '
    index($0, anchor) > 0 {
    count++
    if (count == n) {
    pos = index($0, anchor)
    $0 = substr($0, 1, pos + length(anchor) - 1) insert substr($0, pos + length(anchor))
    }
    }
    1' "$file" >tmp.txt && mv tmp.txt "$file"
    if [ "$output" == "true" ]; then
      echo "Inserted $inserts. $file has been updated"
    fi
  fi
  set +o nounset
}
edit_privileges() {
  set -o nounset
  local INSERTS="$1"
  local ERROR=0
  if [[ "$INSERTS" == *" "* ]]; then
    echo "REMOVE SPACES"
    ((ERROR++))
  fi
  if [[ "$INSERTS" != *"*"* ]]; then
    INSERTS="$INSERTS *"
  fi
  if [[ "$INSERTS" == *"/"* ]]; then
    echo "REMOVE SLASHES"
    ((ERROR++))
  fi
  if [[ "$ERROR" -gt 0 ]]; then
    echo "FIX ERRORS THEN RETRY AGAIN"
    exit
  fi
  anchor "$INSERTS" "binaries_to_allow=(" "4" "$FILE_PATH" "true"
  echo_red "Run $FILE_PATH (-p | --print_privileges) to confirm changes."
}
print_binaries_to_allow() {
  echo "All Binaries Allowed:"
  for binary in "${binaries_to_allow[@]}"; do
    echo "$binary"
  done
}
edit_sites() {
  local FILE="$HOME/CTCT/vivaldimods.sh"
  if [[ ! -e $FILE ]]; then
    perform_rollback
  fi
  for site in "${CUSTOM_SITES[@]}"; do
    anchor "$site" "custom_websites=(" "1" "$FILE" "false"
  done
}
edit_blocklists() {
  local FILE="$HOME/CTCT/vivaldimods.sh"
  if [[ ! -e $FILE ]]; then
    perform_rollback
  fi
  for blocklist in "${CUSTOM_BLOCKLISTS[@]}"; do
    anchor "$blocklist" "extra_mirrors=(" "1" "$FILE" "false"
  done
}

print_help() {
  echo -e "\033[1mUsage:\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-v\033[0m | \033[1m--validate\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-f\033[0m | \033[1m--fix\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-p\033[0m | \033[1m--print-privileges\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-P\033[0m | \033[1m--privileges\033[0m PRIVILEGE"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-w\033[0m | \033[1m--add-website\033[0m WEBSITE\033[1m:\033[0mDURATION"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-a\033[0m | \033[1m--add-process\033[0m PROCESS\033[1m:\033[0mDURATION"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-F\033[0m | \033[1m--add-file\033[0m FILE\033[1m:\033[0mDURATION"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-c\033[0m | \033[1m--check-current-focus\033[0m FLAG"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-t\033[0m | \033[1m--show-tabs\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-D\033[0m \033[1m-s\033[0m"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m [\033[1m-d\033[0m | \033[1m--date\033[0m DATE] [\033[1m-S\033[0m | \033[1m--sites\033[0m SITE] [\033[1m-b\033[0m | \033[1m--blocklist\033[0m BLOCKLIST]"
  echo -e "  \033[1m$SCRIPT_NAME\033[0m \033[1m-h\033[0m | \033[1m--help\033[0m"
  echo -e "\n\033[1mOPTIONS\033[0m"
  echo -e "  \033[1m-v, --validate\033[0m\n      check that the script can run without overwriting files or missing dependencies"
  echo -e "  \033[1m-f, --fix\033[0m\n      download any missing dependencies and move overwritten files to $HOME/.local/share/Trash/files/"
  echo -e "  \033[1m-P, --privileges\033[0m\n      add binary you want to be able to run with sudo and exit"
  echo -e "  \033[1m-p, --print-privileges\033[0m\n      print privileges to screen and exit"
  echo -e "  \033[1m-D, --decrypt\033[0m\n      decrypt password and prompt to change it"
  echo -e "  \033[1m-s, --show-password\033[0m\n      to be used with --decrypt. shows new password user types when changing"
  echo -e "  \033[1m-d, --date\033[0m\n      add a date to end the focus. format: MM\033[1m/\033[0mDD\033[1m/\033[0mYY HH\033[1m:\033[0mMM\033[1m:\033[0mSS"
  echo -e "  \033[1m-w, --add-website\033[0m\n      add a website to be blocked for some time (see DURATION below)"
  echo -e "  \033[1m-a, --add-process\033[0m\n      add a process to be blocked for some time (see DURATION below)"
  echo -e "  \033[1m-F, --add-file\033[0m\n      add a file or directory to be uneditable for some time (see DURATION below)"
  echo -e "  \033[1m-c, --check-current-focus\033[0m\n      print remaining time for active focus sessions. FLAG must be 'a', 'F', 'w', or their full names"
  echo -e "  \033[1m-t, --show-tabs\033[0m\n      display open tabs with an interactive menu to temporarily block sites"
  echo -e "  \033[1m-S, --sites\033[0m\n      add sites to be blocked"
  echo -e "  \033[1m-b, --blocklist\033[0m\n      add a stevenblack blocklist to add to hosts"
  echo -e "  \033[1m-h, --help\033[0m\n      show this message and exit"
  echo -e "\n\033[1mDURATION FORMAT\033[0m"
  echo -e "  DURATION uses natural language to specify how long the focus lasts."
  echo -e "  Examples:"
  echo -e "    \033[1m'3 min'\033[0m           ends the focus in 3 minutes"
  echo -e "    \033[1m'3 days 2 hours'\033[0m  ends the focus in 3 days and 2 hours"
  echo -e "    \033[1m'3 friday'\033[0m        ends the focus 3 fridays from now"
  echo -e "    \033[1m'sunday'\033[0m          ends the focus the next sunday"
  echo -e "    \033[1m'tomorrow 12am'\033[0m   ends the focus at 12:00 AM tomorrow"
}

time_left() {
  local time_diff="$1"
  if [ "$time_diff" -lt 0 ]; then
    result="0 seconds"
  elif [ "$time_diff" -lt 60 ]; then
    result="less than 60 seconds"
  else
    days=$((time_diff / 86400))
    rem=$((time_diff % 86400))
    hours=$((rem / 3600))
    rem=$((rem % 3600))
    minutes=$((rem / 60))
    seconds=$((rem % 60))
    parts=()
    if [ "$days" -gt 0 ]; then parts+=("$days days"); fi
    if [ "$hours" -gt 0 ]; then parts+=("$hours hours"); fi
    if [ "$minutes" -gt 0 ]; then parts+=("$minutes minutes"); fi
    if [ "$seconds" -gt 0 ]; then parts+=("$seconds seconds"); fi
    count=${#parts[@]}
    result=""
    if [ "$count" -eq 1 ]; then
      result="${parts[0]}"
    elif [ "$count" -eq 2 ]; then
      result="${parts[0]} and ${parts[1]}"
    else
      for ((i = 0; i < count - 1; i++)); do
        result="${result}${parts[$i]}, "
      done
      result="${result}and ${parts[$((count - 1))]}"
    fi
  fi
}
decrypt() {
  local round
  local epoch
  local selected_end
  local current_epoch
  local time_diff
  if [[ ! -e "$HOME/go/bin/tle" ]]; then
    echo "tle was not found at \"$HOME/go/bin/tle\""
    exit
  else
    if [[ -e "$HOME/GRUB_PASSWORD-KEEP_SAFE_unlocked.txt" ]]; then
      echo_red "Remove GRUB_PASSWORD-KEEP_SAFE_unlocked.txt then try again"
      exit
    fi
    up_to_date_info=$(curl -sf https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/info)
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
    # this should print it's own stdout which will say if it isn't time yet.
    decrypt_output=$("$HOME/go/bin/tle" --decrypt -o "$HOME/GRUB_PASSWORD-KEEP_SAFE_unlocked.txt" "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" 2>&1)
    if [[ ! -z "$decrypt_output" ]]; then
      round=$(echo "$decrypt_output" | awk -F " " '{print $7}')
      epoch=$((((round - 1) * period) + genesis))
      selected_end=$(date -d "@$epoch" "+%X %x")
      current_epoch=$(date +%s)
      time_diff=$((epoch - current_epoch))
      time_left "$time_diff"
      if [[ ! -z "$selected_end" ]]; then
        if [[ ! -z "$time_diff" && ! -z "$result" ]]; then
          echo "Ends at $selected_end ($result remaining)"
        else
          echo "Ends at $selected_end"
        fi
      fi
    fi

    if [[ -s "$HOME/GRUB_PASSWORD-KEEP_SAFE_unlocked.txt" ]]; then
      local old_password
      old_password=$(awk 'NR==2 {print; exit}' "$HOME/GRUB_PASSWORD-KEEP_SAFE_unlocked.txt" 2>/dev/null)
      echo -e "\033[38;2;124;252;0m Current ROOT Password=$old_password \033[0m"
      if [ "$SHOW_PASSWORD" == true ]; then
        set +x
        read -pr 'Enter new password for Root: ' new_password
      else
        read -spr 'Enter new password for Root: ' new_password
        set +x
      fi
      echo "root:$new_password" | su --command chpasswd
      if [[ "$restore_state" == "set -o xtrace" ]]; then
        set -x
      fi
    fi
  fi
}
up_to_date_JS() {
  cd "$HOME/CTCT/Custom_Vivaldi_JS(AI)/" || exit_cleanly
  for file in *js; do
    anchor "$file" "INSERTS=(" "1" "$HOME/CTCT/vivaldimods.sh" "false"
  done
  cd "$HOME"
}
add_X() {
  local option="$1"
  local options_option="$2"
  local time="$3"
  if ! up_to_date_info=$(curl -sf https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/info); then
    drand_failed=true
  fi
  ending_epoch=$(date -d "$time" +%s)
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

  # this should quote the option in the file like so
  # "option" "round"
  if [ "$option" == "website" ]; then
    echo "\"$options_option\"" "\"$round\"" | sudo tee -a "/etc/website-focus.txt"
  elif [ "$option" == "process" ]; then
    echo "\"$options_option\"" "\"$round\"" | sudo tee -a "/etc/process-focus.txt"
  elif [ "$option" == "file" ]; then
    echo "\"$options_option\"" "\"$round\"" | sudo tee -a "/etc/file-focus.txt"
  else
    exit 1
  fi

  echo "\"$options_option\" \"$round\"" | awk -F: -v option="$option" '{
    if (NF >= 3) {
        print "ERROR: Colons are meant to seperate the" option "from the duration."
        exit 1
    } else {
        exit 0
    }
}'

  if grep -qF "\"$options_option\" \"$round\"" "/etc/${option}-focus.txt"; then
    echo -e "\033[38;2;124;252;0m added $options_option successfully \033[0m"
  else
    echo_red "ERROR. Couldn't confirm $options_option was added"
  fi
}
multi_flag_error_check() {
  local flag="$1"
  local arg1_label="$2"
  local arg1="$3"
  local arg2="$4"
  echo "$arg2" | awk -F: -v option="$option" -v flag="$flag" '{
    if (NF >= 3) {
        print "ERROR: Colons are meant to seperate the" option "from the duration."
        print "You likely have a colon in your argument for" flag
        exit 1
    } else {
        exit 0
    }
}'
  fail=$? # this should get the exit code that awk gives.
  if [[ "$fail" -eq 1 ]]; then
    exit
  else
    if [ -z "$arg1" ] || [ -z "$arg2" ]; then
      echo_red "Error: $flag requires two arguments ($arg1_label and DURATION)."
      exit 1
    fi
  fi
}
check-focus() {
  local file="$1"
  local hash="52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971"
  local up_to_date_info genesis period drand_failed=false
  case "$file" in
  w | W | -w | -W | add-website)
    file="/etc/website-focus.txt"
    ;;
  a | A | -A | -a | add-process)
    file="/etc/process-focus.txt"
    ;;
  F | f | -f | -F | add-file)
    file="/etc/file-focus.txt"
    ;;
  *)
    echo "Not valid flag"
    exit 1
    ;;
  esac

  if up_to_date_info=$(curl -sf "https://api.drand.sh/${hash}/info"); then
    genesis=$(echo "$up_to_date_info" | awk -F '[":,]' '{print $14}')
    period=$(echo "$up_to_date_info" | awk -F '[":,]' '{print $10}')
  else
    drand_failed=true
  fi

  if [[ "$drand_failed" == "true" || -z "$genesis" || -z "$period" ]]; then
    # these are the likely defaults.
    genesis="1692803367"
    period="3"
  fi

  local line round_to_end epoch selected_end current_epoch time_diff
  current_epoch=$(date +%s)

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    round_to_end=$(awk -F '"' '{print $4}' <<<"$line")
    [[ -z "$round_to_end" ]] && continue

    epoch=$((((round_to_end - 1) * period) + genesis))
    selected_end=$(date -d "@$epoch" "+%X %x")
    time_diff=$((epoch - current_epoch))

    time_left "$time_diff"

    if [[ -n "$selected_end" ]]; then
      echo "Ends at $selected_end ($result remaining)"
    fi
  done <"$file"
}
display_sites_with_N() {
  select url in $(curl -s http://localhost:9222/json/list | awk -F '"' '/"url": "https?:\/\// { sub(/^https?:\/\//, "", $4); print $4 }'); do
    echo "You selected: $url"
    echo -e " Format Examples:"
    echo -e "    \033[1m'3 min'\033[0m           ends the focus in 3 minutes"
    echo -e "    \033[1m'3 days 2 hours'\033[0m  ends the focus in 3 days and 2 hours"
    echo -e "    \033[1m'3 friday'\033[0m        ends the focus 3 fridays from now"
    echo -e "    \033[1m'sunday'\033[0m          ends the focus the next sunday"
    echo -e "    \033[1m'tomorrow 12am'\033[0m   ends the focus at 12:00 AM tomorrow"
    read -rp "Enter a time (in natural language) to unblock $url:" "time_given"
    multi_flag_error_check "--add-website" "WEBSITE" "$url" "$time_given"
    add_X 'website' "$url" "$time_given"
    break
  done
}
check-sites() {
  curl -s http://localhost:9222/json/list | awk -F '"' '/"url": "https?:\/\// { sub(/^https?:\/\//, "", $4); print $4 }'
  # Source - https://stackoverflow.com/a/226724
  # Posted by Myrddin Emrys, modified by community. See post 'Timeline' for change history
  # Retrieved 2026-08-19, License - CC BY-SA 4.0

  echo "Do you want to temporarily block an open tab?"
  select strictreply in "Yes" "No"; do
    relaxedreply=${strictreply:-$REPLY}
    case $relaxedreply in
    Yes | yes | y)
      display_sites_with_N
      exit
      ;;
    No | no | n) exit ;;
    esac
  done

}
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
# don't add all of these binaries on one line. add no text on the same line as the "binaries_to_allow=(" line. This will break the '-P, --privileges' option. Don't delete this comment.
binaries_to_allow=(
  "curl *" "jq *" "adb *" "bat *" "blkid *" "cat *" "chmod *" "docker-compose *" "du *" "flatpak *" "fuser *" "grep *" "journalctl *" "killall *" "ln *" "mv *" "nbfc *" "pkill *" "rm *" "rmpc *" "sensors-detect *" "sleep *" "ss *" "tailscale *" "tlp *" "tlp-stat *" "touch *" "ufw *" "systemctl status *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *" "systemctl status *" "systemctl is-active *" "systemctl list-units *" "systemctl list-unit-files *" "systemctl show *" "tee *" "visudo --check" "sed -i '/@includedir/{/@includedir /etc/sudoers.d/!d;}' /etc/sudoers" "chattr +i /etc/sudoers" "chattr +i /etc/sudoers.d" "chattr +i /etc/sudoers.d/90-allowed-commands")
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
  readarray <"$HOME/CTCT/vivaldimods_output.txt" -t new_host_entries
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
backup_timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
readonly backup_timestamp
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

main() {
  check_dependencies
  check_overwritten
  set -eEu
  # Start of script
  # I am contemplating simplifying the script by turning the \
  # for commands in "${commands[@]}"
  # if <command>; then
  # reverse_operation+=("<reverse_command>")
  # else
  #	perform_rollback
  # fi

  echo_red "Checking that user can run sudo"
  sudo -vk || exit_cleanly # to ensure that the user has sudo privileges and can run sudo?. Probably will make this more better by ensuring the user can run sudo on all commands neccessary for this script to run

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
  if [[ $EDIT_SITE == "true" ]]; then
    edit_sites
  fi
  if [[ $EDIT_BLOCKLIST == "true" ]]; then
    edit_blocklists
  fi
  up_to_date_JS
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
  verify_date_syntax() {
    formatted_date=$(date -d "$ending" "+%m/%d/%y %H:%M:%S")
    epoch_formatted_date=$(date -d "$ending" +%s 2>/dev/null)
    today=$(date -d today +%s)
    if [ "$formatted_date" != "$ending" ] || [ "$epoch_formatted_date" -lt "$today" ]; then
      DATE_MANUAL=false
      echo "DATE FLAG HAS BEEN REJECTED"
      echo "formatted_date:"
      echo "$formatted_date"
      echo "epoch_formatted_date"
      echo "$epoch_formatted_date"
      echo "today"
      echo "$today"
      countdown 15
    fi
  }
  if [[ ! -z "$ending" ]]; then # if it is not empty at this point, flag was used
    verify_date_syntax
  fi
  select_end() {
    echo_red "Select a date to stop focussing..."
    echo "Click enter to continue"
    countdown 10
    set +x
    #selected_end_date=$(dialog --clear --erase-on-exit --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Ending Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
    selected_end_date=$(dialog --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Ending Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
    dialog --infobox "You picked ${selected_end_date:-nothing}" 0 0
    if [[ "$restore_state" == "set -o xtrace" ]]; then
      set -x
    fi

    countdown 10
    echo_red "Select a time to end the script..."
    set +x
    #selected_end_time=$(dialog --erase-on-exit --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
    selected_end_time=$(dialog --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
    dialog --infobox "You picked ${selected_end_time:-nothing}" 0 0
    if [[ "$restore_state" == "set -o xtrace" ]]; then
      set -x
    fi
    countdown 5
    # clear
  }
  echo "DEBUG: DATE_MANUAL is currently '$DATE_MANUAL'"
  if [ "$DATE_MANUAL" == false ]; then
    select_end
    ending="$selected_end_date $selected_end_time"
  fi
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

  if [[ ! -e "$HOME/go/bin/tle" ]]; then
    echo_red "tle wasn't installed"
    perform_rollback
  fi

  while true; do # allows the user infinite tries to put a time and date which is valid
    round=$((((ending_epoch - genesis) / period) + 1))
    "$HOME/go/bin/tle" -e -c "$hash" -r "$round" -o "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt"
    if [[ ! -s "$HOME/GRUB_PASSWORD-KEEP_SAFE.lock" ]]; then
      echo_red round "$round" is in the past. Try again
      DATE_MANUAL=false
      TIME_MANUAL=false
      select_end
      ending="$selected_end_date $selected_end_time"
      ending_epoch=$(date -d "$ending" +%s)
    else
      reverse_operation+=("undo_tle_lock")
      shred "$HOME/GRUB_PASSWORD-KEEP_SAFE.txt"
      break
    fi
  done

  # Immutable File; last step
  for file in "${important_files_to_create[@]}"; do
    sudo touch "$file"
  done
  immuting "important_files"
  immuting "applied_vivaldi_mods" "/opt/vivaldi/resources/vivaldi/"
  immuting "important_files_to_append" "" "a"

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

  immuting "important_files2"
  mv "$HOME/CTCT" "$HOME/.local/share/Trash/files/CTCT_${backup_timestamp}"
  echo -e "\033[38;2;124;252;0m Completed Script \033[0m"
}

EDIT_SITE=false
SHOW_PASSWORD=false
VALIDATEOPT=0
FIXOPT=0
PRIVILEGEOPT=0
PRINTPRIVILEGESOPT=0
SITESOPT=0
BLOCKLISTOPT=0
DECRYPTOPT=0
SHOWPASSWORDOPT=0
EDIT_BLOCKLIST=false
DATE_MANUAL=false

while true; do
  case "$1" in
  -v | --validate)
    VALIDATEOPT=1
    shift
    ;;
  -f | --fix)
    FIXOPT=1
    shift
    ;;
  -P | --privileges)
    PRIVILEGEOPT=1
    PRIVILEGE_ARG="$2"
    shift 2
    ;;
  -p | --print-privileges)
    PRINTPRIVILEGESOPT=1
    shift
    ;;
  -S | --sites)
    SITESOPT=1
    EDIT_SITE=true
    CUSTOM_SITES+=("$2")
    shift 2
    ;;
  -b | --blocklist)
    BLOCKLISTOPT=1
    EDIT_BLOCKLIST=true
    CUSTOM_BLOCKLISTS+=("$2")
    shift 2
    ;;
  -d | --date)
    DATEOPT=1
    DATE_MANUAL=true
    ending="$2"
    shift 2
    ;;
  -w | --add-website)
    IFS=':' read -r ADDWEBSITE_ARG ADDWEBSITE_ARG2 <<<"$2"
    ADDWEBSITEOPT=1
    multi_flag_error_check "--add-website" "WEBSITE" "$ADDWEBSITE_ARG" "$ADDWEBSITE_ARG2"
    shift 2
    ;;
  -a | --add-process)
    IFS=':' read -r ADDPROCESS_ARG ADDPROCESS_ARG2 <<<"$2"
    ADDPROCCESSOPT=1
    multi_flag_error_check "--add-process" "PROCESS" "$ADDPROCESS_ARG" "$ADDPROCESS_ARG2"
    shift 2
    ;;
  -F | --add-file)
    IFS=':' read -r ADDFILE_ARG ADDFILE_ARG2 <<<"$2"
    ADDFILEOPT=1
    multi_flag_error_check "--add-file" "FILE" "$ADDFILE_ARG" "$ADDFILE_ARG2"
    shift 2
    ;;
  -c | --check-current-focus)
    CHECKCURRENTFOCUSOPT=1
    FLAG="$2"
    shift 2
    ;;
  -t | --show-tabs)
    SHOWTABSOPT=1
    shift
    ;;
  -D | --decrypt)
    DECRYPTOPT=1
    shift
    ;;
  -s | --show-password)
    SHOWPASSWORDOPT=1
    SHOW_PASSWORD=true
    shift
    ;;
  -h | --help)
    print_help
    exit
    ;;
  --)
    shift
    break
    ;;
  *)
    break
    ;;
  esac
done
# Claude's idea on how to ensure the flags are standalone without writing the same code for each standalone flag
mutually_exclusive_flags=("$VALIDATEOPT" "$FIXOPT" "$PRIVILEGEOPT" "$PRINTPRIVILEGESOPT" "$SITESOPT" "$BLOCKLISTOPT" "$DECRYPTOPT" "$SHOWPASSWORDOPT" "$ADDWEBSITEOPT" "$ADDPROCCESSOPT" "$ADDFILEOPT" "$DATEOPT" "$TIMEOPT" "$CHECKCURRENTFOCUSOPT" "$SHOWTABSOPT")

total_set=0
for opt in "${mutually_exclusive_flags[@]}"; do
  ((opt == 1)) && ((++total_set))
done
standalone_values=("$VALIDATEOPT" "$FIXOPT" "$PRIVILEGEOPT" "$PRINTPRIVILEGESOPT")
standalone_names=("--validate" "--fix" "--privileges" "--print-privileges")
for i in "${!standalone_values[@]}"; do
  if [[ "${standalone_values[$i]}" -eq 1 && $total_set -gt 1 ]]; then
    echo "${standalone_names[$i]} is meant to be used on it's own"
    exit 2
  fi
done
if [[ $SHOWPASSWORDOPT -eq 1 && $DECRYPTOPT -eq 0 ]]; then
  echo "--decrypt is to be used with --show-password"
  exit 2
fi

other_opts_set=$((total_set - DECRYPTOPT - SHOWPASSWORDOPT))
if [[ $DECRYPTOPT -eq 1 && $other_opts_set -gt 0 ]]; then
  echo_red "--decrypt (with optional --show-password) is to be used on its own"
  exit 2
fi

if [[ $VALIDATEOPT -eq 1 ]]; then
  check_dependencies
  check_overwritten
  exit
fi
if [[ $FIXOPT -eq 1 ]]; then
  fix_overwritten
  fix_dependencies
  exit
fi
if [[ $PRIVILEGEOPT -eq 1 ]]; then
  edit_privileges "$PRIVILEGE_ARG"
  exit
fi
if [[ $PRINTPRIVILEGESOPT -eq 1 ]]; then
  print_binaries_to_allow
  exit
fi
if [[ $DECRYPTOPT -eq 1 ]]; then
  decrypt
  exit
fi
if [[ "$ADDWEBSITEOPT" -eq 1 ]]; then
  if [[ -e /etc/systemd/system/CTCT.target.wants/closetabs.service ]]; then
    add_X 'website' "$ADDWEBSITE_ARG" "$ADDWEBSITE_ARG2"
  fi
  exit
fi
if [[ "$ADDPROCCESSOPT" -eq 1 ]]; then
  if [[ -e /etc/systemd/system/CTCT.target.wants/closetabs.service ]]; then
    add_X 'process' "$ADDPROCESS_ARG" "$ADDPROCESS_ARG2"
  fi
  exit
fi
if [[ "$ADDFILEOPT" -eq 1 ]]; then
  if [[ -e /etc/systemd/system/CTCT.target.wants/closetabs.service ]]; then
    add_X 'file' "$ADDFILE_ARG" "$ADDFILE_ARG2"
  fi
  exit
fi
if [[ $CHECKCURRENTFOCUSOPT -eq 1 ]]; then
  check-focus "$FLAG"
  exit
fi

if [[ $SHOWTABSOPT -eq 1 ]]; then
  display_sites_with_N
  exit
fi
main
exit
