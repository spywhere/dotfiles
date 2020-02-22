# Recommended setup
# docker run --privileged -it --rm -w /raspbian -v $(pwd):/app debian:buster-slim bash /app/build.sh

build_rootfs () {
  # set -e
  echo "Update repositories..."
  apt update
  echo "Upgrading packages..."
  apt upgrade -y
  echo "Install building packages..."
  apt install -y wget kpartx zip sudo
  echo "Download Raspbian Lite image..."
  wget -nc https://downloads.raspberrypi.org/raspbian_lite_latest -O raspbian_lite.zip
  echo "Extracting image..."
  unzip -n raspbian_lite.zip
  image=$(ls *.img)
  device=`kpartx -va ${image} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
  device="/dev/mapper/${device}"
  mkdir -p rootfs
  echo "Mounting rootfs..."
  mount "${device}p2" rootfs
  # Or alternatively create a dockerfile out of rootfs instead
  echo "Packing rootfs..."
  tar -czvf raspbian_rootfs.tar.gz -C rootfs .
  mv raspbian_rootfs.tar.gz /app
  echo "Cleaning up..."
  umount rootfs
  kpartx -d $image
  rm -rf rootfs
  echo "Done"
}

if [ "$@" = "rootfs" ]; then
  build_rootfs
  exit 0
fi

set -e
echo "Building raspbian_rootfs.tar.gz..."
docker run --privileged -it --rm -w /raspbian -v $(pwd):/app debian:buster-slim sh /app/build.sh rootfs
echo "Building Docker image from rootfs..."
docker build -t raspbian:tmp .
echo "Done"
