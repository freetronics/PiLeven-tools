# PiLeven Tools

These are some small tools for the Freetronics PiLeven "Arduino Uno
compatible Raspberry Pi expansion" board.

For steps involved in configuring the PiLeven, see the
[Freetronics PiLeven Getting Started Guide](http://freetronics.com/pages/pileven-getting-started-guide)

## Tools in this repository

* **set_pin_alt.py** is a Python script allowing you to easily set the
  "[alternative pin function](http://elinux.org/Rpi_Low-level_peripherals#General_Purpose_Input.2FOutput_.28GPIO.29)"
  ALT0-ALT5 for any BCM2835 GPIO pin. This may be useful for other Raspberry Pi GPIO config tasks.

* **Makefile** and **install_pileven_xxx.sh** are the ingredients that output a single **install_pileven.sh** installer script for easy setup of PiLeven on most Raspberry Pi Linux distros (see the [Getting Started Guide](http://freetronics.com/pages/pileven-getting-started-guide) for details on how to use these).
