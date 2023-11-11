Unofficial ArchImage (Arch Linux-based AppImage) of the audio player Amarok built from AUR. 

WARNING! This Appimage is still experimental, do not use it daily except for testing purposes. Any suggestions to improve it are appreciated! 

Current estimated size: just over 600 MB (it will be lightened once the tests are completed)

#### Download
Continuous builds are available at https://github.com/ivan-hc/Amarok-appimage/releases/tag/continuous

#### What works?
- Play audio files.

#### What does not works?
- Can't collect locale files from directories (this seems to be a problem with mariadb).
- Sometime the app can't be closed.

### Reduce the size of the JuNest based Appimage
You can analyze the presence of excess files inside the AppImage by extracting it:

    ./*.AppImage --appimage-extract
To start your tests, run the "AppRun" script inside the "squashfs-root" folder extracted from the AppImage:

    ./squashfs-root/AppRun

-------------------------
### *Special Credits*
- JuNest https://github.com/fsquillace/junest
- Arch Linux https://archlinux.org
