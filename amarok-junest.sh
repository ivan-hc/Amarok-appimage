#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=amarok
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="phonon-qt5-vlc pulseaudio kcmutils5 kdnssd5 kdoctools5 kirigami2 knewstuff5 ktexteditor5 liblastfm-qt5 libofa mariadb mariadb-clients mariadb-libs phonon-qt5 qt5-webengine threadweaver5 ifuse loudmouth"
BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/x86_64/$APP/flag/ -O - | grep $APP | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)
VERSIONAUR=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir

# ENTER THE APPDIR
cd $APP.AppDir

# SET APPDIR AS A TEMPORARY $HOME DIRECTORY, THIS WILL DO ALL WORK INTO THE APPDIR
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# ENABLE CHAOTIC-AUR
./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# UPDATE ARCH LINUX IN JUNEST
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts $(echo "$BASICSTUFF $COMPILERS $DEPENDENCES $APP")

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
rm -R -f ./*.desktop
LAUNCHER=$(grep -iRl $BIN ./.junest/usr/share/applications/* | grep ".desktop" | head -1)
cp -r "$LAUNCHER" ./
ICON=$(cat $LAUNCHER | grep "Icon=" | cut -c 6-)
cp -r ./.junest/usr/share/icons/hicolor/22x22/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/24x24/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/32x32/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/48x48/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/64x64/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/128x128/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/192x192/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/256x256/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/512x512/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/*$ICON* ./ 2>/dev/null
cp -r ./.junest/usr/share/pixmaps/*$ICON* ./ 2>/dev/null

# TEST IF THE DESKTOP FILE AND THE ICON ARE IN THE ROOT OF THE FUTURE APPIMAGE (./*AppDir/*)
if test -f ./*.desktop; then
	echo "The .desktop file is available in $APP.AppDir/"
else 
	cat <<-HEREDOC >> "./$APP.desktop"
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=NAME
	Comment=
	Exec=BINARY
	Icon=tux
	Categories=Utility;
	Terminal=true
	StartupNotify=true
	HEREDOC
	sed -i "s#BINARY#$BIN#g" ./$APP.desktop
	sed -i "s#Name=NAME#Name=$(echo $APP | tr a-z A-Z)#g" ./$APP.desktop
	wget https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico -O ./tux.png
fi

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
rm -R -f ./AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/lib/locale --bind=/etc/fonts --bind=/usr/share/fonts --bind=/usr/share/themes" 2> /dev/null -- $EXEC "$@"
EOF
chmod a+x ./AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh

# EXIT THE APPDIR
cd ..

# REMOVE SOME BLOATWARES
find ./$APP.AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find ./$APP.AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./$APP.AppDir/.junest/etc/makepkg.conf
rm -R -f ./$APP.AppDir/.junest/etc/pacman.conf
rm -R -f ./$APP.AppDir/.junest/usr/include #FILES RELATED TO THE COMPILER
rm -R -f ./$APP.AppDir/.junest/usr/man #APPIMAGES ARE NOT MENT TO HAVE MAN COMMAND
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# IN THE NEXT 4 STEPS WE WILL TRY TO LIGHTEN THE FINAL APPIMAGE PACKAGE
# WE WILL MOVE EXCESS CONTENT TO BACKUP FOLDERS (STEP 1)
# THE AFFECTED DIRECTORIES WILL BE /usr/bin (STEP 2), /usr/lib (STEP 3) AND /usr/share (STEP 4)

# STEP 1, CREATE A BACKUP FOLDER WHERE TO SAVE THE FILES TO BE DISCARDED (USEFUL FOR TESTING PURPOSES)
mkdir -p ./junest-backups/usr/bin
mkdir -p ./junest-backups/usr/lib/dri
mkdir -p ./junest-backups/usr/share

# STEP 2, FUNCTION TO SAVE THE BINARIES IN /usr/bin THAT ARE NEEDED TO MADE JUNEST WORK, PLUS THE MAIN BINARY/BINARIES OF THE APP
# IF YOU NEED TO SAVE MORE BINARIES, LIST THEM IN THE "BINSAVED" VARIABLE. COMMENT THE LINE "_savebins" IF YOU ARE NOT SURE.
_savebins(){
	BINSAVED="SAVEBINSPLEASE"
	mkdir save
	mv ./$APP.AppDir/.junest/usr/bin/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/bin/bash ./save/
	mv ./$APP.AppDir/.junest/usr/bin/env ./save/
	mv ./$APP.AppDir/.junest/usr/bin/proot* ./save/
	mv ./$APP.AppDir/.junest/usr/bin/sh ./save/
	for arg in $BINSAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/bin/*"$arg"* ./save/
		done
	done
	mv ./$APP.AppDir/.junest/usr/bin/* ./junest-backups/usr/bin/
	mv ./save/* ./$APP.AppDir/.junest/usr/bin/
	rmdir save
}
_savebins

# STEP 3, MOVE UNNECESSARY LIBRARIES TO A BACKUP FOLDER (FOR TESTING PURPOSES)
mkdir save

_binlibs(){
	readelf -d ./$APP.AppDir/.junest/usr/bin/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	mv ./$APP.AppDir/.junest/usr/lib/ld-linux-x86-64.so* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/*$APP* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/libdw* ./save/
	mv ./$APP.AppDir/.junest/usr/lib/libelf* ./save/
	mkdir ./save/dri
	mv ./$APP.AppDir/.junest/usr/lib/dri/swrast_dri.so ./save/dri/
	SHARESAVED="qt db libGLX libglapi libxcb libXx libxshmfence vlc libXcursor libqnmbearer mysql Qt libnss p11 kf" # Enter here keywords or file/folder names to save in /usr/lib. By default, the names of the folders that you will save in /usr/share are selected also here.
	for arg in $SHARESAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/lib/*"$arg"* ./save/
		done
	done
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		for var in $arg; do
			mv ./$APP.AppDir/.junest/usr/lib/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/*/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/*/*/$arg* ./save/
			mv $(find ./save/ | sort | grep "usr/lib" | head -1)/* ./save/
			rm -R -f $(find ./save/ | sort | grep ".AppDir" | head -1)
		done 
	done
	
	rm list
}

_liblibs(){
	readelf -d ./save/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	readelf -d ./save/*/*/*/* | grep .so | sed 's:.* ::' | cut -c 2- | sed 's/\(^.*so\).*$/\1/' | uniq >> ./list
	ARGS=$(tail -n +2 ./list | sort -u | uniq)
	for arg in $ARGS; do
		for var in $arg; do
			mv ./$APP.AppDir/.junest/usr/lib/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/*/$arg* ./save/
			cp --parent ./$APP.AppDir/.junest/usr/lib/*/*/*/$arg* ./save/
			mv $(find ./save/ | sort | grep "usr/lib" | head -1)/* ./save/
			rm -R -f $(find ./save/ | sort | grep ".AppDir" | head -1)
		done 
	done
	rm list
}

_mvlibs(){
mv ./$APP.AppDir/.junest/usr/lib/* ./junest-backups/usr/lib/
mv ./save/* ./$APP.AppDir/.junest/usr/lib/
}

_binlibs

_liblibs
_liblibs
_liblibs
_liblibs
_liblibs

_mvlibs

rmdir save

# STEP 4, SAVE ONLY SOME DIRECTORIES CONTAINED IN /usr/share
# IF YOU NEED TO SAVE MORE FOLDERS, LIST THEM IN THE "SHARESAVED" VARIABLE. COMMENT THE LINE "_saveshare" IF YOU ARE NOT SURE.
_saveshare(){
	SHARESAVED="qt db kf"
	mkdir save
	mv ./$APP.AppDir/.junest/usr/share/*$APP* ./save/
 	mv ./$APP.AppDir/.junest/usr/share/*$BIN* ./save/
	mv ./$APP.AppDir/.junest/usr/share/fontconfig ./save/
	mv ./$APP.AppDir/.junest/usr/share/glib-* ./save/
	mv ./$APP.AppDir/.junest/usr/share/locale ./save/
	mv ./$APP.AppDir/.junest/usr/share/mime ./save/
	mv ./$APP.AppDir/.junest/usr/share/wayland ./save/
	mv ./$APP.AppDir/.junest/usr/share/X11 ./save/
	for arg in $SHARESAVED; do
		for var in $arg; do
 			mv ./$APP.AppDir/.junest/usr/share/*"$arg"* ./save/
		done
	done
	mv ./$APP.AppDir/.junest/usr/share/* ./junest-backups/usr/share/
	mv ./save/* ./$APP.AppDir/.junest/usr/share/
	rmdir save
}
_saveshare

# ADDITIONAL REMOVALS

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION""$VERSIONAUR"-x86_64.AppImage
