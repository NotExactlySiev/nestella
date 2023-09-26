import sys

romFile = sys.argv[1]
print(romFile)

rom = []

with open(romFile, 'rb') as f:
    rom = f.read()

vecs = rom[-6:]
NMI = (vecs[1] << 8) | vecs[0]
RES = (vecs[3] << 8) | vecs[2]
IRQ = (vecs[5] << 8) | vecs[4]
print(RES)

newRES = 0xC000
newNMI = 0xD000

rom = list(rom)

rom[-6] = newNMI & 0xFF
rom[-5] = newNMI >> 8
rom[-4] = newRES & 0xFF
rom[-3] = newRES >> 8

OUTFILE = "rom.bin"

with open(OUTFILE, 'wb') as f:
    f.write(bytes(rom))

