import os
import struct
import serial
import time
from os.path import join

in_file = 'a.out'
file_size = os.path.getsize(in_file)
print("abspath: ", os.path.abspath(in_file))
ser = serial.Serial('/dev/cu.usbmodem1421', 9600)
print("serial port name: ", ser.name)         # check which port was really used
print("filesize: ", file_size)

# This is critical: !!!
time.sleep(2)   #Give arduino serial device time to set up

#Write the file size out as first two bytes
packet = bytearray()
file_size_lo = file_size & 0b0000000011111111
packet.append(file_size_lo)
#print("file_size_lo = ", file_size_lo)
file_size_hi = (file_size & 0b1111111100000000) >> 8
packet.append(file_size_hi)
#print("file_size_hi = ", file_size_hi)
ser.write(packet)

with open(in_file, "rb") as f:  
    ba = bytearray(f.read())
ser.write(ba)
