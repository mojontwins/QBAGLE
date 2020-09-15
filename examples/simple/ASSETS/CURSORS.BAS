nSprites% = 5
'8x8/2/2+2 = 18
DIM cursors%(17, nSprites% - 1)

cursor$ = ""
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "FFF0FFF0"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "00000000"

cursor$ = cursor$ + "0FFFFFF0"
cursor$ = cursor$ + "F00FF00F"
cursor$ = cursor$ + "F00FF00F"
cursor$ = cursor$ + "F00FF00F"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "F00FF00F"
cursor$ = cursor$ + "F00FF00F"
cursor$ = cursor$ + "0FFFFFF0"

cursor$ = cursor$ + "0FFFFFF0"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "F0F0F0FF"
cursor$ = cursor$ + "F000000F"
cursor$ = cursor$ + "0FFFFFF0"

cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "00FFF000"
cursor$ = cursor$ + "0FFFFF00"
cursor$ = cursor$ + "FFFFFFF0"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "000F0000"
cursor$ = cursor$ + "00000000"

SCREEN 7

x% = 0: y% = 8
FOR i% = 1 TO LEN(cursor$)
    m$ = MID$(cursor$, i%, 1)
    'IF m$ = "0" THEN v% = 0 ELSE v% = 240 + VAL("&H" + m$)
    v% = VAL("&H" + m$)
    PSET (x%, y%), v%
    x% = x% + 1: IF x% = 8 THEN x% = 0: y% = y% + 1
NEXT i%


x% = 0: y% = 0
FOR i% = 0 TO nSprites% - 1
    GET (x%, y%)-(7 + x%, 7 + y%), cursors%(0, i%)
    y% = y% + 8
NEXT i%

DEF SEG = VARSEG(cursors%(0, 0))
BSAVE "CURSORS.PUT", VARPTR(cursors%(0, 0)), nSprites% * 36
DEF SEG


FOR i% = 0 TO 500
PUT (INT(RND * 312), INT(RND * 192)), cursors%(0, (INT(RND * nSprites%))), PSET
NEXT i%

