This repository creates and distributes the unofficial Appimage of Amarok.

From here you can download the scripts to build on top of [JuNest](https://github.com/fsquillace/junest), the lightweight Arch Linux based distro that runs, without root privileges, on top of any other Linux distro.

#### WARNING! This Appimage is still experimental, do not use it daily except for testing purposes. Any suggestions to improve it are appreciated! 

---------------------------------

#### What works?
- Play audio files.

---------------------------------

#### What does not works?
- Can't collect locale files from directories (this seems to be a problem with mariadb).
- Sometime the app can't be closed.

---------------------------------

## Debugging and improvements

To improve it, extract the AppImage using the option `--appimage-extract` and follow the instructions [here](https://github.com/ivan-hc/ArchImage#troubleshooting).
