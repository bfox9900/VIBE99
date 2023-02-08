\ VIBE99  for Camel99 Forth, with more vi commands           Jan 31 2023  

\ VIBE Release 2.2 
\ Copyright (c) 2001-2003 Samuel A. Falvo II
\ All Rights Reserved
\   Highly portable block editor --

\ * Use with written permission for Camel99 Forth *

\ USAGE: VI <filepath> opens BLOCK FILE,
\        VI (no parameter) goto last used block
\        VIBE ( n -- ) Edits block 'n'.  Sets SCR variable to 'n'.
\
\ 2.1 -- Fixed stack overflow bugs; forgot to DROP in the non-default
\        key handlers.
\
\ 2.2 Ported to CAMEL99 Forth B. Fox 2019
\     Removed some character constants to save space.
\     Changed TYPE for VTYPE.
\     Removed shadow block function
\     Added some block navigation commands

\ 2.3 Fixed keyboard bugs for TI-99/4A
\     VI command takes a filename parameter like real VI
\     simplfied wipe screen logic and saved bytes
\     Add $ command: goto end of line
\     Add PC delete KEY for Classic99

\ 2.4 Change CMOVE, CMOVE>  to MOVE for Camel99 2.69

\ 2.5 Changed [ ]  key bindings to ^f ^b like vi
\     Added w and b commands for word jumping 

( libary includes for Camel99 Forth)

NEEDS DUMP      FROM DSK1.TOOLS
NEEDS 80COLS    FROM DSK1.80COL
NEEDS RKEY      FROM DSK1.RKEY
NEEDS BLOCK     FROM DSK1.BLOCKS
NEEDS -TRAILING FROM DSK1.TRAILING
NEEDS MARKER    FROM DSK1.MARKER

\ MARKER /VIBE
NEEDS WORDLIST  FROM DSK1.WORDLISTS
ONLY FORTH DEFINITIONS 

VOCABULARY EDITOR 

ONLY FORTH ALSO EDITOR DEFINITIONS 

HERE

( Editor CHAR Constants )
CHAR i  CONSTANT 'i   \ Insert mode
CHAR c  CONSTANT 'c   \ Command mode
CHAR r  CONSTANT 'r   \ replace mode 
CHAR d  CONSTANT 'd   
CHAR P  CONSTANT 'P  
CHAR y  CONSTANT 'y

\ block constants 
DECIMAL
       64 CONSTANT WIDTH
 WIDTH 1- CONSTANT LENGTH
       80 CONSTANT MAXBLKS
 1024     CONSTANT 1K

\ hex constants 
HEX
  0F CONSTANT $0F
  F0 CONSTANT $F0
  7F CONSTANT $7F

