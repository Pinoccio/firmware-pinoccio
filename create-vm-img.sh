#!/bin/sh

# Pinoccio virtual machine image creation script
#
# Copyright (C) 2009 Matthijs Kooijman <matthijs@stdin.nl>
# Copyright (C) 2014 Geoff Van der Wagen <geoff@thenack.com>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# This script creates a Debian install for use in Virtualbox
# and contains a preconfigured environment for the Pinoccio ecosystem
#

# Debian mirror
DEBIANMIRROR="ftp.us.debian.org"
# (Maximum) size of the disk (in megabytes)
DISK_SIZE=10240
# Amount of RAM to allocate to VM (in megabytes)
RAM=1024
# Version of Debian to use
DEBIANVERSION=jessie
# Username of the default (and only) user
USERNAME=pinoccio
# Hostname for the system
HOSTNAME=pinoccio
# Place to mount the filesystem while building. Directory shouldn't
# exist yet.
ROOT="/mnt/virtual-$HOSTNAME"
# Filename for the normal loopback-mountable filesystem image
IMG="${HOSTNAME}.img"
# Filename for the final disk that is part of the Open Virtualization
# Format package.
VMDK="${HOSTNAME}.vmdk"
# Filename for the configuration that is part of the Open Virtualization
# Format package.
OVF="${HOSTNAME}.ovf"
# The virtualbox share to automount. Should not contain any spaces.
VBOXSHARE=share

# Link to Arduino IDE to install
ARDUINOIDE="http://downloads.arduino.cc/arduino-avr-toolchain-nightly-gcc-4.8.1-linux32.tgz"

# Link to Github repo for the hardware/libraries
GITREPO="https://github.com/Pinoccio/firmware-pinoccio.git"

# Extra debian packages to install
PACKAGES="linux-image-686-pae virtualbox virtualbox-guest-utils \
  virtualbox-guest-x11 xfce4 slim xorg xserver-xorg-input-all \
  vim less sudo iceweasel bzip2 build-essential make gcc passwd \
  medit vim-gtk open-vm-tools-desktop wget git openssl ca-certificates \
  xorg desktop-base thunar-volman tango-icon-theme xfce4-notifyd \
  xfce4-goodies xfce4-power-manager gtk3-engines-xfce default-jre synaptic"

export LANG=
set -e 


echo "**********Checking system dependencies"
dpkg-query -W -f='${binary:Package} \t\t${Status}\n' \
  sudo debootstrap virtualbox extlinux git wget bison flex bzip2 \
  build-essential make gcc subversion autoconf automake

echo "Make sure all the above packages are installed!"
echo "Ctrl-C to break out and add them, or press ENTER to continue"
read VAR1


echo "**********Creating virtual disk file using dd"
dd if=/dev/zero "of=${IMG}" bs=1M count=${DISK_SIZE}

echo "**********Creating ext4 file system on image file"
# Create the filesystem (-F to convince mkfs to work on a regular file).
sudo mkfs.ext4 -F "${IMG}"

echo "**********Mounting the filesystem"
# Mount the filesystem somewhere
sudo mkdir "${ROOT}"
sudo mount -o loop "${IMG}" "${ROOT}"


echo "**********Bootstrapping Debian"
# Bootstrap Debian
sudo debootstrap --arch i386 "${DEBIANVERSION}" \
  "${ROOT}" http://${DEBIANMIRROR}/debian

echo "**********Setting up proc,dev,sys"
sudo mount -t proc none "${ROOT}/proc"
sudo mount -o bind /dev "${ROOT}/dev"
sudo mount -t sysfs sys "${ROOT}/sys"

echo "**********Setting up kernel-img"
sudo sh -c "cat > '${ROOT}/etc/kernel-img.conf'" <<EOF
do_initrd = Yes
EOF

echo "**********Adding contrib/non-free to client apt"
sudo sed -i "s/ ${DEBIANVERSION} main$/ ${DEBIANVERSION} main contrib non-free/" ${ROOT}/etc/apt/sources.list
sudo chroot "${ROOT}" aptitude update

echo "**********Installing extra packages"
# Install extra packages. Don't use debootstrap's --include, since it is
# less smart (installs all xserver-xorg-video-* packages, for example).
export DEBCONF_PRIORITY=critical 
export DEBIAN_FRONTEND=noninteractive
sudo chroot "${ROOT}" aptitude \
  --without-recommends --assume-yes install ${PACKAGES}
