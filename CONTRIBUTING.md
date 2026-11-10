<p align="center">
  <img src="https://img.shields.io/github/last-commit/MrSavageBanana/CTCT?color=teal&style=for-the-badge">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-success?style=for-the-badge">
  <img src="https://img.shields.io/github/commit-activity/y/MrSavageBanana/CTCT?color=teal&style=for-the-badge">
</p>
<h1 align="center">Contributing</h1>
<a id="contribute-toc"></a>
  <div align="center">
    <a href="#what_should_i_know_before_i_get_started">What should I know before I get started?</a>
    <span> · </span>
    <a href="#how_do_i_contribute">How do I Contribute?</a>
  </div>
  <br>


Even if you have little to no experience with Bash, I'll be more than happy to help :)

## I don't want to read this whole thing I just have a question!!! <a id=i-dont-want-to-read-this-whole-thing-i-just-have-a-question></a>
<!-- We have an official message board and a FAQ. See&nbsp;[below](#other-resources) -->
We have an official message board. See&nbsp;[below](#other-resources)
<a id="other-resources"></a>
[GitHub Discussions](https://github.com/MrSavageBanana/CTCT/discussions/categories/ideas-feature-requests?discussions_q=is%3Aopen+category%3A%22Ideas%2FFeature+Requests%22), the official CTCT message&nbsp;board
<!-- [CTCT FAQ](https://github.com/MrSavageBanana/CTCT#faq) -->

> [!NOTE]
> Please don't file an issue to ask a question. You'll get faster results by using the resource above.
> If the answer isn't in the resource above, open a [discussion](https://github.com/MrSavageBanana/CTCT/discussions/new/choose) or an [issue](https://github.com/MrSavageBanana/CTCT/issues/new/choose)
<!-- > Please don't file an issue to ask a question. You'll get faster results by using the resources above. -->
<!-- > If the answer isn't in the resources above, open a [discussion]() -->
## What should I know before I get started? <a id="what_should_i_know_before_i_get_started"></a>
### Philosophy <a id="coding_philosophy"></a>
- It is meant to be impossible to stop while it is running. Meaning if you set it up correctly with the [right privileges and blocklists](https://github.com/MrSavageBanana/CTCT/wiki/how-to-set-up-CTCT-correctly), there should be NO WAY to stop until the timer is done
- The user shouldn't NEED to think of a command to solve a (common) problem. Everything they need should be copy and paste from the repo (like the [ requirements table](https://github.com/MrSavageBanana/CTCT#requirements)) or in the -h option

### What to avoid?:
- Huge bl<b>a</b>cklists (other then the website blocklist. it is super hard to categorize a website and [StevenBlack](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts) already has an established list)
- Other programming languages other then bash unless a valid reason. Speed (for the sake of speed) is not a valid reason.
- Adding dependencies

## How do I Contribute? <a id="how_do_i_contribute?"></a>
<a id="contribute-toc2"></a>
  <div align="center">
    <a href="#feature_requests">Feature Requests</a>
    <span> · </span>
    <a href="#issues">Issues</a>
    <span> · </span>
    <a href="#open-problems">Open Problems</a>
    <span> · </span>
    <a href="#checking_your_work">Checking Your Work</a>
    <span> · </span>
    <a href="#ai_use_policy">AI usage policy</a>
    <span> · </span>
    <a href="#conventions">Conventions</a>
  </div>
  <br>

Thank you for your interest in contributing! Use the Table of Contents [above](#contribute-toc2) to navigate.

## Feature Requests <a id="feature_requests"></a>
- To avoid wasted effort, check if the feature has already been requested by [searching through GitHub Discussions](https://github.com/MrSavageBanana/CTCT/discussions). 
  * If the feature IS a duplicate,  upvote it by clicking the [+<img src="assets/smile-beam-svgrepo-com-black.svg" width="16" height="16" style="filter: invert(1);"> ] button and the <img src="assets/thumbs-up-svgrepo-com.svg" width="16" height="16" style="filter: invert(1);">. Avoid comments like "+1" or "me too" as they clutter the discussion and make it harder to prioritize requests.
- Requesting new features, questions or discussions about new features belong on [GitHub Discussions](https://github.com/MrSavageBanana/CTCT/discussions). Avoid putting them in [Issues](https://github.com/MrSavageBanana/CTCT/issues).

**The issue tracker is not for feature requests**

- Once you have at least proposed the feature on GitHub Discussions, you may submit a PR. Follow [the brief requirements for PR.](#pull_requests_pr)

- Additionally, I reserve the right to reject any features which I do not think belong in CTCT.

Requesting a feature is no guarantee it will be added.

## Pull Requests (PR) <a id="pull_requests_pr"></a>
- DO submit all code changes via pull requests (PRs) rather than through a direct commit. PRs will be reviewed and potentially merged after a peer review

- DO submit a separate PR for every code issue. DO NOT make seven separate changes and submit as one PR.

- DO NOT submit "work in progress" PRs. A PR should only be submitted when it is considered ready for review and subsequent merging by the contributor.

- Do NOT submit feature requests which change core functionality without [discussing](https://github.com/MrSavageBanana/CTCT/discussions/new/choose) first.

- DO NOT make large PRs.

## Issues <a id="issues "></a>

### Working on issues <a id="working_on_issues"></a>
Please feel free to take on any issue [that's currently open]. Feel free to resolve any issue that you would enjoy working on even if it happens to be a low priority.

<!-- TODO: gotta add the booting into another Linux distro as a currently open bug -->
### Indicating interest in issues <a id="indicating_interest_in_issues"></a>
Upvote issues you deem important by clicking the [+😊] button and the 👍. Avoid comments like "+1" or "me too" as they clutter the discussion and make it harder to prioritize requests.
### Writing Good Bug Reports <a id="writing_good_bug_reports"></a>
 Please include the following with each issue (run [the code](#bug-report) to automatically get **most** of these. <br>'*' indicates what cannot be automatically discovered)
- *A description of the issue
- *What you expected to see
- *How to reproduce (if known)
- Your Operating System
- Bash version
- Version of each dependency
- *Terminal Output
- *Screenshots or a screen recording showing the issue occurring
  (**ONLY** if issue is outside of terminal output)
- *Log file (automatically created when you don't use -x flag)
<details>
<summary><h4><a id="bug-report"></a>Get This Information Automatically</h4></summary>

```bash
# Print Operating System
while IFS='=' read -r key val; do
       case $key in
       PRETTY_NAME) distro=$val ;;
       esac
   done </etc/os-release
echo "$distro"
# Bash version
bash --version
# Version of each dependency
deps=(
  "flock" "grub-mkpasswd-pbkdf2" "sed" "date" "rm" "mv" "sudo" "mkdir" "cp" "tee" "grub-mkconfig" "cat" "awk" "git" "grep" "curl" "systemctl" "grep" "tar" "diff" "find" "md5sum" "sort" "bash" "tr" "fold" "head" "shred" "whoami" "basename" "pgrep" "xargs" "uniq" "file" "strace" "vivaldi" "pacman" "hashcat")
# kill, chpasswd, and chattr do not have a version flag
for dep in "${deps[@]}"; do
  echo "$dep version"
  "$dep" --version | head -n 1
done
echo 'Dialog version'
dialog --version
echo 'Pacman version'
pacman --version | head -n 2
```
</details>

## Open Problems <a id= "open-problems"></a>
- There are some problems in CTCT.sh which can always be improved. They are listed below along. Click them to see previous attempts and their results
<!-- TODO: add these open problems -->
<!-- somewhere along /docs/open-problems/*.md -->

## Checking Your Work <a id="checking_your_work"></a>
Before submitting your work, do the following:
1. run bash -n
```bash
bash -n <script> && echo $?
```
If the above command doesn't print 0, you have errors. Fix them.

2. run Shellcheck. Install [here](https://github.com/koalaman/shellcheck)
```bash
shellcheck --severity=info --check-sourced <script>
```
fix any errors you see

3. standard testing of every flag. Ensure that each flag works as expected

> [!TIP]
> I am working on an automated way to run tests and give the results using docker or a headless virtual machine
> You can [get notified](https://github.com/MrSavageBanana/CTCT/issues/8) when it is ready

## AI use policy <a id="ai_use_policy"></a>
### When using AI for understanding the code
- Keep in mind that while AI assistants help with navigating and understanding the code base, you need to take their claims with a grain of salt.
- Using AI tools doesn't prevent you from becoming familiar with the code and the development workflow.
### When using AI for communication <a id="when_using_ai_for_communication"></a>
- Avoid verbose descriptions, provide enough information to understand the request but do not add unrelated details.
### When using AI for code contribution <a id="when_using_ai_for_code_contribution"></a>
- Cite AI when used.
- You are responsible for the code you contribute. You cannot blame an AI for code. Citing an AI doesn't excuse bad code (eg: Used Claude to ...; ChatGPT said ... )
- You must be able to explain the what, why and how of the change without help from the AI tool. This is to ensure that there is no redundant code. 

These rules **aren't against AI**. 
They are there to ensure there is no vibe coding because CTCT effects delicate parts of user's systems.
## Conventions <a id="conventions"></a>
The conventions of the code depends on the file.
The structure of the files that will be updated the most are below:
<details>
<summary><h3><a id="ctct-sh"></a>CTCT.sh</h3></summary>
The main script.

#### In General
1. Avoid adding more dependencies if possible. Code changes made to remove dependencies are encouraged. 
2. Avoid repeated pipes if possible.
3. Avoid echoing messages if possible. Doesn't apply to failed commands
4. use echo_red only if it is something the user should act on.

#### Helper Variables and Arrays (lines )
- these are variables that are used very commonly so makes sense to always initialize them
#### Helper functions (lines )
- these are all functions other than the main function
#### Rollback Functions (lines )
- these are functions that are used **only** in the main function and **only** to rollback a command if it failed.
#### Main function (lines )
- Any command effecting the user's system **must** be wrapped in the following logic
```bash
if <command>; then
    reverse_operation+=("<undo_command_function>")
else 
    perform_rollback
fi
```
If the command works, it's rollback function is added to the reverse_operation array
The rollback function must undo what the command did. This means that the command must be undoable.
If the command fails, perform_rollback is run, running all of the rollback functions in reverse order
<insert gif of the man going backwards>

<details>
<summary><h4><a id="The flag logic (lines )"></a>The flag logic (lines )</h4></summary>

- The Initial variables for each flag. Boolean logic. Set to the equivalent of 'false'
- the case logic for each flag
  - when a flag is chosen, the variable is set to the equivalent of 'true'
    ```bash
    -s | --long-option)
    FLAG=TRUE
    shift
    ;;
    ```
  - if the flag accepts a parameter, end the flag with shift 2
    ```bash
    -s | --long-option)
    FLAG=TRUE
    shift 2
    ;;
    ```
  - if the flag is allowed to be called multiple times in the same command (eg:`CTCT.sh --flag --flag --flag`) without overwriting the arguments to the previous calls, use the following logic
    ```bash
    -s | --long-option)
        FLAG=TRUE
        FLAG_ARRAY+=("$2")
        shift 2
        ;;
    ```
- if the flag is meant to be used on it's own,
    * add it to mutually_exclusive_flags array
    * add the variable and flag to standalone_values and standalone_names respectively
- If the flag is meant to be used on it's own AND with another flag, **add** the following logic
  ```bash
  if [[ $FlagOneVariable -eq 1 && $FlagTwoVariable -eq 0 ]]; then
    echo "--FlagTwo is to be used with --FlagOne"
    exit 2
  fi
  ```
  
  - If the flag is meant to be used on it's own AND **only** with another flag, **add** the following logic
  ```bash
  other_opts_set=$((total_set - FlagTwoVariable - FlagOneVariable))
  if [[ $FlagTwoVariable -eq 1 && $other_opts_set -gt 0 ]]; then
    echo_red "--FlagTwo (with optional --FlagOne) is to be used on its own"
    exit 2
  fi
  ```

- The if Statements
  - using the variable set to true as the condition, run the commands in the flag
  - if the flag is meant to not run with the main function, end the if with the 'exit' command
</details>

#### FAQ
##### Why is the script randomly exiting? Nothing failed
You likely hit the set -e. A command might not have failed but instead returned a return code of 1. 
Common solution:
Add '|| true' after the command that returns 1. 
##### Why is this so many lines?
The real script is the main function (~400 lines)
The rest of the script is to handle errors and ensure the user doesn't have to touch the command line to do repeated actions (like decrypting)
</details>
<details>
<summary><h3><a id="matt-damon-sh"></a>matt_damon.sh</h3></summary>
The root daemon
<!-- get it? 'daemon' sounds like 'damon' -->

#### In General
1. Avoid adding more dependencies if possible. Code changes made to remove dependencies are encouraged. 
2. Avoid repeated pipes if possible.
3. Use verbose echoing so a user can search the journalctl logs if needed.
</details>
</details>
