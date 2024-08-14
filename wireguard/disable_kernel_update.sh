#!/bin/bash
cat > /etc/apt/preferences.d/99-no-kernel.pref <<EOF
Package: firmware-linux-free
Pin: origin ""
Pin-Priority: -1

Package: initramfs-tools
Pin: origin ""
Pin-Priority: -1

Package: initramfs-tools-core
Pin: origin ""
Pin-Priority: -1

Package: klibc-utils
Pin: origin ""
Pin-Priority: -1

Package: libklibc
Pin: origin ""
Pin-Priority: -1

Package: linux-image-*-rt-armmp
Pin: origin ""
Pin-Priority: -1

Package: linux-image-rt-armmp
Pin: origin ""
Pin-Priority: -1
EOF