sudo chroot "${ROOT}" aptitude clean

echo "**********Configuring user and root accounts"
# Setup user account
sudo chroot "${ROOT}" adduser --disabled-password --gecos "" "${USERNAME}"
sudo chroot "${ROOT}" usermod -a -G dialout "${USERNAME}"
# Set password to "user"
sudo chroot ${ROOT} sh -c "echo \"${USERNAME}:${USERNAME}\" | /usr/sbin/chpasswd"

# Set root password to "root"
sudo chroot ${ROOT} sh -c "echo \"root:root\" | /usr/sbin/chpasswd"

echo "**********Configuring sudo"
# Allow passwordless sudo
sudo sh -c "cat  > '${ROOT}/etc/sudoers'" <<EOF
Defaults	env_reset
Defaults	mail_badpass
Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

${USERNAME} ALL=NOPASSWD: ALL
EOF


echo "**********Setting up autologin"
# Setup autologin
sudo sh -c "cat >> '${ROOT}/etc/slim.conf'" <<EOF
default_user ${USERNAME}
auto_login yes
EOF

echo "**********Setup networking"
# Setup networking
sudo sh -c "cat >> '${ROOT}/etc/network/interfaces'" <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
sudo sh -c "echo ${HOSTNAME} > '${ROOT}/etc/hostname'"
sudo sh -c "echo 127.0.0.1 ${HOSTNAME} > '${ROOT}/etc/hosts'"

echo "**********Installing bootloader"
sudo mkdir "${ROOT}/boot/extlinux"
sudo extlinux --install "${ROOT}/boot/extlinux/"

KERNEL=`(cd "${ROOT}/boot/"; ls vmlinuz-* | head -1)`
INITRD=`(cd "${ROOT}/boot/"; ls initrd.* | head -1)`
sudo sh -c "cat > '${ROOT}/boot/extlinux/extlinux.conf'" <<EOF
default linux
label linux
        kernel  /boot/${KERNEL}
        append initrd=/boot/${INITRD} root=/dev/sda ro

label single
        kernel  /boot/${KERNEL}
        append initrd=/boot/${INITRD} root=/dev/sda ro single
EOF

#echo "**********Configuring X"
# Setup X.org virtualbox mouse driver for full integration (Video driver
# is autodetected in lenny).
#sudo chroot "${ROOT}" /usr/share/virtualbox/x11config.pl

#echo "**********Mounting share folder"
# Mount a vbox shared folder called "share" for easy filesharing between
# host and guest (user only needs to setup a shared folder using
# "Devices" -> "Shared folders..." within Virtualbox.
#sudo sh -c "echo vboxvfs > '${ROOT}/etc/modules'"
#sudo mkdir "${ROOT}/home/${USERNAME}/${VBOXSHARE}"
#sudo sh -c "echo ${VBOXSHARE} /home/${USERNAME}/${VBOXSHARE} vboxsf defaults,uid=${USERNAME} 0 0 \
#  > '${ROOT}/etc/fstab'"

# Now, install Pinoccio related stuff

echo "**********Installing Arduino IDE"
sudo chroot "${ROOT}" mkdir /usr/local/arduino
sudo chroot "${ROOT}" wget -O /usr/local/arduino/arduino.tgz ${ARDUINOIDE}
sudo chroot "${ROOT}" tar -zxf /usr/local/arduino/arduino.tgz -C /usr/local/arduino/ --strip 1
sudo chroot "${ROOT}" rm /usr/local/arduino/arduino.tgz
sudo chroot "${ROOT}" chown -R root.staff /usr/local/arduino

echo "**********Setting nice user prefs"
sudo mkdir "${ROOT}/home/${USERNAME}/.arduino15"
sudo sh -c "cat > '${ROOT}/home/${USERNAME}/.arduino15/preferences.txt'" <<EOF
board=pinoccio
custom_cpu=pinoccio_atmega256rfr2
editor.window.height.default=700
editor.window.width.default=980
serial.databits=8
serial.debug_rate=115200
serial.line_ending=3
serial.parity=N
serial.port=/dev/ttyACM0
serial.port.file=ttyACM0
serial.stopbits=1
sketchbook.path=/usr/local/pinoccio-firmware
software=ARDUINO
target_package=pinoccio
target_platform=avr
EOF

