#!/bin/sh

machine=`uname -m`
if [ "${machine}" != "armv7l" ]; then
  echo "This script will be executed at mounted raspbian enviroment (armv7l). Current environment is ${machine}."
  exit 1
fi

echo "Please check environment variables etc, this script can be executed ONLY within RPI environment!"
echo "When tasks done, type \"exit\" to return"
echo ""

#Permit Root Password Login
sed -i "s/PermitRoot.*/PermitRootLogin yes/" /etc/ssh/sshd_config

#mpd
apt-get -y install mpd mpc alsa-utils python-pip python3 python3-pip python-pygame
systemctl enable mpd
echo "#\!/bin/sh
mount -o remount,rw /" > /usr/sbin/rw
chmod +x /usr/sbin/rw
pip install python-mpd2
pip3 install python-mpd2

#ignore trashbin folders created by OS X
echo ".Trashes
" > /media/.mpdignore

cp mpd.conf /etc
mkdir /persist/mpd
chown mpd:audio /persist/mpd

#usbmount configuration
apt-get -y install usbmount
cp 01_update_mpc_unmount /etc/usbmount/umount.d/
chmod +x /etc/usbmount/umount.d/01_update_mpc_unmount
cp 01_update_mpc_mount /etc/usbmount/mount.d/
chmod +x /etc/usbmount/mount.d/01_update_mpc_mount

ln -s /media /var/lib/mpd/music/media

sed -e "s/MOUNTOPTIONS.*/MOUNTOPTIONS=\"ro,sync,noexec,nodev,noatime,nodiratime\"/" /etc/usbmount/usbmount.conf > /tmp/usbmount.conf
mv /tmp/usbmount.conf /etc/usbmount/usbmount.conf

#echo "auto lo
#iface lo inet loopback
#" > /etc/network/interfaces

#display stuff
apt-get -y install tslib libts-bin
echo "dtparam=spi=on
dtoverlay=mz61581
" >> /boot/config.txt

cp 96-touch.rules /etc/udev/rules.d/

apt-get -y install fake-hwclock
rm /etc/fake-hwclock.data
ln -s /persist/fake-hwclock.data /etc/fake-hwclock.data
fake-hwclock save

#broken libsdl workaround
echo "deb http://archive.raspbian.org/raspbian wheezy main
" > /etc/apt/sources.list.d/wheezy.list

echo "APT::Default-release \"stable\";
" > /etc/apt/apt.conf.d/10defaultRelease

echo "Package: libsdl1.2debian
Pin: release n=jessie
Pin-Priority: -10

Package: libsdl1.2debian
Pin: release n=wheezy
Pin-Priority: 900
" > /etc/apt/preferences.d/libsdl

apt-get update
apt-get -y --force-yes install libsdl1.2debian/wheezy

echo "#\!/bin/sh
TSLIB_FBDEVICE=/dev/fb1 TSLIB_TSDEVICE=/dev/input/touchscreen ts_calibrate
" > /usr/local/bin/calibrate
chmod +x /usr/local/bin/calibrate
cp pointercal /etc

#pulseaudio
apt-get install -y --no-install-recommends bluez bluez-tools pulseaudio pulseaudio-module-bluetooth

sed -i "s/#Name.*/Name = AstraPi/" /etc/bluetooth/main.conf
echo "load-module module-loopback
" >> /etc/pulse/default.pa

rm /var/lib/bluetooth
mkdir /persist/bluetooth
ln -s /persist/bluetooth /var/lib/bluetooth

rm /var/lib/mpd/.config
mkdir /persist/mpd/.config
ln -s /persist/mpd/.config /var/lib/mpd/.config
chown mpd:audio /persist/mpd/.config
chown -H mpd:audio /var/lib/mpd/.config

usermod -aG pulse,pulse-access,bluetooth mpd

#syslog
apt-get install -y busybox-syslogd
dpkg --purge rsyslog

#set timezone
timedatectl set-timezone Europe/Berlin


