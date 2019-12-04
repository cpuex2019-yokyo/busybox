#!/bin/bash

#
# create root filesystem
#

# prepare env
set -e
cd $(dirname "$0")

IMAGE_PATH=../rootfs.img
ROOT_PASSWORD=uouo

# prepare rootfs image
rm -f ${IMAGE_PATH=}
dd if=/dev/zero of=${IMAGE_PATH} bs=1M count=300
/sbin/mkfs.ext4 -j -F ${IMAGE_PATH}

test -d mnt || mkdir mnt
mount -o loop ${IMAGE_PATH} mnt

# set up in rootfs
cd mnt
cp -r ../../_install/* .
mkdir -p root bin dev lib lib/modules proc sbin sys tmp usr usr/bin usr/sbin var/run var/log var/tmp etc
ls
cp ../../busybox bin/
rsync -a --exclude ldscripts --exclude '*.la' --exclude '*.a' ${RISCV}/sysroot/lib/ lib/

cp -r ../templates/etc/* etc/
hash=$(openssl passwd -1 -salt xyzzy ${ROOT_PASSWORD})
sed -i'' "s:\*:${hash}:" etc/shadow
chmod 600 etc/shadow

#ln -s ../bin/busybox sbin/init
#ln -s busybox bin/sh
cp ../templates/bin/ldd bin/ldd

mknod dev/console c 5 1
mknod dev/ttyS0 c 4 64
mknod dev/null c 1 3
cd ..

# finalize
umount mnt
sleep 1
rmdir mnt
