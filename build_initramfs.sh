#!/bin/bash

# https://wiki.gentoo.org/wiki/Custom_Initramfs

# needed to make parsing outputs more reliable
export LC_ALL=C
# we can never know what aliases may be set, so remove them all
unalias -a

# destination
CURRENT_DIR=$PWD
INITRAMFS=${CURRENT_DIR}/initramfs
INITRAMFS_ROOTFS=${CURRENT_DIR}/initramfs_rootfs.tar.gz
INITRAMFS_ROOT=${INITRAMFS}/root
if [ ! -f ${INITRAMFS_ROOTFS} ]; then
    echo "initramfs_rootfs.tar.gz is not found"
    exit 1
fi

if [ "$1" = '--update' ]
then
    UPDATE_BOOT='yes'
else
    UPDATE_BOOT='no'
fi

echo '### Removing old stuff'

# remove old cruft
rm -rf ${INITRAMFS}/

mkdir -p ${INITRAMFS}
mkdir -p ${INITRAMFS_ROOT}

tar xf ${INITRAMFS_ROOTFS} -C ${INITRAMFS_ROOT}

echo '### Creating initramfs root'

mkdir -p ${INITRAMFS_ROOT}/{bin,dev,etc,lib,lib64,mnt,proc,sbin,sys,usr,run} ${INITRAMFS_ROOT}/usr/{bin,sbin}

echo '### Install busybox'
# Download a static-built busybox. The one shipped with Debian lacks telnetd and ftpd
# curl https://files.serverless.industries/bin/busybox.armv7 -o ${INITRAMFS_ROOT}/bin/busybox
curl https://www.busybox.net/downloads/binaries/1.21.1/busybox-armv7l -o ${INITRAMFS_ROOT}/bin/busybox
chmod +x ${INITRAMFS_ROOT}/bin/busybox
${INITRAMFS_ROOT}/bin/busybox --install -s ${INITRAMFS_ROOT}/bin
for i in ${INITRAMFS_ROOT}/bin/*; do
    exe_name=$(basename $i)
    if [ "$exe_name" != "busybox" ]; then
        ln -rsf ${INITRAMFS_ROOT}/bin/busybox $i
    fi
done

cp -a /usr/sbin/led ${INITRAMFS_ROOT}/sbin/led
EXTRA_EXE=("e2fsck")
for i in "${EXTRA_EXE[@]}"; do
    cp -L $(which $i) ${INITRAMFS_ROOT}/bin/$i
    cp $(ldd ${INITRAMFS_ROOT}/bin/${i} | egrep -o '/.* ') ${INITRAMFS_ROOT}/lib/
done

chmod +x ${INITRAMFS_ROOT}/init
chown -R root:root ${INITRAMSF_ROOT}

echo '### Creating uRamdisk'

cd ${INITRAMFS_ROOT}
find . -print | cpio -ov --format=newc | gzip -9 > ${INITRAMFS}/custom-initramfs.cpio.gz
mkimage -A arm -O linux -T ramdisk -a 0x00e00000 -e 0x0 -n "Custom initramfs" -d ${INITRAMFS}/custom-initramfs.cpio.gz ${INITRAMFS}/uRamdisk

if [ "$UPDATE_BOOT" = 'yes' ] 
then 
    if [ -e '/boot/boot/' ]; then
        echo '### Updating /boot/boot'    
    
        if [ -e '/boot/boot/uRamdisk' ]; then
            mv /boot/boot/uRamdisk /boot/boot/uRamdisk.old
        fi
    
        mv ${INITRAMFS}/uRamdisk /boot/boot/uRamdisk        
    elif [ -e '/boot/' ]; then
        echo '### Updating /boot'
    
        if [ -e '/boot/uRamdisk' ]; then
            mv /boot/uRamdisk /boot/uRamdisk.old
        fi
    
        mv ${INITRAMFS}/uRamdisk /boot/uRamdisk    
    fi

    rm -rf ${INITRAMFS}
else
    echo '### Cleanup'
    rm -rf ${INITRAMFS}/custom-initramfs.cpio.gz
    rm -rf ${INITRAMFS_ROOT}
fi

echo '### Done.'

