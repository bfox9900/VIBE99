# VIBE99
Vibe 2.2 is a universial block editor written in ANS/ISO Forth by Sam Falvo.
It is used here with written permission from the author. 

Vibe99 began as a port of VIBE but has been expanded to operate more like vi. 

It is VERY important to understand that VIBE is NOT like modern editors.
Like vi, VIBE has two modes. "Visual" mode used to cursor around and changes 
pages and editing mode where you can change the actual text. 
Some people love this way or working. Others ... not so much.
On top of that VIBE is  "BLOCK" editor meaning it does not edit text files 
but rather blocks of file space that are 1024 bytes in size. 

### Hardware Requirements
- needs an F18 display for 80 columns or the Classic99 Emulator
- needs the editor Assembler cartridge

### Software Requirements to compile VIBE 
- Camel99 Forth version 2.69 or greater
- Camel99 Forth library disk or the following files on DSK1 
   - DSK1.80COL
   - DSK1.RKEY  
   - DSK1.BLOCKS
   - DSK1.TRAILING
   - DSK1.MARKER
   - DSK1.WORDLISTS



### Starting VIBE80
---------------
1. With the editor assembler cartridge start CAMEL99 FORTH
   Menu option 5 Run program file:  DSK1.CAMEL2.69 or higher

2. Inside Forth type:  INCLUDE DSK2.VIBE99

3. If you don't have a block file you must make one like this:

```   
DECIMAL  <enter>
80  S" DSK2.MYBLOCKS" MAKE-BLOCKS <enter>
```

This will create an 80K byte file on disk2.

To start the editor type VI DSK2.MYBLOCKS  <enter>

