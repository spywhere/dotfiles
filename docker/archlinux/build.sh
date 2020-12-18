#!/bin/sh

set -e

if ! test -f "archlinux.tar.gz"; then
  echo "Downloading archlinux tarball..."
  curl -L http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz --progress-bar -o archlinux.tar.gz
fi
echo "Building Docker image from rootfs..."
docker build -t archlinux . -f- <<EOF
FROM scratch
ADD ./archlinux.tar.gz /
CMD ["sh"]
EOF
echo "Done"
