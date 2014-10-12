#!/bin/sh
#
# Uninstaller script for Freetronics PiLeven support on Raspberry Pi
# attempts to remove the things that the install_pileven.sh script
# installs.

if [ `id -u` -ne 0 ]; then
    echo "This uninstall script needs to be run as root"
    exit 1
fi

if [ -e /boot/cmdline.txt.prepilv ]; then
    echo "Moving /boot/cmdline.txt.prepilv back as /boot/cmdline.txt"
    mv /boot/cmdline.txt /boot/cmdline.txt.pilv
    mv /boot/cmdline.txt.prepilv /boot/cmdline.txt
else
    echo "WARNING: /boot/cmdline.txt.prepilv not found. /boot/cmdline.txt is unchanged."
fi

if [ -e /etc/inittab ]; then
    echo "Re-enabling serial port tty in /etc/inittab..."
    sed -i 's/^#\(.\+ttyAMA0\)/\1/' /etc/inittab
    /bin/kill -HUP 1
fi

if [ -e /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules ]; then
    echo "Removing udev rule /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules..."
    rm -f /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules
fi

if [ -e /usr/local/sbin/set_pin_alt.py ]; then
    echo "Removing /usr/local/sbin/set_pin_alt.py..."
    rm /usr/local/sbin/set_pin_alt.py
fi