( Editor State )
 VARIABLE SCR       \ Current block
 VARIABLE X         \ Cursor X position 0..LENGTH
 VARIABLE Y         \ Cursor Y position 0..15
 VARIABLE MODE      \ current mode: INSERT or command ( 'i OR 'c

\ CMDNAME the command string, is built, found and executed
CREATE CMDNAME    5 C,  CHAR $ C, CHAR $ C,  0 C, 0 C, 0 C,

\ direct to video type 
: VTYPE  ( addr len -- ) TUCK  VPOS SWAP VWRITE   VCOL +! ;

CREATE PATH  16 ALLOT  PATH OFF 

( Editor Display )
HEX 
: MODE.    40 VCOL !  MODE @ 5F AND EMIT ;
 DECIMAL
: BLANKS   BL FILL ; 
: PATH.    26 VCOL !   PATH COUNT VTYPE ;
: PROMPT   0 19 AT-XY VPOS WIDTH BL VFILL ;
: SCR.     0 0 AT-XY S" Block: " VTYPE  SCR @ . ;
: HEADER   SCR. PATH. MODE. ;
: 16-S     S" ----------------" VTYPE ;
: WIDTH-S  16-S 16-S 16-S ;
: RULE     S" +---------" VTYPE ;
: RULER    SPACE RULE RULE RULE RULE RULE RULE S" +----" VTYPE CR ;
: BORDER   SPACE WIDTH-S CR ;
: ROW      ( addr -- addr') DUP LENGTH VTYPE 64 + ; \ FAST
\ : ROW    ( addr -- addr') DUP LENGTH TYPE LENGTH + ;   \ SLOW
: LINE     ( addr -- addr') [CHAR] | EMIT  ROW CR ;
: 4LINES   ( addr -- ) LINE LINE LINE LINE ;
: 'BLOCK   ( -- addr) SCR @ BLOCK ;
: 16LINES  'BLOCK  4LINES 4LINES 4LINES 4LINES DROP ;
: CARD     0 1 AT-XY RULER 16LINES BORDER ;
: CURSOR   X @ 1+  Y @ 2+ AT-XY ;
: SCREEN   HEADER CARD PROMPT  CURSOR ;

( Editor State Control )
\ change cursor character to show mode as well
: INSERT   'i MODE !         30 CURS ! ; 
: REPLACE  'r MODE !  [CHAR] _ CURS ! ;
: CMD      'c MODE !        31 CURS ! ;

: BOUNDED   ( addr n -- ) 0 MAX MAXBLKS MIN SWAP ! ;
: PREVBLOCK  SCR DUP @ 1- BOUNDED ;
: NEXTBLOCK  SCR DUP @ 1+ BOUNDED ;
\ : TOGGLESHADOW 1 SCR @ XOR SCR ! ;

( Editor Cursor Control )
: FLUSHLEFT  X OFF ;
: BOUNDX     X @  0 MAX LENGTH MIN X ! ;
: BOUNDY     Y @  0 MAX 15 MIN Y ! ;
: BOUNDXY    BOUNDX BOUNDY ;
: LEFT       X 1-! BOUNDXY ;
: RIGHT      X 1+! BOUNDXY ;
: UP         Y 1-! BOUNDXY ;
: DOWN       Y 1+! BOUNDXY ;
\ : beep     7 EMIT ;
: NEXTLINE   Y @ 15 < IF FLUSHLEFT DOWN THEN ;
: NEXT       X @ LENGTH = IF NEXTLINE EXIT  THEN RIGHT ;

( Editor Insert/Replace Text )
: 64*        6 LSHIFT ;  \  x64 
: WHERE ( col row -- addr) 64* +  'BLOCK + ;
: WH         X @ Y @ WHERE ;
: SOL        0  Y @ WHERE ;
: EOL        LENGTH Y @ WHERE ;
: PUTC       WH C! UPDATE NEXT ;
: -EOL?      X @ LENGTH < ;
: OPENR      WH DUP 1+ LENGTH X @ - MOVE ;
: OPENRIGHT  -EOL? IF OPENR THEN ;
: INSERTING?  MODE @ 'i = ;
: CHR         INSERTING? IF OPENRIGHT THEN PUTC ;
: EOTEXT      SOL LENGTH -TRAILING NIP X ! ;


: BELOW   ( -- n) 'BLOCK 1K + WH - ; \ n=bytes below cursor 
: NXTWRD  ( addr n -- addr' )  BL SKIP BL SCAN  DROP ;
: >OFFSET ( addr n -- n') 'BLOCK -  1K 1- MIN ;
: ADR>XY  ( addr --) WIDTH /MOD   Y !  1+ X ! BOUNDXY ;

\ scans entire block for next word 
: NEXTWORD   WH BELOW  NXTWRD  >OFFSET ADR>XY ; 

: -ASCII ( addr len -- addr len') \ scan back until BL
    1- 0 MAX 
    OVER + ( start end )
    BEGIN 
       2DUP <> 
    WHILE           \ test end of string 
       DUP C@ BL <> 
    WHILE           \ test for blank 
        1-          \ dec address 
    REPEAT 
    THEN 
    OVER - 0 MAX 
;    

: PRVWRD    -TRAILING  -ASCII  ;
: PREVWORD  'BLOCK WH OVER - PRVWRD NIP  ADR>XY  ;    

( Editor Backspace/Delete )
: PADDING  BL EOL C! UPDATE ;
: DEL      WH DUP 1+ SWAP LENGTH X @ - MOVE ;
: DELETE   -EOL? IF DEL THEN PADDING ;
: BS        LEFT DELETE ;
: BACKSPACE  X @ 0 > IF BS THEN ;

( Editor Carriage Return )
: NEXTLN    EOL 1+ ;
: #CHRS     'BLOCK 1K + NEXTLN - WIDTH - ;
: COPYDOWN  Y @ 14 < IF NEXTLN DUP WIDTH + #CHRS MOVE THEN ;
: BLANKDOWN NEXTLN WIDTH BLANKS UPDATE ;
: SPLITDOWN WH NEXTLN 2DUP SWAP - MOVE ;
: BLANKREST WH NEXTLN OVER -  BLANKS ;
: OPENDOWN  COPYDOWN BLANKDOWN ;
: SPLITLINE OPENDOWN SPLITDOWN BLANKREST ;
: RETRN     INSERTING? IF SPLITLINE THEN FLUSHLEFT NEXTLINE ;
: ENTER    Y @ 15 < IF RETRN THEN ;

\ copy paste support 
VARIABLE TP
: TP+!  ( n ) TP +! TP @ 0 MAX  TP ! ; \ circular increment/decrement
HEX 
: TEMP  ( -- Vaddr) TP @ 64* C00 +  ;  \ VDP used as line buffers
DECIMAL 
: CUT      1 TP+! SOL TEMP WIDTH VWRITE UPDATE ;
: YANK     CUT DOWN ; 
: ERASELN  ( n ) 0 SWAP  WHERE  LENGTH BLANKS ;
: PULLUP   NEXTLN SOL  BELOW  MOVE  15 ERASELN ;
: DELINE   CUT PULLUP   ;
: PUSHDOWN Y @ 14 < IF SOL NEXTLN  BELOW MOVE  THEN ;
: (PASTE)  PUSHDOWN  TEMP SOL WIDTH VREAD  -1 TP+! ;
: PASTE    TP @ 0= IF  BEEP EXIT THEN  
           TP @ 0 ?DO  (PASTE) LOOP UPDATE ;

( Editor Wipe Block ) \ simplified by BFox
HEX
: >UPPER  ( c -- c')  5F AND ;
DECIMAL
: MSG         PROMPT ." Are you sure? (Y/N) " ;
: CLRMSG      PROMPT  WIDTH SPACES ;
: NO?         MSG KEY >UPPER CLRMSG [CHAR] Y <> ;
: ?CONFIRM    NO? IF R> DROP THEN ;
: HOME        X OFF  Y OFF ;
: WIPE        ?CONFIRM 'BLOCK 1K BLANKS HOME  UPDATE  ;

( Editor Keyboard Handler CMDWORD encoding)
\ CMD name key:   $$ _ _ _
\                    | | |
\ 'c'=command mode --+ | |
\ 'i"=ins/repl mode    | |
\                      | |
\ Key code (hex#) -----+-+
\
\ Called with ( k -- ) where k is the ASCII key code.
DECIMAL
: KEYBOARD    RKEY $7F AND ; \ repeating key 
: KEY         KEY  $7F AND ; \ non-repeating 

: CMD?        MODE @ 'c = ;
: INS?        MODE @ 'i =   MODE @ [CHAR] r =  OR ;
: MODE!       INS? 'i AND CMD? 'c AND OR  CMDNAME 3 + C! ;
: >HEX        DUP 9 > IF 7 + THEN [CHAR] 0 + ;
: H!          DUP $F0 AND  4 RSHIFT >HEX  CMDNAME 4 + C! ;
: L!          $0F AND >HEX CMDNAME 5 + C! ;
: NAME!       ( c -- ) MODE! H! L! ;
: NOMAPPING   ['] HONK CMD? AND   ['] CHR INS? AND  OR ;

\ key command interpreter
\ : .CMDNAME    68 0 AT-XY CMDNAME COUNT TYPE ; \ debugging
: HANDLERWORD ( c --) NAME!  CMDNAME FIND 0= IF  DROP NOMAPPING THEN ;
: HANDLER  DUP  HANDLERWORD EXECUTE ;
: CMDLOOP   BEGIN  KEYBOARD HANDLER  SCREEN  AGAIN ;
: VIBE ( n -- )  SCR ! DECIMAL PAGE  HOME CMD SCREEN  CMDLOOP ;
: EDIT   SCR @ VIBE ;

\ ':' line interpreter for that real vi sensation
: INPUT       PAD DUP LENGTH ACCEPT ;
: COMMANDLINE PROMPT ." :" INPUT EVALUATE  SCREEN ;

: .NOTSAVED  ." Not saved. Use FLUSH to update disk." ;
: .FORTH     PROMPT ." Forth" ;
: CONSOLE    ONLY FORTH DEFINITIONS ALSO EDITOR  ABORT ;

( VI Command mode keys)
( Place at end for faster lookup )
: $$c06  DROP NEXTBLOCK ;         \ ^F  ( CHANGE FROM VIBE )
: $$c02  DROP PREVBLOCK ;         \ ^B  ( CHANGE FROM VIBE )
: $$c1A  DROP PAGE .NOTSAVED CONSOLE ; \ ^Z to command shell 
: $$c24  DROP EOTEXT ;            \ $  goto end of line
: $$c30  DROP FLUSHLEFT ;         \ 0  goto start of line   

: $$c41  DROP EOTEXT REPLACE ;    \ A  append at end of line 
: $$c47  DROP FLUSHLEFT 15 Y ! ;  \ G  bottom line 
: $$c48  DROP FLUSHLEFT Y OFF ;   \ H  goto home, top left
: $$c49  DROP FLUSHLEFT INSERT ;  \ I
: $$c4D  DROP WIDTH 2/ X ! ;      \ M  middle of line 
: $$c52  DROP REPLACE ;           \ R
: $$c50  DROP PASTE ;             \ P  paste before cursor line 
\ : $$c5C  DROP TOGGLESHADOW ;    \ \
: $$c61  DROP NEXT REPLACE ;      \ a  append after cursor  
: $$c62  DROP PREVWORD  ;         \ b  
: $$c64  DROP DELINE ;            \ d  delete line 
: $$c68  DROP LEFT ;              \ h
: $$c69  DROP INSERT ;            \ i
: $$c6A  DROP DOWN ;              \ j
: $$c6B  DROP UP ;                \ k
: $$c6C  DROP RIGHT ;             \ l
: $$c72  DROP KEY PUTC UPDATE ;   \ r replace char at cursor 
: $$c75  DROP EMPTY-BUFFERS SCREEN ;  \ u undo since last flush
: $$c77  DROP NEXTWORD  ;         \ w
: $$c78  DROP DELETE ;            \ x delete char at cursor 
: $$c79  DROP KEY 'y = IF YANK THEN ; \ yy yank line 

( Insert mode Commands: backspace, delete, et. al. )
: $$i04  DROP DELETE ;            \ ^D
: $$i03  DROP DELETE ;            \ PC delete key
: $$i08  DROP BACKSPACE ;         \ Backspace
: $$i0D  DROP ENTER ;             \ Enter
: $$i0F  DROP CMD   ;             \ (esc) command mode
: $$c5A  DROP WIPE ;              \ Z
: $$c6F  DROP OPENDOWN DOWN ;     \ o
: $$c4F  DROP UP OPENDOWN DOWN ;  \ O
: $$c3A  DROP COMMANDLINE  ;      \ ':' vi style 
\ : $$i7F  DROP BACKSPACE ;       \ DEL -- for Unix

\ command line commands are just Forth words 
\ duplicates in upper and lower case 
: Q!    .FORTH  CR .NOTSAVED CONSOLE ;
: q!    Q! ;  

: w     FLUSH  SCREEN ;
: W     w ; 

: wq    FLUSH .FORTH CONSOLE ;
: WQ    wq ; 

: vibe  VIBE ;
: G     ( n -- ) VIBE ;
: KC    TP OFF ;  \ kill clipboard 
: edit  EDIT ;
\ \\\\\\\\\\\\\\\\\\\\\\\\\\ VIBE ENDS \\\\\\\\\\\\\\\\\\\\\\\\\\
\ VI command additions
: USE ( <path>)   \ open a block file to use 
  BHNDL @ IF  CLOSE-BLOCKS THEN 
  PARSE-NAME DUP 0> 
  IF 2DUP PATH PLACE  OPEN-BLOCKS  SCR OFF  HOME  THEN ;

: LIST    ( n -- ) SCR ! PAGE SCREEN 50 18 AT-XY ;
: INDEX   ( from to -- )
  1+ SWAP ?DO  CR I 4 .R 2 SPACES I BLOCK 64 TYPE ?BREAK  LOOP ;


SCR OFF
HERE SWAP - DECIMAL . .( bytes)

\ USE DSK7.FBLOCKS 
