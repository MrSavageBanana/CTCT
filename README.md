<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-success?style=for-the-badge">
  <img src="https://img.shields.io/github/license/MrSavageBanana/CTCT?style=for-the-badge">
  <!-- until this gets stars, i probably shouldn't just advertise my zero stars lol -->
  <!-- <img src="https://img.shields.io/github/stars/MrSavageBanana/CTCT?style=for-the-badge"> -->
  <!-- <img src="https://img.shields.io/github/forks/MrSavageBanana/CTCT?color=teal&style=for-the-badge"> -->
  <img src="https://img.shields.io/github/issues/MrSavageBanana/CTCT?color=violet&style=for-the-badge">
</p>

<div align="center">
<!-- Credit to https://patorjk.com/software/taag/#p=display&f=Big%20Money-nw&t=CTCT&x=none -->
<pre>
 $$$$$$\ $$$$$$$$\  $$$$$$\ $$$$$$$$\ 
$$  __$$\\__$$  __|$$  __$$\\__$$  __|
$$ /  \__|  $$ |   $$ /  \__|  $$ |   
$$ |        $$ |   $$ |        $$ |   
$$ |        $$ |   $$ |        $$ |   
$$ |  $$\   $$ |   $$ |  $$\   $$ |   
\$$$$$$  |  $$ |   \$$$$$$  |  $$ |   
 \______/   \__|    \______/   \__|   
</pre>
  <strong>A REALLY strong Website Blocker</strong>
  <br>
  <br>
  <div align="center">
    <a href="#quick-start">Quick Start</a>
    <span> · </span>
    <a href="#usage">Usage</a>
    <span> · </span>
    <a href="#contributing">Contributing</a>
  </div>
  <br>
  <br>
</div>


### What is CTCT not?
- a screen time usage tracker
- a website blocker with scheduled downtime
- a website blocker that lets you turn off restrictions
## Requirements & Dependencies 
#### Requirements (7) <a id="requirements"></a>
<table>
<thead>
<tr>
<th>Requirement</th>
<th>How to check</th>
<th>How to Fix</th>
</tr>
</thead>
<tbody>

<tr></tr>
<tr>
<td>Using Linux</td>
<td>

if running the following command says "Linux"
```bash
uname
```
</td>
<td>

Switch to Linux <br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/1) when your OS is supported

</td>
</tr>
<tr></tr>
<tr>
<td>Linux Distro is systemd based</td>
<td>

if running the following command says systemd
```bash
ps --no-headers -o comm 1
```

</td>
<td>

Switch to a Systemd Distro <br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/2) when your init system is supported

</td>
</tr>

<tr></tr>
<tr>
<td>Using GRUB</td>
<td>
<hr>
</td>
<td>

Switch to GRUB <br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/3) when your boot loader is supported

</td>
</tr>
<tr></tr>
<tr>
<td> A single user system</td>
<td>

if running the following command says 1
```bash
getent passwd |
awk -F: '$3 >= 1000 && $3 <= 60000' |
wc -l
```

</td>
<td>

Delete all users except 1 <br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/4) when multi-user is supported

</td>
</tr>
<tr></tr>
<tr>
<td>

