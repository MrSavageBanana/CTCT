#!/bin/bash
git clone https://github.com/MrSavageBanana/CTCT.git
cd CTCT || exit

# Service 
cp closetabs.service /etc/systemd/system
systemctl enable closetabs
mv --force matt_damon.sh /etc/
# Hooks
mkdir -p /etc/pacman.d/hooks.bin
mv --force vivaldimods.sh /etc/pacman.d/hooks.bin
mkdir -p /etc/pacman.d/hooks
mv --force vivaldiupdate.hook /etc/pacman.d/hooks
mv --force grub1.hook /etc/pacman.d/hooks
mv --force grub2.hook /etc/pacman.d/hooks
# Javascript
sudo pacman -S --needed vivaldi 
cd "Custom_Vivaldi_JS(AI)" || exit
# This array needs to be upgraded by making all files in Custom_Vivaldi_JS be in it, regardless of name
# If i decide to have the bundles of JS scripts as little packs, i will need to 
# 1. add the option to choose which pack and 
# 2. if the user has their own custom, they should be required to put the path to the directory 
# 3. if they don't have their directory yet, they can run the script with the arguments to the directory to add it in. 
JS_SCRIPTS=( 'reddit.js' 'reddit_hp' 'shorts.js' 'video.js' 'video.js' 'youtube.js' 'youtubeNU.js' ) 
mv  --force "${JS_SCRIPTS[@]}" /opt/vivaldi/resources/vivaldi
echo "Applying JS and hosts"
sudo bash /etc/pacman.d/hooks.bin/vivaldimods.sh

# This part is to help the user with running the correct flag for vivaldi without having to type. They can edit this freely as it shouldn't effect effectiveness
if [[ -e "$HOME/.local/share/applications/vivaldi-stable.desktop" ]]; then
	rm "$HOME/.local/share/applications/vivaldi-stable.desktop"
	cp vivaldi-stable.desktop /home/shayan/.local/share/applications
fi
mkdir -p "$HOME/.local/bin"
mv --force vivaldi-custom "$HOME/.local/bin"


# Edit /etc/sudoers
# This will need to get the users username
# I will likely allow the users to change what is given the sudo privileges but the script will check for what is absolutely not allowed to be given sudo privileges for this stuff to work.
# Might want to integrate a way to add a timer so the user can be given back the root privileges and the Grub password can be removed timer so the user can be given back the root privileges and the Grub password can be removed. 
# Remove Root privileges from the current user
# GRUB.sh to stop editing boot parameters
# Ask user to find someone to do the bootloader BIOS if we can find no way to create a BIOS password for any computer
# Talk to Claude for ideas on how to help the person if they have no one to trust with the bios. Least we can do is provide a quick, easy to run script that the user can oneshot into the command line and be rid of any distractions

# Immutable File
chattr +i /etc/hosts
chattr +i /etc/pacman.d/hooks/vivaldiupdate.hook
chattr +i /etc/pacman.d/hooks/grub1.hook
chattr +i /etc/pacman.d/hooks/grub2.hook
chattr +i /etc/pacman.d/hooks.bin/vivaldimods.sh chattr +i /etc/systemd/system/closetabs.service
chattr +i /etc/matt_damon.sh
chattr +i /etc/sudoers
chattr +i /etc/sudoers.d
for JS_SCRIPT in "${JS_SCRIPTS[@]}"; do
	chattr +i "$JS_SCRIPT"
done
