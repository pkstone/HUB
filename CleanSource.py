# Strip the machine code from the fully-beautified HUB source,
# in order to test it via reassembly and comparison with origial object code

import os
import struct
from os.path import join

in_file = 'HUB_Source_Formatted.txt'
out_file = 'HUB.asm'


with open(in_file) as f_in, open(out_file, 'w') as f_out:  
    for cnt, line in enumerate(f_in):
        if len(line.strip()) == 0:
            f_out.write(line.strip())
        else:
            # strip off the first 29 characters of the line
            f_out.write(line[29:])
       
