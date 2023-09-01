#!/bin/bash

set -ex

ramdisk=$1
system=$2
image=${3:-android.img}

if [ -z "$ramdisk" ] || [ -z "$system" ]; then
	echo "Usage: $0 <ramdisk> <system image> [<output anbox image>]"
	exit 1
fi

workdir=`mktemp -d`
rootfs=$workdir/rootfs

mkdir -p $rootfs

# Extract ramdisk and preserve ownership of files
(cd $rootfs ; cat $ramdisk | gzip -d | cpio -i)

mkdir $workdir/system
mount -o loop,ro $system $workdir/system
cp -ar $workdir/system/* $rootfs/system
umount $workdir/system

gcc -o $workdir/uidmapshift external/nsexec/uidmapshift.c
$workdir/uidmapshift -b $rootfs 0 100000 65536

# FIXME
chmod +x $rootfs/anbox-init.sh

mksquashfs $rootfs $image -comp xz -no-xattrs
chown $USER:$USER $image

rm -rf $workdir
