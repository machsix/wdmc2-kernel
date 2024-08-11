#!/bin/bash

# Find dir of build.sh and go there
current_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
output_dir="${current_dir}/output"
rootfs_dir="${output_dir}/rootfs"
boot_dir="${output_dir}/boot"
cache_dir="${current_dir}/cache"
release=bookworm

echo "### Unmounting"
while grep -Eq "${rootfs_dir}.*(dev|proc|sys)" /proc/mounts
do
	umount -l --recursive "${rootfs_dir}"/dev >/dev/null 2>&1
	umount -l "${rootfs_dir}"/proc >/dev/null 2>&1
	umount -l "${rootfs_dir}"/sys >/dev/null 2>&1
	sleep 5
done

echo "### Rootfs complete: ${release}/${arch}"
echo "### Packing and cleanup"

cd "${rootfs_dir}"

tar -czf "${output_dir}"/"${release}"-rootfs.tar.gz .

chown "root:sudo" "${rootfs_dir}"
chown "root:sudo" "${output_dir}"/"${release}"-rootfs.tar.gz
chmod "g+rw" "${rootfs_dir}"
chmod "g+rw" "${output_dir}"/"${release}"-rootfs.tar.gz

