#!/bin/sh
#
# Installer script for Freetronics PiLeven support on Raspberry Pi.
#
# This installer does 3 things:
# * Disables Linux console serial port output
# * Installs the tool /usr/local/set_pin_alt.py to allow setting alternative GPIO functions.
# * Automatically sets up the built-in serial port at startup so it will automatically work
#   with PiLeven

if [ `id -u` -ne 0 ]; then
    echo "This install script needs to be run as root"
    exit 1
fi

if grep -q ttyAMA0 /boot/cmdline.txt 2>/dev/null; then
    echo "Backing up /boot/cmdline.txt as /boot/cmdline.txt.prepilv..."
    cp /boot/cmdline.txt /boot/cmdline.txt.prepilv
    echo "Disabling Linux console output to serial port..."
    # matches console=ttyAMA0,12345 or kgdboc=ttyAMA0,12345
    sed -i 's/[a-z]*=ttyAMA0[0-9,]* *//g' /boot/cmdline.txt
elif ! [ -e /boot/cmdline.txt ]; then
    echo "WARNING: /boot/cmdline.txt not found. You will need to manually remove any console=ttyAMA0 line from kernel boot arguments!"
fi

if grep ttyAMA0 /etc/inittab 2>/dev/null; then
    echo "Disabling serial port login console in /etc/inittab..."
    sed -i 's/.\+ttyAMA0/#\0/' /etc/inittab
elif [ -x /usr/bin/systemctl ]; then
    echo "Disabling serial port console..."
    systemctl disable serial-getty@ttyAMA0.service # silent if doesn't exist
else
    echo "WARNING: Console mechanism not found. You will need to disable the ttyAMA0 console manually."
fi

if [ -d /etc/udev/rules.d ]; then
    cat > /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules <<EOF
# /dev/ttyAMA0 needs two things (apart from disabled console) to work with Freetronics PiLeven
#
# - RTS pin on GPIO 17 needs to be enabled, this acts as auto-reset for Arduino upload.
# - A symlink as /dev/ttyS99 is created as the Arduino IDE doesn't see /dev/ttyAMAx as a valid serial port
#
KERNEL=="ttyAMA0", ACTION=="add", SYMLINK+="ttyS99", RUN+="/usr/local/sbin/set_pin_alt.py 17 ALT3"
EOF
else
    echo "WARNING: no directory /etc/udev/rules.d. Cannot installed the PiLeven udev rule."
fi

echo "Installing /usr/local/sbin/set_pin_alt.py..."
cat > /usr/local/sbin/set_pin_alt.py <<EOF
#!/usr/bin/env python2
