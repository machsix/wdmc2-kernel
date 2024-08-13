#!/bin/bash

archive=${1:-gzip}
rm -rf initrd
mkdir -p initrd
if [ "${archive}" = "lzma" ]; then
  dd if=uRamdisk of=initrd/initrd.cpio.lzma bs=64 skip=1
  cd initrd
  lzma -d initrd.cpio.lzma
else
  dd if=uRamdisk of=initrd/initrd.cpio.gz bs=64 skip=1
  cd initrd
  gzip -d initrd.cpio.gz
fi

cpio -i < initrd.cpio
rm initrd.cpio
cd -