sudo chroot "${ROOT}" chown -R ${USERNAME}.${USERNAME} /home/${USERNAME}/.arduino15

echo "**********Installing Pinoccio libraries"
sudo chroot "${ROOT}" git clone ${GITREPO} /usr/local/pinoccio-firmware
sudo chroot "${ROOT}" sh -c 'cd /usr/local/pinoccio-firmware && ./update.sh'

echo "**********Setting IDE/library ownership to user, for updates"
sudo chroot "${ROOT}" chown -R ${USERNAME}.${USERNAME} /usr/local/pinoccio-firmware
sudo chroot "${ROOT}" chown -R ${USERNAME}.${USERNAME} /usr/local/arduino


echo "**********Creating desktop shortcuts"
sudo mkdir "${ROOT}/home/${USERNAME}/Desktop"

sudo sh -c "cat > '${ROOT}/home/${USERNAME}/Desktop/Arduino IDE.desktop'" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Arduino IDE
Comment=
Exec=/usr/local/arduino/arduino
Icon=emblem-system
Path=/usr/local/arduino
Terminal=false
StartupNotify=false
EOF

sudo sh -c "cat > '${ROOT}/home/${USERNAME}/Desktop/Update Pinoccio Libraries.desktop'" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Update Pinoccio Libraries
Comment=
Exec=sh -c "/usr/local/pinoccio-firmware/update.sh ; sleep 5"
Icon=emblem-symbolic-link
Path=/usr/local/pinoccio-firmware/
Terminal=true
StartupNotify=false
EOF

sudo chroot "${ROOT}" chown -R ${USERNAME}.${USERNAME} "/home/${USERNAME}/Desktop"
sudo chroot "${ROOT}" chmod +x "/home/${USERNAME}/Desktop/Arduino IDE.desktop"
sudo chroot "${ROOT}" chmod +x "/home/${USERNAME}/Desktop/Update Pinoccio Libraries.desktop"


echo "********** Cleaning up the mess I made"
echo "********** Killing off anything blocking us from unmounting"
sudo lsof | grep "${ROOT}" | awk '{ print $2 }' | uniq | sudo xargs kill -9

# Cleanup
echo "**********Dismounting virtual dev, if mounted"
mountpoint -q "${ROOT}/dev"
if [ $? -eq 0 ]; then
  sudo umount "${ROOT}/dev"
  echo "**********Virtual dev dismounted"
fi

mountpoint -q "${ROOT}/proc"
if [ $? -eq 0 ]; then
  sudo umount "${ROOT}/proc"
  echo "**********Virtual proc dismounted"
fi

mountpoint -q "${ROOT}/sys"
if [ $? -eq 0 ]; then
  sudo umount "${ROOT}/sys"
  echo "**********Virtual sys dismounted"
fi

echo "**********Waiting to unmount virtual image"
sleep 10
sudo umount "${ROOT}"
sudo rmdir "${ROOT}"

echo "**********Creating compressed virtual disk template"
VBoxManage convertfromraw "${IMG}" "${VMDK}.tmp" --format vmdk
FULL_SIZE=`stat --format '%s' "${IMG}"`

# Delete the raw image since we no longer need it
rm "${IMG}"

# clonehd defaults to files in ~/.Virtualbox/somewhere, so use
# absolute paths.
VBoxManage clonehd "`pwd`/${VMDK}.tmp" "`pwd`/${VMDK}" --format vmdk --variant Stream
rm "${VMDK}.tmp"

VMDK_SIZE=`stat --format '%s' "${VMDK}"`

VBoxManage createvm --name ${HOSTNAME} --ostype Debian --register --basefolder .
VBoxManage modifyvm ${HOSTNAME} --memory ${RAM} --vram 32
VBoxManage storagectl ${HOSTNAME} --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach ${HOSTNAME} --storagectl "SATA Controller" --type hdd --port 0 --device 0 --medium ${VMDK}
VBoxManage storagectl ${HOSTNAME} --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach ${HOSTNAME} --storagectl "IDE Controller" --type dvddrive --port 0 --device 0 --medium emptydrive
VBoxManage modifyvm ${HOSTNAME} --usb on --usbehci on
VBoxManage export ${HOSTNAME} --manifest -o "${HOSTNAME}.ova"
VBoxManage unregistervm ${HOSTNAME} --delete

echo "Pinoccio VM deployment image is ready at ./${HOSTNAME}.ova"

echo "**********Finished!"