[Vivaldi](https://vivaldi.com) is your daily browser
</td>
<td>
<hr>
</td>
<td>

Make [Vivaldi](https://vivaldi.com/download/) your daily browser<br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/5) when your browser is supported
</td>
</tr>

<tr></tr>
<tr>
<tr></tr>
<tr>
<td>

Sudo is your only privilege escalation tool

</td>
<td>
<hr>
</td>
<td>

Switch to sudo<br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/6) when your privilege escalation tool is supported
</td>
</tr>

<tr></tr>
<tr>
<tr></tr>
<tr>
<td>

Using Arch Linux

</td>
<td>
If running the following says "Arch Linux"

```bash
grep -oP "^PRETTY_NAME=[\"']\K[^\"']+" /etc/os-release

```
<td>

Switch to Arch Linux<br>OR<br> [get notified](https://github.com/MrSavageBanana/CTCT/issues/7) when your distro is supported
</td>
</tr>


</tbody>
</table>

<br>

#### Dependencies
> [!TIP]
> The script will warn you if you are missing any of the [dependencies](#all-dependencies)
> If you meet all the [requirements](#requirements), proceed to [quick start](#quick-start)
<details> 
<summary><h4><a id="all-dependencies"></a>All Dependencies (50)</h4></summary>

 1. systemctl
 2. grub-mkpasswd-pbkdf2
 3. grub-mkconfig
 4. vivaldi
 5. file
 6. bash
 7. grep
 8. date
 9. rm
10. mv
11. sed
12. mkdir
13. cp
14. tee
15. cat
16. md5sum
17. sort
18. tr
19. fold
20. head
21. shred
22. whoami
23. basename
24. uniq
25. curl
26. sudo
27. kill
28. awk
29. git
30. chpasswd
31. chattr
32. tar
33. diff
34. find
35. pgrep
36. xargs
37. pacman
38. flock
39. dialog
40. strace
41. hashcat
42. getopt
43. lsattr
44. visudo
45. su
46. unlink
47. mktemp
48. seq
49. go
50. tle

</details>


## Quick Start <a id="quick-start"></a>
> [!WARNING]
> Read [the script](https://github.com/MrSavageBanana/CTCT/blob/main/CTCT.sh#L1114) 
> Know what it does to your system
<details>
<summary>
<h3 style="display: inline-flex; align-items: center; gap: 8px; margin: 0;">
  <a href="#on-linux">
    <img src="assets/tuxed.png" width="30" height="36" align="absmiddle" alt="Tux">
  </a>
    &nbsp;On Linux <a id="on-linux"></a>
</h3></summary>
Download the script on your computer:

```bash
curl https://raw.githubusercontent.com/MrSavageBanana/CTCT/main/heads/CTCT.sh > CTCT.sh
```
**Read** [**the script!:**](https://github.com/MrSavageBanana/CTCT/blob/main/CTCT.sh#L1114)
```bash
less CTCT.sh
```
After you read the script and approve, go to [Usage](#usage)
</details>


## Usage <a id="usage"></a>
Get started interactively:
```bash
bash CTCT.sh 
```
See all options at a glance:
```bash 
bash CTCT.sh -h
```

<details>
<summary><h3>All Options</h3></summary>
<table>
<thead>
<tr>
<th>Command</th>
<th>Description</th>
</tr>
</thead>
<tbody>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --validate
```

</td>
<td>Check for file conflicts and missing dependencies</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --fix
```

</td>
<td>Install missing dependencies and move overwritten files to $HOME/.local/share/Trash/files/</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --privilege
```

</td>
<td>Add binary you want to be able to run all commands with sudo and exit</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --print-privileges
```

</td>
<td>Print privileges to screen and exit</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --site
```

</td>
<td>Add site to be blocked</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --blocklist
```

</td>
<td>

Add a [stevenblack](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants) blocklist to add to hosts

</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --date
```

</td>
<td>Add a date to end the focus.<br>Format: MM/DD/YY HH:MM:SS</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --add-website
```

</td>
<td>

Add a website to be blocked for some time<br>(see [DURATION](#duration-format) below)

</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --add-process
```

</td>
<td>

Add a process to be blocked for some time <br>(see [DURATION](#duration-format) below)

</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --add-file
```

</td>
<td>

Add a file or directory to be uneditable for some time<br>(see [DURATION](#duration-format) below)</td>

</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --check-current-focus
```

</td>
<td>Print remaining time for active focus sessions.<br>FLAG must be 'a', 'F', 'w', or their full names</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --check-all-focus
```

</td>
<td>Print remaining time for all focus sessions.</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --add-js-script
```

</td>
<td>Add a custom JS file to be loaded into Vivaldi</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --brute-force
```

</td>
<td>Attempt to brute-force the GRUB root password hash using Hashcat</td>
</tr>
<tr></tr>
<tr>
<td>

```bash
CTCT.sh --show-tabs
```

</td>
<td>Display open tabs with an interactive menu to temporarily block sites</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --decrypt
```

</td>
<td>Decrypt password and prompt to change it</td>
</tr>

<tr></tr>
<tr>
<td>

```bash
CTCT.sh --show-password
```

</td>
<td>To be used with --decrypt.<br>Shows new password user types when changing</td>
</tr>


</tbody>
</table>

**DURATION FORMAT** <a id="duration-format"></a>
DURATION uses natural language to specify how long the focus lasts.
&nbsp;&nbsp;Examples:
&nbsp;&nbsp;&nbsp;&nbsp;**'3 min'**           ends the focus in 3 minutes
&nbsp;&nbsp;&nbsp;&nbsp;**'3 days 2 hours'**  ends the focus in 3 days and 2 hours
&nbsp;&nbsp;&nbsp;&nbsp;**'3 friday'**        ends the focus 3 fridays from now
&nbsp;&nbsp;&nbsp;&nbsp;**'sunday'**          ends the focus the next sunday
&nbsp;&nbsp;&nbsp;&nbsp;**'tomorrow 12am'**   ends the focus at 12:00 AM tomorrow

</details>

### Feature Showcase
| | Feature
|:----------------------------------------------- |:------------------------------------ 
| | Remove distraction without browser extensions
| | Closes blocked websites even with VPN
| | Block any other app.
| | close other browsers
| | make files uneditable. Useful for dotfiles.


## Roadmap
These are features that are planned on being added. 
Of course, fixing bugs comes first. 

### Soon:
- Add support for more browsers
- Add a configuration file to make more reproducible
- Add support for Windows
### Later in the roadmap:
- Add support for multi-users in Linux
- Add support for multi-users in Windows
- Add support for MacOS
- Add support for other init system
- Add support for other other bootloaders
- Add support for other privilege escalation
- Make it pretty. Likely using [beddu](https://github.com/mjsarfatti/beddu)

## Contributing <a id="contributing"></a>
Have a feature request? Start a discussion by clicking [here](https://github.com/MrSavageBanana/CTCT/discussions/new?category=ideas-feature-requests)
Found a bug? Click [here](https://github.com/MrSavageBanana/CTCT/issues/new?template=bug_report.yml) to submit
If my code sucks, looks bad or poorly designed please [open an issue](https://github.com/MrSavageBanana/CTCT/issues/new/choose) and let me know!

See [CONTRIBUTING](https://github.com/MrSavageBanana/CTCT?tab=contributing-ov-file) for more details if needed (1-5 min read)

Consider giving the repository a star <img src="assets/star.png" width="16" height="16" style="filter: invert(1);">

[Back to top](#top)
