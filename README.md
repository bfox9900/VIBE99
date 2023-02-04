# VIBE99
Vibe 2.2 is a universial block editor written in ANS/ISO Forth by Sam Falvo.
It is used here with written permission from the author. 

Vibe99 began as a port of VIBE but has been expanded to operate even
more like vi with more commands added and a ":" command line.

VIBE99 operates on a specific file type on TI-99 that consists of 1K
blocks of text or data. It does not use the DV80 file format that is
the default text file used for source code by many TI-99 programs. 

### Hardware Requirements
- F18 display or Classic99 Emulator or any emulator that has F18 support
- 32K expanded memory
- TI-99 disk system 


### Starting VIBE80
---------------
1. With the editor assembler cartridge start CAMEL99 FORTH
   Menu option 5 Run program file:  DSK1.CAMEL2.69 or higher

2. Inside Forth type:  INCLUDE DSK2.VIBE99

3. If you don't have a block file you must make one like this:
   
`DECIMAL  <enter>
80  S" DSK2.MYBLOCKS" MAKE-BLOCKS <enter>`

This will create an 80K byte file on disk2.

To start the editor type VI DSK2.MYBLOCKS  <enter>

