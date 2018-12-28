import os
import struct
from os.path import join

in_file = 'Hub.asm'
out_file = 'HUB.src'


with open(in_file) as f_in, open(out_file, 'w') as f_out:  
    for cnt, line in enumerate(f_in):
        if len(line.strip()) == 0:
            f_out.write(line.strip())
        else:
            f_out.write(line[16:])
       
