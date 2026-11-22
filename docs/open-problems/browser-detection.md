# browser detection
This is the current steps i have taken to attempt to find the browsers on a user's system

## .desktop files (introduced in #bc8e52b)
### Context:
In "/usr/share/applications/" and "$HOME/.local/share/applications/", there are .desktop files used to create desktop entries in application launchers
These entries usually have a Categories entry like so:
```.desktop
1. Categories=GNOME;GTK;Network;WebBrowser;
2. Categories=GNOME;Network;
3. Categories=GNOME;System;
4. Categories=Graphics;Viewer;
5. Categories=Network;RemoteAccess;
6. Categories=Network;WebBrowser;
7. Categories=Office;
8. Categories=Office;Viewer;
9. Categories=Office;WordProcessor
```

Browsers usually have "WebBrowser" in their Categories

### Solution:
we look through these directories for .desktop files containing Categories which contain "WebBrowser"

### Problem:
1. A browser developer may not include "WebBrowser" in their .desktop file. All it takes is a single browser to not do this to bypass CTCT. No browser must exist except CTCT
2. A user can edit .desktop files to remove this line. 
Especially when running appimages, a user could extract a appimage using the following
```bash
./browserappimage-x86_64.AppImage --appimage-extract
```
then edit the .desktop file in squashfs-root/browserappimage.desktop
then recompile the appimage using [appimagetool](https://github.com/AppImage/appimagetool) and run it and bypass CTCT

## browser engines (introduced in most recent commit)

### Context
browsers almost all use some browser engine like chromium, gecko, webkit, etc to run the browser
they expose this in the /proc/PID/maps file when the browser runs. 
### Solution 1:
If we look through the maps file, we can look for signs of a browser such as
libxul.so
libcef.so
libwebkit2gtk
libwebkitgtk-6
libWPEWebKit
libQtWebEngineCore
### Problem 1:
Many popular apps (unfortunately) embed browser engines to launch their app. This means that those apps will be detected as browsers. 
### Solution 2:
We look for further files to confirm if it is a browser such as 
omni.ja
.asar
electron
### Problem 2: 
This can introduce false positives.
This is unfortunately a trade-off that must exist to ensure that vivaldi is the only browser
The only thing (to my knowledge) that always differentiates between a browser and an embed is an address bar, making it extremely hard to know the intention of a program's use of a browser engine 
