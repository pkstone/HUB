import os
import struct
from os.path import join

data_file = '/Users/ps/Documents/PD/SYM_Memory/SYM_Mem.bin'
out_file = '/Users/ps/Documents/PD/SYM_Memory/SYM_Mem_MOD.bin'

def splice_SYM_data():
    fh = open(data_file, "rb")
    ba = bytearray(fh.read())

    for x in range(0, 0x100):
        ba[0x2000+x] = x
    for x in range(0, 0x100):
        ba[0x2100+x] = 255 - x
        
    newFile = open(out_file, "wb")
    newFile.write(ba)
    print ("Glack.")

splice_SYM_data()
