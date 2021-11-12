# Upon newly setup on Raspberry Pi

- Generate locale with `sudo locale-gen` (be sure to check the locale is added in /etc/locale.gen)
- Update hostname and reboot once
- Add new user by `sudo adduser <user>`
  - Add user into the groups using `sudo usermod -aG sudo,audio,video,games,users,input,netdev,i2c,gpio <user>`
- Add Aptitude repositories

```
deb http://mirror.kku.ac.th/raspbian/raspbian/ bulleyes main contrib non-free rpi
deb http://raspbian.raspberrypi.org/raspbian/ testing main contrib non-free rpi
deb-src http://mirror.kku.ac.th/raspbian/raspbian/ bulleyes main contrib non-free rpi
deb-src http://raspbian.raspberrypi.org/raspbian/ testing main contrib non-free rpi
```
- Adjust overclock and voltage in `/boot/config.txt`
  - Voltage adjustment
    - Raspberry Pi 4: `over_voltage=6`
    - Raspberry Pi Zero 2: `over_voltage=4`
  - Frequency adjustment
    - Raspberry Pi 4: `arm_freq=2000`
    - Raspberry Pi Zero 2: `arm_freq=1300`
