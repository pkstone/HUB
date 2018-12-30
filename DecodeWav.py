import os
import struct
from os.path import join

audio_file = 'HubROM.wav'
sign = lambda word: (1, -1)[word < 0]

def decode_wav(filename, binary):
    samples_between_zerocross = 0
    current_sign = 1
    ignore_next = False
    bit_count = 0
    next_byte = 0
    ignore_start_bit = True
    ignore_header = True
    header_skip_bytes = 5
    row_count = 0
    out_bytes = []
    byte_count = 1126     #Now that we know where the code ends, we can do this
    
    with open(filename, mode="rb") as f:
        word = 0
        junk = f.read(44)  # Skip header
        while (word < 10) and (word > -10): # Skip "silence"
            word = getWord(f)
            junkword = getWord(f)
        while True:
            word = getWord(f)
            junk = getWord(f)   # Skip empty channel
            this_sign = sign(word)
            if this_sign != current_sign:
                current_sign = this_sign
                ## print( "count: " + str(samples_between_zerocross) )
                if ignore_next:
                    ignore_next = False
                    samples_between_zerocross = 0
                else:
                    next_bit = 1 if samples_between_zerocross < 35 else 0
                    if next_bit: ignore_next = True
                    samples_between_zerocross = 0
                    if ignore_start_bit:
                        ignore_start_bit = False
                    else:
                        next_byte = next_byte >> 1
                        next_byte = next_byte ^ (0b10000000 if next_bit else 0)
                        bit_count += 1
                        if bit_count == 8:
                            if not ignore_header and not header_skip_bytes:
                                # Write byte out to array or console
                                if binary:
                                    # Write byte out to binary array
                                    out_bytes.append(next_byte)
                                else:
                                    # Write byte out console
                                    print ('{0:0{1}X}'.format(next_byte,2), end =" ")
                                    row_count += 1
                                    if row_count > 15:
                                        print ('')
                                        row_count = 0

                                byte_count -= 1
                                if byte_count == 0:
                                    # End of 'interesting' data reached
                                    break
                            else:
                                if not ignore_header:
                                    header_skip_bytes -= 1;
                                else:
                                    if next_byte == 0x2A:        #start byte
                                        ignore_header = False
                            next_byte = 0
                            bit_count = 0
                            ignore_start_bit = True
            else:
                samples_between_zerocross += 1

        # We're here after breaking out of read loop
        if binary:
            newFile = open("HUBROM.bin", "wb")
            outFileBytes = bytes(out_bytes)
            newFile.write(outFileBytes)


def getWord(file):
    try:
        read_tuple = struct.unpack('h', file.read(2))
    except (struct.error):
        # ignore error at EOF, as we won't get here
        return 0
    return read_tuple[0]



decode_wav(audio_file, True)
