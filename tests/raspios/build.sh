#!/bin/sh

build_rootfs () {
  target_host=$(hostname)
  # set -e
  echo "[$target_host] Update repositories..."
  apt update
  echo "[$target_host] Upgrading packages..."
  apt upgrade -y
  echo "[$target_host] Install building packages..."
  apt install -y curl kpartx zip sudo
  echo "[$target_host] Download Raspberry Pi OS Lite ($1) image..."
  curl -L "https://downloads.raspberrypi.org/raspios_lite_${1}_latest" -o "raspios_lite_${1}.zip"
  echo "[$target_host] Extracting image..."
  unzip -n "raspios_lite_${1}.zip"
  image=$(ls ./*.img)
  device=$(kpartx -va "$image" | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1)
  device="/dev/mapper/$device"
  mkdir -p rootfs
  echo "[$target_host] Mounting rootfs..."
  mount "${device}p2" rootfs
  # Or alternatively create a dockerfile out of rootfs instead
  echo "[$target_host] Packing rootfs..."
  tar -czvf raspios_rootfs.tar.gz -C rootfs .
  mv raspios_rootfs.tar.gz /app
  echo "[$target_host] Cleaning up..."
  umount rootfs
  kpartx -d "$image"
  rm -rf rootfs
  echo "[$target_host] Done"
}

if test -z "$1"; then
  echo "usage: $0 <arch>"
  echo
  echo "architectures:"
  echo "  - armhf"
  echo "  - arm64"
  exit 0
else
  if test "$2" = "rootfs"; then
    build_rootfs "$1"
    exit 0
  fi
fi

base_host=$(hostname)

set -e
if ! test -f "raspios_rootfs.tar.gz"; then
  echo "[$base_host] Building raspios_rootfs.tar.gz ($1)..."
  docker run --network=host --hostname=docker --privileged -it --rm -w /raspios -v /dev:/dev -v "$(pwd):/app" debian:bullseye-slim sh /app/build.sh "$1" rootfs
fi
echo "[$base_host] Building Docker image from rootfs..."
docker build -t "raspios:lite-$1" . -f- <<EOF
FROM scratch
ADD ./raspios_rootfs.tar.gz /
CMD ["bash"]
EOF
echo "[$base_host] Done"
