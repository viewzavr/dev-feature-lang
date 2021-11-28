# Local data server project

Allows to visualize CinemaScience 3d scenes on local computer.

# Installation

* Install nodejs from https://nodejs.org/en/download/ for linux or windows.
* If you use windows 7, use this [installer](https://nodejs.org/download/release/v13.14.0/node-v13.14.0-x64.msi)

# Usage
Run:
* `npx vr-cinema`
* `npx vr-cinema path-to-dir`

Will run vr-cinema on local interface 127.0.0.1.

# Options

* Bind to specific interface: `VR_HOST=some-interface npx vr-cinema`.
Examples: `VR_HOST=myhost.com npx vr-cinema`, `VR_HOST=192.168.0.5 npx vr-cinema`.

# Integrate with windows explorer / gnome

## Linux
Run `npx -p vr-cinema vr-cinema-setup`
Effect: gnome nautilus will show a `script/vr-cinema` in folders context menu.

## Windows
Download [setup.reg](https://viewzavr.com/apps/vr-cinema/local_data_server/setup-windows/setup.reg) and click it.
Effect: explorer context menu on folders will have `Open with VR-Cinema` menu.

To uninstall, download [setupoff.reg](https://viewzavr.com/apps/vr-cinema/local_data_server/setup-windows/setup.regoff) and click it.

# Idea

Project main idea:
1. Serve specific dir on local machine so web browser may access files on that dir.
2. Be able to run (1) as npx command.
3. Integrate (2) with shell (explorer, gnome).

## Notes

It is currently tied with ../package.json. Actually, client's counterpart is done in ../index.html.
Probably, these all are separate projects - vr-cinema and local-server-powered add-on.
Also, loading side modules should be considered, for example Dubins.

# Notes on integration
We still user npx, probably it is simpler to install vr-cinema once in a form `npm i -g vr-cinema`.
However in that case user have to manually update server.

We integrate with gnome/nautilus using nautilus script feature.
We integrate with explorer using reg files.

# Ideas


* Handle file changes and notify client.
Seems simples way is to load ws://...data.csv in current circumstances,
hovewer to handle other files probably it is better to see on notifiers.
Probably, should thing of it.
* Notify server when browser window closes so server may stop?
Probably it may be tied with previous feature - so server stops when
all clients closes connections (probably with some elegant manner so we do not
close server if connection just closed by say hibernation).

# Requirements and features

## R-FRESH-DATA
Data should be displayed fresh, as on disks.

### F-CACHE
Cache should be 0 with e-tags, so new data will.

## R-SAVE-SETTINGS
User should be able to save settings while navigating scene.

### F-AUTOSAVE
Auto-save viewzavr-settings.json (done in ../index.html)

## R-EASY-START
User should have an ability to start our CinemaScience viewer with easy on local data files.
That's why we created this server. However it should be probably integrated with explorer/gnome.

## R-EXPLORE
It will be easier to use if software may find cinemascience bases automatically.

### F-EXPLORE
Inspect subdirs to multiple data.csv and show their overview with screenshots.
Currently if data.csv exist in specified dir, it will start as is.
In other case, a search of data.csv files is performed and they are shown in index screen.

## R-FRESH-FILES
When sending files, it should be served with valid responce headers so browser will cache
them smartly, say with e-tag of if-modified-since checking on each ongoing request to same
resource.

## R-INTERFACES-BIND
We should somehow configure which interfaces should server listen on.
Options file? Env? (seems env is simpler, then go to options file).
Additionally, if we serve from 0.0.0.0, url to files in explore mode 
should point to some accessible address.
## F-INTERFACES-BIND [x]
Implemented option VR_HOST. It was an option for VR_BIND, but seems `host` is more intuitive for user.

## F-REQUESTER-CORS [x]
We should respond to requester host in cors. This is required for https operation.

## R-SECURE [x]
If started from user home dir, an ssh key is also served. Do something with this.
## F-SECURE [x]
If see .ssh folder in startup, stop.

## F-SERVER-CINEMA-LOCAL
Technically we may serve vr-cinema project locally, without
going to viewzavr.com project at all, for example from /vr-cinema path.
Then, probably, we may even hook viewzavr-system-a too as a submodule
(seems this is a best way).
But this will work only in http mode, which is problem for WebVR.

# F-SORT-LISTING
When showing listing of scenes, sort them using pathes to dirs.

# I-UPPER-SETTINGS
If file viewzavr-settings.json not present in cur folder, look in upper folders.

# I-UPPER-FILES
If loading file that is relative and upper to current cinema dir on disk,
allow loading it if it is referenced in data.csv.

## F-LOCAL-CINEMA
VR-Cinema should be server from local installation, not internet-hosted one.

# I-AUTOCLOSE-SERVER
Count clients and close server? // Ws

# F-AUTOOPEN-ONE-SCENE
If there is only 1 scene, auto open it instead of listing.
Clarified: open scene, only if data.csv is located in dir.
Else, start scan and show even 0 or 1 scenes, but always in listing mode;

# R-PRINT-PROJECT-VERSION
We need somehow to check which version of server/project is running.
## F-PRINT-PROJECT-VERSION
Print server version from package.json / npm env.