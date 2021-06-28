#!/bin/sh

build_rootfs () {
  target_host=$(hostname)
  # set -e
  echo "[$target_host] Update repositories..."
  apt update
  echo "[$target_host] Upgrading packages..."
  apt upgrade -y
  echo "[$target_host] Install building packages..."
  apt install -y wget kpartx zip sudo
  echo "[$target_host] Download Raspberry Pi OS Lite image..."
  wget -nc https://downloads.raspberrypi.org/raspios_lite_armhf_latest -O raspios_lite.zip
  echo "[$target_host] Extracting image..."
  unzip -n raspios_lite.zip
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

if test "$1" = "rootfs"; then
  build_rootfs
  exit 0
fi

base_host=$(hostname)

set -e
if ! test -f "raspios_rootfs.tar.gz"; then
  echo "[$base_host] Building raspios_rootfs.tar.gz..."
  docker run --network=host --hostname=docker --privileged -it --rm -w /raspios -v /dev:/dev -v "$(pwd):/app" debian:buster-slim sh /app/build.sh rootfs
fi
echo "[$base_host] Building Docker image from rootfs..."
docker build -t raspios:lite . -f- <<EOF
FROM scratch
ADD ./raspios_rootfs.tar.gz /
CMD ["bash"]
EOF
echo "[$base_host] Done"
