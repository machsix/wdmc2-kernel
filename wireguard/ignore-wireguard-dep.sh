#!/bin/bash
cat > /etc/apt/preferences.d/98-ignore-wireguard-dep.pref <<EOF
Package: wireguard-modules
Pin: origin ""
Pin-Priority: -1

Package: wireguard-dkms
Pin: origin ""
Pin-Priority: -1
EOF
