#!/bin/sh

STARTDIR=$(pwd)
KERNEL_RELEASE="$(uname -r)"
KERNEL_EDITION="$(uname -r | sed 's/-.*$//g')"
SOURCEDIR="source/$(uname -r)"
TARGETDIR="/lib/modules/$KERNEL_RELEASE/kernel/"
MODULE="drivers/input/mouse/psmouse.ko"

get_patch()
{
	cd tmp
	if [ ! -f "disabling_gesture.patch" ]; then
		curl "https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/patch/?id=e51e38494a8ecc18650efb0c840600637891de2c" > disabling_gesture.patch 2>/dev/null
	fi
	cd - >/dev/null
}

get_source()
{
	if [ ! -d "$SOURCEDIR" ]; then
	
		mkdir -p "$SOURCEDIR"
		cd "$SOURCEDIR"
		apt-get source "linux-image-$KERNEL_RELEASE"
		cd -
	
	fi
}

backup()
{
	SOURCE="$1"
	i=1
	TARGET="$SOURCE.bu.$i"
	while [ -f "$TARGET" ]; do
		i=$(($i+1))
		TARGET="$SOURCE.bu.$i"
	done
	sudo mv "$SOURCE" "$TARGET"
}

rm -rf tmp
mkdir tmp
get_patch
get_source
cp -r "$SOURCEDIR"/* tmp/
cd "tmp/linux-$KERNEL_EDITION"
patch -p1 < ../disabling_gesture.patch
make -C "/lib/modules/$KERNEL_RELEASE/build" M="$(pwd)" "$MODULE"
backup "$TARGETDIR/$MODULE"
sudo cp "$MODULE" "$TARGETDIR/$MODULE"
sudo rmmod psmouse
sudo modprobe psmouse

cd "$STARTDIR"
rm -rf tmp

