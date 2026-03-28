# CTCT
CTCT = Colder Than Cold Turkey

Steps (Rough)
0. Create the 
    1. daemon for closing tabs and ensuring vivaldi runs with remote-debugging-port
    3. auto repair hook (which should also check that the hosts hasn't been changed)
    4. host file filled with blocked domains
    5. javascripts 
1. Run the following commands to make the important files immutable:
    ```bash
    chattr +i /etc/hosts
    chattr +i /etc/pacman.d/hooks/vivaldiupdate.hook
    chattr +i /etc/pacman.d/hooks/grub1.hook
    chattr +i /etc/pacman.d/hooks/grub2.hook
    chattr +i /etc/pacman.d/hooks.bin/vivaldimods.sh
    chattr +i /etc/systemd/system/closetabs.service
    chattr +i /home/shayan/Downloads/Code/CTCT/Modules/matt_damon.sh # This is what i named the daemon that closetabs.service runs
    chattr +i /etc/sudoers
    chattr +i /etc/sudoers.d
    chattr +i /opt/vivaldi/resources/vivaldi/reddit.js
    chattr +i /opt/vivaldi/resources/vivaldi/reddit_hp.js
    chattr +i /opt/vivaldi/resources/vivaldi/posts.js
    chattr +i /opt/vivaldi/resources/vivaldi/search.js
    chattr +i /opt/vivaldi/resources/vivaldi/youtube.js
    chattr +i /opt/vivaldi/resources/vivaldi/shorts.js
    chattr +i /opt/vivaldi/resources/vivaldi/video.js
    ```
    1. You said "chattr +i" which wasn't confusing but i am hearing different numbers from you on chmod. Mode 644, 755
1. edit /etc/sudoers using visudo command
```txt
shayan All=(root)_NOPASSWD: /usr/bin/curl
shayan All=(root)_NOPASSWD: /usr/bin/jq
shayan All=(root)_NOPASSWD: /usr/bin/adb
shayan All=(root)_NOPASSWD: /usr/bin/bat
shayan All=(root)_NOPASSWD: /usr/bin/blkid
shayan All=(root)_NOPASSWD: /usr/bin/cat 
shayan All=(root)_NOPASSWD: /usr/bin/chmod
shayan All=(root)_NOPASSWD: /usr/bin/docker-compose 
shayan All=(root)_NOPASSWD: /usr/bin/du
shayan All=(root)_NOPASSWD: /usr/bin/flatpak
shayan All=(root)_NOPASSWD: /usr/bin/fuser
shayan All=(root)_NOPASSWD: /usr/bin/grep
shayan All=(root)_NOPASSWD: /usr/bin/journalctl 
shayan All=(root)_NOPASSWD: /usr/bin/killall
shayan All=(root)_NOPASSWD: /usr/bin/ln
shayan All=(root)_NOPASSWD: /usr/bin/make
shayan All=(root)_NOPASSWD: /usr/bin/micro
shayan All=(root)_NOPASSWD: /usr/bin/mv
shayan All=(root)_NOPASSWD: /usr/bin/nano 
shayan All=(root)_NOPASSWD: /usr/bin/nbfc
shayan All=(root)_NOPASSWD: /usr/bin/nvim
shayan All=(root)_NOPASSWD: /usr/bin/pacman 
shayan All=(root)_NOPASSWD: /usr/bin/pkill
shayan All=(root)_NOPASSWD: /usr/bin/rm
shayan All=(root)_NOPASSWD: /usr/bin/rmpc
shayan All=(root)_NOPASSWD: /usr/bin/sed
shayan All=(root)_NOPASSWD: /usr/bin/sensors-detect 
shayan All=(root)_NOPASSWD: /usr/bin/sleep
shayan All=(root)_NOPASSWD: /usr/bin/ss
shayan All=(root)_NOPASSWD: /usr/bin/systemctl
shayan All=(root)_NOPASSWD: /usr/bin/tailscale
shayan All=(root)_NOPASSWD: /usr/bin/tlp 
shayan All=(root)_NOPASSWD: /usr/bin/tlp-stat
shayan All=(root)_NOPASSWD: /usr/bin/touch
shayan All=(root)_NOPASSWD: /usr/bin/ufw 
shayan All=(root)_NOPASSWD: /usr/bin/yay
shayan All=(root)_NOPASSWD: /usr/bin/systemctl status
shayan All=(root)_NOPASSWD: /usr/bin/systemctl start
shayan All=(root)_NOPASSWD: /usr/bin/systemctl restart
shayan All=(root)_NOPASSWD: /usr/bin/systemctl enable
shayan All=(root)_NOPASSWD: /usr/bin/systemctl is-active
shayan All=(root)_NOPASSWD: /usr/bin/systemctl list-units
shayan All=(root)_NOPASSWD: /usr/bin/systemctl list-unit-files
shayan All=(root)_NOPASSWD: /usr/bin/systemctl show
shayan All=(root)_NOPASSWD: /usr/bin/systemctl status *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl start *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl restart *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl enable *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl is-active *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl list-units *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl list-unit-files *
shayan All=(root)_NOPASSWD: /usr/bin/systemctl show *
```
3. Remove Root privileges from me
4. Give Root Password to my "Guardian"
5. create grub password which will only show up on dualbooting to other OSs
 editing /etc/grub.d/40_custom
set superusers="linuxconfig"
password_pbkdf2 linuxconfig grub.pbkdf2.sha512...

where the password_pbkdf2 is obtained from 
sudo grub-mkpasswd-pbkdf2

then they can run:
sudo update-grub

which is the same as running: 
```bash
#!/bin/sh
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
```
6. Set bootloader BIOS password "Guardian"
