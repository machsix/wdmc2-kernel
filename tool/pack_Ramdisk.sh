#!/bin/bash
cd initrd
find . | cpio -o -H newc | gzip  > ../initramfs.cpio.gz
cd ..
mkimage -A arm -O linux -T ramdisk -C gzip -a 0x00e00000 -n Ramdisk -d initramfs.cpio.gz uRamdisk
rm initramfs.cpio.gz
