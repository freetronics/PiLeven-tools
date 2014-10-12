#!/usr/bin/env python
import mmap, types, os, struct, argparse, sys, time
"""
Program to get/set ALT pin functions on Raspberry Pi GPIO pin(s).

Uses /dev/mem so needs to be run as root.

For details on ALT functions, see:
http://elinux.org/Rpi_Low-level_peripherals#GPIO_hardware_hacking

or the BCM2835 Peripherals Datasheet PDF, page 102:
http://www.raspberrypi.org/wp-content/uploads/2012/02/BCM2835-ARM-Peripherals.pdf

Run with -h argument for a usage summary.

Copyright (C) 2014 Freetronics Pty Ltd
Licensed under the New BSD License as described in the file LICENSE.

Originally written by Angus Gratton (my fault, everyone!).
"""

GPIO_REGS= 0x20200000

def main():
    args = arguments.parse_args()

    # open devmem
    try:
        f = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
        mem = mmap.mmap(f, mmap.PAGESIZE, mmap.MAP_SHARED, mmap.PROT_WRITE | mmap.PROT_READ, offset=GPIO_REGS)
        os.close(f)
    except OSError as e:
        if e.errno == 13: # permission failure
            raise RuntimeError("Permission denied openening /dev/mem. Are you running as root?")
        else:
            raise RuntimeError("Unexpected error opening /dev/mem: %s" % e)

    if args.gpio is None and args.alt is None:
        # print all GPIO functions
        for gpnum in range(32):
            gpio = GPIO(mem, gpnum)
            print("GPIO %2d: %s" % (gpnum, FSEL_VALUES[gpio.get_fsel()]))
    elif args.alt is None:
        # print GPIO function
        gpio = GPIO(mem, args.gpio)
        print("GPIO %2d: %s" % (args.gpio, FSEL_VALUES[gpio.get_fsel()]))
    else:
        # set GPIO function
        fsel = arg_to_fsel(args.alt)
        gpio = GPIO(mem, args.gpio)
        gpio.set_fsel(fsel)
    mem.close()


def arg_to_fsel(arg):
    """
    Convert a string argument to a FSEL (function selection) value for the BCM2835
    """
    arg = arg.upper()
    # argument can be a string (ie ALT0 or INPUT), or an alt number
    for i in range(len(FSEL_VALUES)):
        if arg == FSEL_VALUES[i]:
            return i
    raise RuntimeError("Invalid FSEL argument. Valid choices: INPUT, OUTPUT, ALT0-5")

FSEL_VALUES = [
    "INPUT", # 0
    "OUTPUT", # 1
    "ALT5", # 2
    "ALT4", # 3
    "ALT0", # 4
    "ALT1", # 5
    "ALT2", # 6
    "ALT3", # 7
]

class GPIO(object):
    def __init__(self, mem, gpnum):
        self.mem = mem
        self.gpnum = gpnum
        self.gpfsel = gpnum//10 * 4
        self.bitshift = (gpnum % 10) * 3
        self.bitmask = 0b111 << self.bitshift

    def get_fsel(self):
        """ Return selected function (fsel index number) for given GPIO pin """
        return ( self._read_word() & self.bitmask ) >> self.bitshift

    def set_fsel(self, fsel):
        """ Set new selected function (fsel index number) for given GPIO pin """
        orig = self._read_word() & ~self.bitmask
        self._write_word(orig | ((fsel << self.bitshift) & self.bitmask) )

    def _read_word(self):
        result = struct.unpack('<L', self.mem[self.gpfsel:self.gpfsel+4])[0]
        return result

    def _write_word(self,val):
        self.mem[self.gpfsel:self.gpfsel+4] = struct.pack('<L', val)

# Parser for command line arguments
arguments = argparse.ArgumentParser(description='Set or Get Raspberry Pi GPIO ALT function.')
arguments.add_argument('gpio', metavar='GPIO', help="GPIO number to set/get. Leave blank to get all pibns.", nargs='?', type=int)
arguments.add_argument('alt', metavar='ALT', help="Function to set. ALT<0-5>, INPUT or OUTPUT. Leave blank to read back current config instead. For INPUT/OUTPUT it's recommended to use regular /sys GPIO functions.", nargs='?')

if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        print(e)
        sys.exit(1)
