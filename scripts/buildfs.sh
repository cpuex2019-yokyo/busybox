#!/bin/bash

#
# create root filesystem
#

# prepare env
set -e
cd $(dirname "$0")

ROOT_PASSWORD=uouo

# prepare rootfs image
rm -f ../rootfs.img
rm -f ../initramfs.cpio.gz
dd if=/dev/zero of=../rootfs.img bs=1M count=300
/sbin/mkfs.ext2 -j -F ../rootfs.img

test -d mnt || mkdir mnt
mount -o loop ../rootfs.img mnt

# set up in rootfs
cd mnt
cp -r ../../_install/* .
mkdir -p bin dev lib lib/modules proc sbin sys tmp usr usr/bin usr/sbin var/run var/log var/tmp etc
ls
cp ../../busybox bin/
cp -r ../templates/etc/* etc/
ln -s bin/busybox init
cp ../templates/bin/ldd bin/ldd
rsync -a --exclude ldscripts --exclude '*.la' --exclude '*.a' ${RISCV}/sysroot/lib/ lib/
#cp ${RISCV}/sysroot/lib/libc.so.6 lib/libc.so.6
rm lib/libnss*

# set passwd
hash=$(openssl passwd -1 -salt xyzzy ${ROOT_PASSWORD})
sed -i'' "s:\*:${hash}:" etc/shadow
chmod 600 etc/shadow


mknod dev/console c 5 1
mknod dev/ttyS0 c 4 64
mknod dev/null c 1 3

find . | cpio -o -H newc | gzip > ../../initramfs.cpio.gz
cd ..

# finalize
umount mnt
rmdir mnt
