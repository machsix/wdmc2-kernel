#!/bin/bash

unalias -a

# Find dir of build.sh and go there
current_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
output_dir="${current_dir}/output"
rootfs_dir="${output_dir}/rootfs"
boot_dir="${output_dir}/boot"
cache_dir="${current_dir}/cache"

echo "### Mounting / preparing chroot"
mount -t proc chproc "${rootfs_dir}"/proc
mount -t sysfs chsys "${rootfs_dir}"/sys
mount -t devtmpfs chdev "${rootfs_dir}"/dev || mount --bind /dev "${rootfs_dir}"/dev
mount -t devpts chpts "${rootfs_dir}"/dev/pts

chroot "${rootfs_dir}"
