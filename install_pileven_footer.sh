EOF

chmod +x /usr/local/sbin/set_pin_alt.py

command -v python2 >/dev/null 2>&1 || {
    echo "WARNING: No 'python2' installed on PATH. You will need to install Python 2.x before rebooting, so pin mode setting can work."
}

echo "Done installing PiLeven support. Please reboot before running the Arduino IDE."
