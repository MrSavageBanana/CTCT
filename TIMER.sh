#!/usr/bin/env
pick_date(){
	selected_start_date=$(dialog --clear --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Starting Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
	echo "select a date to end the script"
	selected_end_date=$(dialog --clear --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Ending Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
	echo "select a time to start the script"
	selected_start_time=$(dialog --clear --title "Select a Time" --timebox "Choose Starting Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
	echo "select a time to end the script"
	selected_end_time=$(dialog --clear --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
}
# echo "select a date to start the script"
#selected_start_date=$(dialog --clear --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Starting Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
selected_start_date="07/04/26"
# echo "select a date to end the script"
# selected_end_date=$(dialog --clear --date-format "%m/%d/%y" --title "Select a Date" --calendar "Choose Ending Date" 0 0 0 0 0 3>&1 1>&2 2>&3)
selected_end_date="07/06/26"
# echo "select a time to start the script"
#selected_start_time=$(dialog --clear --title "Select a Time" --timebox "Choose Starting Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
selected_start_time="10:00:00"
# echo "select a time to end the script"
# selected_end_time=$(dialog --clear --title "Select a Time" --timebox "Choose Ending Time" 0 0 0 0 0 3>&1 1>&2 2>&3)
selected_end_time="22:00:00"
# clear
starting="$selected_start_date $selected_start_time"
ending="$selected_end_date $selected_end_time"
starting_epoch=$(date -d "$starting" +%s)
ending_epoch=$(date -d "$ending" +%s)

if [[ $ending_epoch -le $starting_epoch ]]; then
	echo "Ending date OR time is before Starting date OR time. See Details below:"
	echo "starting date and time:"
	echo "$starting"
	echo "ending date and time:"
	echo "$ending"
	echo "Press enter to try again."; read _''
	pick_date
elif [[ $ending_epoch -ge $starting_epoch ]]; then
	echo "Start and Ending date and time are valid"
else
	echo "Invalid Date Validation. Inspect Variables Below"
	echo "starting date and time:"
	echo "$starting"
	echo "ending date and time:"
	echo "$ending"
	echo "starting date and time (seconds):"
	echo "$starting_epoch"
	echo "ending date and time (seconds):"
	echo "$ending_epoch"
fi
valid_starting=$(date -d "$selected_start_date $selected_start_time")
valid_ending=$(date -d "$selected_end_date $selected_end_time")
{
	echo "Starting Date:"
	echo "$valid_starting"
	echo "Ending Date:"
	echo "$valid_ending"
} >> SCHEDULED_CTCT.txt
