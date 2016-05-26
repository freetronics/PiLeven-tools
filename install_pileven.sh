#!/bin/sh
#
# Installer script for Freetronics PiLeven support on Raspberry Pi.
#
# This installer does up to 4 things:
#
# * (Pi 3 only), adds a Device Tree overlay to move the Bluetooth
#   serial UART connection to the "mini-UART" to free up the main UART for PiLeven.
#
# * Disable Linux console serial UART output (via kernel command line
#   and systemd getty or inittab)
#
# * Adds a "udev rule" to configure the built-in serial port & GPIO
#   pins at startup so they will work with PiLeven & Arduino
#
#   (GPIO 17 is set to UART0 RTS (ALT3), GPIOs 14 & 15 are set to
#    UART0 TX/RX (ALT0).
#
# * Installs wiringpi for the /usr/bin/gpio pin configuration tool.
#
if [ `id -u` -ne 0 ]; then
    echo "This install script needs to be run as root"
    exit 1
fi

echo "Installing PiLeven support..."
echo "***"

for SERIAL in ttyAMA0 serial0; do

    if grep -q =${SERIAL} /boot/cmdline.txt 2>/dev/null; then
		if ! [ -f /boot/cmdline.txt.prepilv ]; then
  			echo "Backing up /boot/cmdline.txt as /boot/cmdline.txt.prepilv..."
			cp /boot/cmdline.txt /boot/cmdline.txt.prepilv
		fi
		echo "Disabling Linux console output to serial port ${SERIAL}..."
		# matches console=${SERIAL},12345 or kgdboc=${SERIAL},12345
		sed -i "s/[a-z]*=${SERIAL}[0-9,]* *//g" /boot/cmdline.txt
	elif ! [ -e /boot/cmdline.txt ]; then
		echo "WARNING: /boot/cmdline.txt not found. You will need to manually remove any console=${SERIAL} line from kernel boot arguments!"
	fi

done

echo "***"

if [ -f /dev/inittab ] && grep ttyAMA0 /etc/inittab 2>/dev/null; then
	echo "Disabling serial port login console in /etc/inittab..."
	sed -i 's/.\+ttyAMA0/#\0/' /etc/inittab
elif [ -x /bin/systemctl ]; then
	echo "Disabling serial port console..."
	/bin/systemctl disable serial-getty@ttyAMA0.service # silent if doesn't exist
	/bin/systemctl disable serial-getty@serial0.service
else
    echo "WARNING: Console mechanism not found. You will need to disable the ttyAMA0/serial0 console manually."
fi

echo "***"

if [ -d /etc/udev/rules.d ]; then
    echo "Installing new udev rule /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules"
    cat > /etc/udev/rules.d/99-PiLeven-ttyAMA0-config.rules <<EOF
# /dev/ttyAMA0 needs three things (apart from disabled console) to work with Freetronics PiLeven
#
# - RTS pin on GPIO 17 needs to be enabled, this acts as auto-reset for Arduino upload.
# - A symlink as /dev/ttyS99 is created as the Arduino IDE doesn't see /dev/ttyAMA0 as a valid serial port
# - Set group to 'dialout' if a dialout group exists on this system.
#
KERNEL=="ttyAMA0", ACTION=="add", SYMLINK+="ttyS99", RUN+="/usr/bin/gpio -g mode 17 alt3", RUN+="/usr/bin/gpio -g mode 14 alt0", RUN+="/usr/bin/gpio -g mode 15 alt0", GROUP="dialout"
EOF
else
    echo "WARNING: no directory /etc/udev/rules.d. Cannot installed the PiLeven udev rule."
fi

# Raspberry Pi 3 needs dtoverlay to swap Bluetooth from Pi
#
# Identify Pi 3 as the second last hex digit in the cpuinfo revision
# field should always be 3. See here:
# https://github.com/AndrewFromMelbourne/raspberry_pi_revision
#
if grep -q "^Revision\s*:\s*....8.$" /proc/cpuinfo; then
    echo "***"
    
    if grep -q "^dtoverlay=\(pi3-miniuart-bt\|pi3-disable-bt\)" /boot/config.txt; then
	echo "UART0 on pin header GPIO 14/15 is already enabled in /boot/config.txt."
    else
	echo "Appending dtoverlay=pi3-disable-bt to /boot/config.txt to free up UART0 for PiLeven..."
	echo "(See /boot/overlays/README for details.)"
	echo ""
	echo "Check the Getting Started guide for instructions on using Bluetooth & PiLeven at the same time."
	echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt
    fi
fi

echo "***"

# check for wiringpi's GPIO tool
if [ -e /usr/bin/gpio ] && ( /usr/bin/gpio -v | grep -q "^Raspberry Pi Details" ); then
    echo "wiringpi & its /usr/bin/gpio tool already installed, skipping installation."
elif [ -e /usr/bin/apt-get ]; then
    echo "Attempt to install wiringpi from Raspbian..."
    /usr/bin/apt-get install wiringpi
fi

echo "***"

if ! [ -e /usr/bin/gpio ] || ! ( /usr/bin/gpio -v | grep -q "^Raspberry Pi Details" ); then
    echo "wiringpi does not seem to be installed or is not working properly."
    echo "It is required for the /usr/bin/gpio tool."
    echo ""
    echo "Find information about installing wiringpi at http://wiringpi.com/"
else
    echo "Done installing PiLeven support. Please reboot before running the Arduino IDE."
fi
