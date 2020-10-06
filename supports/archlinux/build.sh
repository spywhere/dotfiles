#!/bin/sh

set -e
echo "Downloading archlinux tarball..."
curl -L http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz --progress-bar -o archlinux.tar.gz
echo "Building Docker image from rootfs..."
docker build -t archlinux .
echo "Done"
