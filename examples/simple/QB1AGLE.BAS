'' ===========================================
''                 QB1AGLv2.0 EGA
'' ===========================================
'' COPYLEFT 1997, 1998, 2002, 2016 LS Produkt.
'' ===========================================
''   Compile using Microsoft QuickBASIC v4.5

'' Uses assorted mouse driver by Unkwown (sorry)
'' Uses S3M Player by Bisqwit (http://iki.fi/bisqwit/)
'' Uses DMAPLAY by Mike Huff, Martin Rampersad & Toshi Horie
'' Uses SB detection routines by Alexander Verhaeghe

'' Mouse
DECLARE SUB MOUSEstatus (lb%, rb%, xm%, ym%)
DECLARE SUB MOUSEdriver (ax%, bx%, cx%, dx%)
DECLARE SUB MOUSEinitLib ()
DECLARE FUNCTION MOUSEinit% ()

'' S3M player by bisqwit
DECLARE SUB FMtimer ()
DECLARE SUB FMbeSilent ()
DECLARE SUB FMwrite (i%, d%)
DECLARE SUB FMload (fs$)
DECLARE SUB FMnoteoff (chan%, ope%)
DECLARE SUB FMMPUwrite (B%)
DECLARE SUB FMplayrowfrom (pat$, ofs%, effnum%)
DECLARE SUB FMtouch (chan%, ope%, vol%, ins%)
DECLARE SUB FMupdate (chan%, ope%, period%, ins%, vol%)
DECLARE SUB FMend ()
DECLARE FUNCTION FMinit% ()
DECLARE FUNCTION FMMPUDetect% ()
DECLARE FUNCTION FMMPUVol% (vol%, ins%)
DECLARE FUNCTION FMnote2period% (note%, oct%, ins%)
DECLARE FUNCTION FMVibVal% (ind%, mode%)

'' DMAPLAY by Mike Huff, Martin Rampersad & Toshi Horie
DECLARE SUB DMAgetBlaster ()
DECLARE SUB DMAwriteDAC (byte%)
DECLARE SUB DMAwriteDSP (byte%)
DECLARE SUB DMAspeakerState (OnOff%)
DECLARE SUB DMAplayVOC (file$, freq&)
DECLARE SUB DMAplayVOCBG (file$, freq&)
DECLARE SUB DMAplay (segment&, offset&, length&, freq&)
DECLARE FUNCTION DMAdone% ()
DECLARE FUNCTION DMAreadDSP% ()
DECLARE FUNCTION DMAresetDSP% ()
DECLARE FUNCTION DMAdspVersion! ()
DECLARE FUNCTION DMAspeakerStatus% ()

'' Mine
DECLARE SUB EGAloadPut (x%, y%, file$)
DECLARE SUB PokeString (segment%, offset%, code$)
DECLARE SUB QAGLloadPut (segment%, offset%, fileNoExt$, x%, y%)
DECLARE SUB QAGLloadCursors (fileName$)
DECLARE SUB QAGLwt (x%, y%, crsr%)
DECLARE SUB QAGLmouseLimit (x%, y%)
DECLARE SUB QAGLsve ()
DECLARE SUB QAGLrec ()
DECLARE SUB QAGLbutton (segment%, offset%, T$, x%, y%, w%, status%)
DECLARE SUB QAGLloadBsv (segment%, offset%, fileNoExt$)
DECLARE SUB QAGLloadPal (fileName$)
DECLARE SUB QAGLadvanceScriptTo (f%, fileName$, label$)
DECLARE SUB QAGLaction (action$, zone$, x%, y%)
DECLARE SUB QAGLprint (text$)
DECLARE SUB QAGLopenBox (type$)
DECLARE SUB QAGLparseFileForLabels (fileName$)
DECLARE SUB QAGLfancyBoxWire (x0%, y0%, x1%, y1%)
DECLARE SUB QAGLcenter (T$)
DECLARE SUB QAGLactionStatusBar ()
DECLARE FUNCTION QAGLpreprocess$ (word$)
DECLARE FUNCTION QAGLrunScript% (fileName$, label$, auxs$, auxv%)
DECLARE FUNCTION QAGLfileExists% (fileName$)
DECLARE FUNCTION QAGLlabelExists% (fileName$, label$)
DECLARE FUNCTION QAGLchooseAnswer% (a1$, a2$, a3$)
DECLARE FUNCTION QAGLprocessForLabel$ (s$)
DECLARE FUNCTION QAGLprocrust$ (s$, l%)

'' SB detection routines (patched / adapted)
DECLARE FUNCTION SBgetDMA% ()
DECLARE FUNCTION SBgetIRQ% ()
DECLARE FUNCTION SBdspReset% ()
DECLARE FUNCTION SBisSb% ()

'' Simple parser
DECLARE SUB PARSERdoFlags ()
DECLARE SUB PARSERparse (T$)

'' Constants
CONST ZEXAM = 1
CONST ZGET = 2
CONST ZFIDDLE = 4
CONST ZTALK = 8
CONST ZEXIT = 128
CONST FALSE = 0
CONST TRUE = NOT FALSE
CONST MPUBASE = &H330
CONST OPLBASE = &H388
CONST FMEFFFILE = "ASSETS\EFFECTS.S3M"
CONST MAXWORDS = 16
CONST MAXZONES = 16
CONST MAXLABELSBUFFER = 255

'' Types
TYPE TypeZone
	x1 AS INTEGER
	y1 AS INTEGER
	x2 AS INTEGER
	y2 AS INTEGER
	title AS STRING * 16
	flag AS INTEGER
END TYPE

TYPE FMadlchan
	n AS INTEGER
	s AS INTEGER
	v AS INTEGER
	c AS INTEGER
	i AS INTEGER
	DefD AS INTEGER
	DefE AS INTEGER
	DefH AS INTEGER
	CurInst AS INTEGER
	CurVol AS INTEGER
	period AS INTEGER
	VibPos AS INTEGER
	effres AS INTEGER
	VibEff AS INTEGER
END TYPE

TYPE FMinsdata
	c4spd AS INTEGER
	vol AS INTEGER
	gm AS INTEGER
	gmadd AS INTEGER
	gmvol AS INTEGER
	gmbank AS INTEGER
END TYPE

TYPE FMdata
	CurRow AS INTEGER
	CurOrd AS INTEGER
	NeedPat AS INTEGER
	EdPat AS INTEGER
	TickPos AS INTEGER
	SkipRow AS INTEGER
	ordnum AS INTEGER
	insnum AS INTEGER
	patnum AS INTEGER
	patdelay AS INTEGER
	patdelaymax AS INTEGER
	LoopBegin AS INTEGER
	LoopCount AS INTEGER
	patpos AS INTEGER
	pperror AS DOUBLE
	effectA AS INTEGER
	effectT AS INTEGER
	effind AS INTEGER
	effpptr AS LONG
END TYPE

TYPE FMeffdata
	effA AS INTEGER
	effptr AS INTEGER
	effTickPos AS INTEGER
END TYPE

TYPE TypeItem
	x AS INTEGER
	y AS INTEGER
	desc AS STRING * 16
	file AS STRING * 20 ' Forwards compatibility
END TYPE

TYPE TypeInventoryItem
	idItem AS INTEGER
	flags AS INTEGER
END TYPE

'' Shared goods
DIM SHARED MOUSEcode%(29)
DIM SHARED baseport%, LenPort%, IRQ%, DMA%
DIM SHARED FMperiod(0 TO 11) AS DOUBLE
DIM SHARED FMorder%(0 TO 255)
DIM SHARED FMadlData%(1 TO 100, 0 TO 11)
DIM SHARED FMinsdata(1 TO 100) AS FMinsdata
DIM SHARED FMadlchan(0 TO 31) AS FMadlchan
DIM SHARED MIDInote%(0 TO 31), MIDIchan%(0 TO 31)
DIM SHARED FMfilename$, FMpattern$, FMeffect$(0 TO 3)
DIM SHARED FMdata AS FMdata, FMeff(0 TO 3) AS FMeffdata
DIM SHARED QAGLcursors%(17, 4)
DIM SHARED QAGLloadPutBuffer%(32003)
DIM SHARED words$(MAXWORDS)
DIM SHARED flags%(255), engineFlagsOffset%
DIM SHARED zones(MAXZONES) AS TypeZone
DIM SHARED maxZone%
DIM SHARED QAGLboxX0%, QAGLboxY%, QAGLboxX1%
DIM SHARED breakMe%
DIM SHARED inventoryOn%, lastItem%, itScrX%, itScrY%
DIM SHARED items(59)  AS TypeItem
DIM SHARED inventory(9)  AS TypeInventoryItem
DIM SHARED labelFPosBuffer%(MAXLABELSBUFFER)
DIM SHARED labelNameBuffer$(MAXLABELSBUFFER)
DIM SHARED maxLabels%
DIM SHARED soundBlasterDetected%

'' Initialize
PRINT
PRINT "ÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜ"
PRINT "Qbasic 1 Adventure Game Library v.3 EGA " + CHR$(3)
PRINT "ßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþßþÜþß"
PRINT
PRINT "Copyleft 1997, 1998, 2002, 2016 LS Produktions / Mojon Twins"
PRINT "Copyleft 2016 LS Produktions / Mojon Twins"
PRINT "EGA routines, interpreter and engine by na_th_an"
PRINT "S3M player by Bisqwit (http://iki.fi/bisqwit/)"
PRINT "DMAPlay by Mike Huff, Martin Rampersad & Toshi Horie"
PRINT "SB detection routines by Alexander Verhaeghe"
PRINT
PRINT "Array: "; LTRIM$(RTRIM$(STR$(FRE(-1))));
PRINT ", Stack: "; LTRIM$(RTRIM$(STR$(FRE(-2))));
PRINT ", String: "; LTRIM$(RTRIM$(STR$(FRE(""))))

soundBlasterDetected% = SBisSb%: HWBP% = baseport%
IF soundBlasterDetected% THEN
	PRINT "Sound Blaster Detected!"
	DMAgetBlaster
	IF baseport% <> -1 THEN
		PRINT "Blaster variable detected! ";
		PRINT "Base="; HEX$(baseport%); ", IRQ="; LTRIM$(STR$(IRQ%)); ", DMA="; LTRIM$(STR$(DMA%))
	ELSE
		PRINT "Blaster variable not detected, auto-detecting..."
		baseport% = HWBP%
		IRQ% = SBgetIRQ%
		DMA% = SBgetDMA%
		PRINT "Hardware values: ";
		PRINT "Base="; HEX$(baseport%); ", IRQ="; LTRIM$(STR$(IRQ%)); ", DMA="; LTRIM$(STR$(DMA%))
	END IF
	DMAspeakerState 1
	dummy% = FMinit%
ELSE
	PRINT "Sound Blaster not detected. Game will be silent!"
END IF

MOUSEinitLib
IF NOT (MOUSEinit%) THEN PRINT "Mouse not detected! You need a mouse (and drivers) to play :-(": SYSTEM
QAGLloadCursors "ASSETS\CURSORS.PUT"

PRINT "Press any key...": SLEEP

SCREEN 7: PALETTE 1, 0: PALETTE 0, 1

'' here
res% = QAGLrunScript%("SAMPLE.SPT", "", "", 0)

'' Outtro
BeSilent: FMend: SCREEN 0, 0, 0, 0: WIDTH 80: SYSTEM

'' Timer callback for S3M player
timercallback: FMtimer: RETURN

FUNCTION DMAdone%
	Count% = INP(LenPort%)
	Count2% = INP(LenPort%)
	Count& = CLNG(Count% + 1) * CLNG(Count2% + 1)
	IF (Count& - 1) >= &HFFFF& THEN junk% = INP(DSPDataAvail%): DMAdone% = -1
END FUNCTION

FUNCTION DMAdspVersion!
	' Gets the DSP version.
	DMAwriteDSP &HE1
	Temp% = DMAreadDSP%
	Temp2% = DMAreadDSP%
	DMAdspVersion! = VAL(STR$(Temp%) + "." + STR$(Temp2%))
END FUNCTION

SUB DMAgetBlaster
	' This subroutine parses the BLASTER environment string and returns settings.
	IF LEN(ENVIRON$("BLASTER")) = 0 THEN PRINT "BLASTER environment variable not set.": EXIT SUB
	baseport% = -1: IRQ% = -1: DMA% = -1
	FOR length% = 1 TO LEN(ENVIRON$("BLASTER"))
	   SELECT CASE MID$(ENVIRON$("BLASTER"), length%, 1)
		  CASE "A"
			baseport% = VAL("&H" + MID$(ENVIRON$("BLASTER"), length% + 1, 3))
		  CASE "I"
			IRQ% = VAL(MID$(ENVIRON$("BLASTER"), length% + 1, 1))
		  CASE "D"
			DMA% = VAL(MID$(ENVIRON$("BLASTER"), length% + 1, 1))
	   END SELECT
	NEXT
END SUB

SUB DMAplay (segment&, offset&, length&, freq&)
	' Transfers and plays the contents of the buffer.
	length& = length& - 1
	Page% = 0
	MemLoc& = segment& * 16 + offset&
	SELECT CASE DMA%
		CASE 0
		   PgPort% = &H87
		   AddPort% = &H0
		   LenPort% = &H1
		   ModeReg% = &H48
		CASE 1
		   PgPort% = &H83
		   AddPort% = &H2
		   LenPort% = &H3
		   ModeReg% = &H49
		CASE 2
		   PgPort% = &H81
		   AddPort% = &H4
		   LenPort% = &H5
		   ModeReg% = &H4A
		CASE 3
		   PgPort% = &H82
		   AddPort% = &H6
		   LenPort% = &H7
		   ModeReg% = &H4B
		CASE ELSE
		   PRINT "DMA channels 0-3 only are supported."
		   EXIT SUB
	END SELECT
	
	OUT &HA, &H4 + DMA%
	OUT &HC, &H0
	OUT &HB, ModeReg%
	OUT AddPort%, MemLoc& AND &HFF
	OUT AddPort%, (MemLoc& AND &HFFFF&) \ &H100
	IF (MemLoc& AND 65536) THEN Page% = Page% + 1
	IF (MemLoc& AND 131072) THEN Page% = Page% + 2
	IF (MemLoc& AND 262144) THEN Page% = Page% + 4
	IF (MemLoc& AND 524288) THEN Page% = Page% + 8
	OUT PgPort%, Page%
	OUT LenPort%, length& AND &HFF
	OUT LenPort%, (length& AND &HFFFF&) \ &H100
	OUT &HA, DMA%

	IF freq& < 23000 THEN
	   TimeConst% = 256 - 1000000 \ freq&
	   DMAwriteDSP &H40
	   DMAwriteDSP TimeConst%
	   DMAwriteDSP &H14
	   DMAwriteDSP (length& AND &HFF)
	   DMAwriteDSP ((length& AND &HFFFF&) \ &H100)
	ELSE
	   IF DMAdspVersion! >= 3 THEN
		  TimeConst% = ((65536 - 256000000 \ freq&) AND &HFFFF&) \ &H100
		  DMAwriteDSP &H40
		  DMAwriteDSP TimeConst%
		  DMAwriteDSP (length& AND &HFF)
		  DMAwriteDSP ((length& AND &HFFFF&) \ &H100)
		  DMAwriteDSP &H91
	   ELSE
		  PRINT "You need a Sound Blaster with a DSP v3.x+ to play at high speed."
		  EXIT SUB
	   END IF
	END IF
END SUB

SUB DMAplayVOC (file$, freq&)
   DMAspeakerState 1
   'MasterVolume 15, 15, 0
   DIM WavBuffer(1 TO 1) AS STRING * 8192
   fileName$ = file$
   f% = FREEFILE
   OPEN fileName$ FOR BINARY AS f%
	  GET #f%, 44, WavBuffer(1)
	  length& = LOF(f%) - 44
   CLOSE f%
   IF length& > 8192 THEN length& = 8192
   DMAplay VARSEG(WavBuffer(1)), VARPTR(WavBuffer(1)), length&, freq&
   DO: LOOP UNTIL DMAdone%
   ERASE WavBuffer
END SUB

SUB DMAplayVOCBG (file$, freq&)
   'MasterVolume 15, 15, 0
   DIM WavBuffer(1 TO 1) AS STRING * 8192
   fileName$ = file$
   f% = FREEFILE
   OPEN fileName$ FOR BINARY AS #f%
	  GET #f%, 44, WavBuffer(1)
	  length& = LOF(f%) - 44
   CLOSE f%
   IF length& > 8192 THEN length& = 8192
   IF NOT DMAdone% THEN EXIT SUB
   DMAplay VARSEG(WavBuffer(1)), VARPTR(WavBuffer(1)), length&, freq&
	
   ERASE WavBuffer
END SUB

FUNCTION DMAreadDSP%
	' Reads a byte from the DSP
	DO
	LOOP UNTIL INP(baseport% + 14) AND &H80
	DMAreadDSP% = INP(baseport% + 10)
END FUNCTION

FUNCTION DMAresetDSP%
	' Resets the DSP
	OUT baseport% + 6, 1
	FOR Count% = 1 TO 4
	   junk% = INP(baseport% + 6)
	NEXT
	OUT baseport% + 6, 0
	IF INP(baseport% + 14) AND &H80 = &H80 AND INP(baseport% + 10) = &HAA THEN
	   DMAresetDSP% = -1
	ELSE
	   DMAresetDSP% = 0
	END IF
END FUNCTION

SUB DMAspeakerState (OnOff%)
	' Turns speaker on or off.
	IF OnOff% THEN DMAwriteDSP &HD1 ELSE DMAwriteDSP &HD3
END SUB

FUNCTION DMAspeakerStatus%
	OUT baseport% + 4, &HD8
	IF INP(baseport% + 5) = &HFF THEN DMAspeakerStatus% = -1 ELSE DMAspeakerStatus% = 0
END FUNCTION

SUB DMAwriteDAC (byte%)
	' Writes a byte to the DAC.
	DMAwriteDSP &H10
	DMAwriteDSP byte%
END SUB

SUB DMAwriteDSP (byte%)
	' Writes a byte to the DSP
	DO
	LOOP WHILE INP(baseport% + 12) AND &H80
	OUT baseport% + 12, byte%
END SUB

SUB EGAloadPut (x%, y%, file$)
	DIM d AS STRING * 1
   
	' Bload
	DEF SEG = VARSEG(QAGLloadPutBuffer%(0))
	BLOAD file$, VARPTR(QAGLloadPutBuffer%(0))
	DEF SEG
   
	' Read some header stuff to know wether to put
	' solid or transparent.
	f% = FREEFILE
	OPEN file$ FOR BINARY AS #f%
	l& = LOF(f%)
	GET #f%, , d ' QBasic header &HFD
	GET #f%, , segment%
	GET #f%, , offset%
	GET #f%, , length%
	GET #f%, , w%
	GET #f%, , h%
	CLOSE #f%

	IF l& - 7 = 4 + (w% \ 2) * h% THEN
		PUT (x%, y%), QAGLloadPutBuffer%(0), PSET
	ELSE
		PUT (x%, y%), QAGLloadPutBuffer%(2 + (w% \ 4) * h%), AND
		PUT (x%, y%), QAGLloadPutBuffer%(0), OR
	END IF
END SUB

SUB FMbeSilent
	FOR j% = 0 TO 31
		FMnoteoff j%, j%
	NEXT
	FOR j% = 0 TO 244: FMwrite j%, 0: NEXT
END SUB

SUB FMend
	PLAY OFF
	CALL FMbeSilent
END SUB

FUNCTION FMinit%
	FMwrite 4, 96: FMwrite 4, 128: a% = INP(OPLBASE)
	FMwrite 2, 255: FMwrite 4, 33: a# = TIMER: a# = TIMER: B% = INP(OPLBASE)
	FMwrite 4, 96: FMwrite 4, 128
	'IF ((a% AND &HE0)) OR ((B% AND &HE0) <> &HC0) THEN FMinit% = -1: EXIT FUNCTION
	a# = 1712
	FOR x% = 0 TO 11: FMperiod(x%) = a#: a# = a# * .9438743126816935#: NEXT
	CALL FMbeSilent
	PLAY ON
	ON PLAY(1) GOSUB timercallback
	PLAY "mlmbt255p64"
	FMload FMEFFFILE
	CALL FMbeSilent
	FMdata.effind = 0
	FOR x% = 0 TO 3: FMeff(x%).effA = FMdata.effectA: NEXT
	FOR x% = 0 TO 31: FMadlchan(x%).effres = -1: NEXT
	FOR x% = 1 TO FMdata.insnum
		FOR y% = 0 TO 11
			FMadlData%(70 + x%, y%) = FMadlData%(x%, y%)
		NEXT
		FMinsdata(70 + x%) = FMinsdata(x%)
	NEXT
	FMdata.effpptr = &H61 + FMdata.ordnum + FMdata.insnum * 2
	x% = FMMPUDetect%
	FMinit% = 1
END FUNCTION

SUB FMload (fs$)
	FMfilename$ = ""
	PLAY STOP
	CALL FMbeSilent
	fp% = FREEFILE
	OPEN fs$ FOR BINARY AS fp%
	IF LOF(fp%) = 0 THEN
		CLOSE fp%
		KILL s$
		PRINT "FILE NOT FOUND ERROR: "; s$
		EXIT SUB
	END IF
	SEEK fp%, &H21
	FMdata.ordnum = CVI(INPUT$(2, fp%))
	FMdata.insnum = CVI(INPUT$(2, fp%))

	SEEK fp%, &H32
	FMdata.effectA = ASC(INPUT$(1, fp%))
	FMdata.effectT = ASC(INPUT$(1, fp%))
	SEEK fp%, &H61
	FOR x% = 1 TO FMdata.ordnum
		FMorder%(x% - 1) = ASC(INPUT$(1, fp%))
	NEXT
	FOR x% = 1 TO FMdata.insnum
		SEEK fp%, &H61 + FMdata.ordnum + (x% - 1) * 2
		insptr = CVI(INPUT$(2, fp%))
		SEEK fp%, insptr * 16& + 1 + &H10
		FOR y% = 0 TO 11
			FMadlData%(x%, y%) = ASC(INPUT$(1, fp%))
		NEXT
		SEEK fp%, insptr * 16& + 1 + &H1C
		FMinsdata(x%).vol = ASC(INPUT$(1, fp%))
		SEEK fp%, insptr * 16& + 1 + &H20
		FMinsdata(x%).c4spd = CVI(INPUT$(2, fp%))
		SEEK fp%, insptr * 16& + 1 + &H30
		s$ = INPUT$(28, fp%)
		IF LEFT$(s$, 2) = "GM" THEN
			g% = 0
		ELSEIF LEFT$(s$, 2) = "GP" THEN
			g% = 1
		ELSE
			g% = -1
		END IF
		IF g% < 0 THEN
			FMinsdata(x%).gm = 0
			FMinsdata(x%).gmadd = 0
			FMinsdata(x%).gmvol = 0
		ELSE
			n% = VAL(MID$(s$, 3))
			IF LEFT$(s$, 2) = "GP" THEN
				n1% = n% - 35 + 128
			ELSE
				n1% = n% - 1
			END IF
			FMinsdata(x%).gmadd = 0
			FMinsdata(x%).gmvol = 64
			FMinsdata(x%).gm = n1%
			IF n% < 10 THEN c% = 1 ELSE IF n% < 100 THEN c% = 2 ELSE c% = 3
			p% = 3 + c%
			DO WHILE p% < LEN(s$)
				c$ = MID$(s$, p%, 1)
				IF c$ = "+" OR c$ = "-" THEN
					p% = p% + 1
					n% = VAL(MID$(s$, p%))
					IF n% < 10 THEN c% = 1 ELSE IF n% < 100 THEN c% = 2 ELSE c% = 3
					IF c$ = "-" THEN n% = -n%
					FMinsdata(x%).gmadd = n%
					p% = p% + c%
				ELSEIF c$ = "" THEN
					p% = p% + 1
					n% = VAL(MID$(s$, p%))
					IF n% < 10 THEN c% = 1 ELSE IF n% < 100 THEN c% = 2 ELSE c% = 3
					FMinsdata(x%).gmbank = n%
					p% = p% + c%
				ELSEIF c$ = "/" THEN
					p% = p% + 1
					n% = VAL(MID$(s$, p%))
					IF n% < 10 THEN c% = 1 ELSE IF n% < 100 THEN c% = 2 ELSE c% = 3
					FMinsdata(x%).gmvol = n%
					p% = p% + c%
				ELSEIF c$ = "&" THEN
					p% = p% + 1
					n% = VAL(MID$(s$, p%))
					IF n% < 10 THEN c% = 1 ELSE IF n% < 100 THEN c% = 2 ELSE c% = 3
					p% = p% + c%
				ELSE
					EXIT DO
				END IF
			LOOP
		END IF
	NEXT
	FOR x% = 0 TO 31
		FMadlchan(x%).CurInst = 0
		FMadlchan(x%).CurVol = 0
		FMadlchan(x%).n = 255
		FMadlchan(x%).s = 0
		FMadlchan(x%).v = 255
		FMadlchan(x%).c = 0
		FMadlchan(x%).i = 0
		MIDIchan%(x%) = -1
	NEXT
	FMdata.CurRow = 0
	FMdata.CurOrd = 0
	FMdata.SkipRow = 0
	FMdata.NeedPat = TRUE
	FMdata.LoopBegin = 0
	FMdata.LoopCount = 0
	FMdata.TickPos = 0
	FMdata.EdPat = -1
	CLOSE fp%
	FMfilename$ = fs$
	IF FMorder%(FMdata.CurOrd) < 255 THEN
		PLAY ON
	END IF
END SUB

FUNCTION FMMPUDetect%
	FMMPUDetect% = 0
	OUT MPUBASE + 1, 255
	B% = 10000
	WHILE (INP(MPUBASE + 1) AND &H40) <> 0
		B% = B% - 1
		IF B% = 0 THEN EXIT FUNCTION
	WEND
	OUT MPUBASE + 1, 255
	B% = 10000
MPULoop:
	WHILE (INP(MPUBASE + 1) AND &H80) <> 0
		B% = B% - 1
		IF B% = 0 THEN EXIT FUNCTION
	WEND
	IF INP(MPUBASE) <> 254 THEN GOTO MPULoop
	FMMPUDetect% = 0
	WHILE (INP(MPUBASE + 1) AND &H40) <> 0: WEND
	OUT MPUBASE + 1, 63
	B% = 10000
MPULoop2:
	WHILE (INP(MPUBASE + 1) AND &H80) <> 0
		B% = B% - 1
		IF B% = 0 THEN EXIT FUNCTION
	WEND
	IF INP(MPUBASE) <> 254 THEN GOTO MPULoop2
	FMMPUDetect% = -1
END FUNCTION

FUNCTION FMMPUVol% (vol%, ins%)
	v% = vol% * FMinsdata(ins%).gmvol \ 64
	IF v% > 0 THEN v% = EXP(v% / (64 / 4)) * 127 / EXP(4)
	IF v% < 0 THEN v% = 0 ELSE IF v% > 127 THEN v% = 127
	FMMPUVol = v%
END FUNCTION

SUB FMMPUwrite (B%)
END SUB

FUNCTION FMnote2period% (note%, oct%, ins%)
	c4spd% = FMinsdata(ins%).c4spd%
	tmp& = 8363& * 16& * FMperiod(note%)
	IF c4spd% = 0 THEN
		FMnote2period% = 0
	ELSE
		FMnote2period% = (tmp& \ (2 ^ oct%)) / c4spd%
	END IF
END FUNCTION

SUB FMnoteoff (chan%, ope%)
	FMwrite &HB0 + chan%, 0
	FMwrite &H40 + ope%, 255
	FMwrite &H43 + ope%, 255
	FMMPUwrite &H80 + MIDIchan%(chan%)
	FMMPUwrite MIDInote%(chan%)
	FMMPUwrite 127
	MIDIchan%(chan%) = -1
END SUB

SUB FMplayeffect (ind%)
	PLAY STOP
	fp% = FREEFILE
	OPEN FMEFFFILE FOR BINARY AS fp%
	SEEK fp%, FMdata.effpptr + ind% * 2
	patptr% = CVI(INPUT$(2, fp%))
	SEEK fp%, patptr% * 16& + 1
	patlen% = CVI(INPUT$(2, fp%))
	FMeffect$(FMdata.effind) = INPUT$(patlen%, fp%)
	FMeff(FMdata.effind).effptr = 1
	FMeff(FMdata.effind).effTickPos = 0
	FMdata.effind = (FMdata.effind + 1) AND 3
	CLOSE fp%
	PLAY ON
END SUB

SUB FMplayrowfrom (pat$, ofs%, effnum%)
	IF LEN(pat$) = 0 THEN EXIT SUB
	termination% = FALSE
	FOR c% = 0 TO 31
		IF FMadlchan(c%).effres = effnum% THEN
			FMadlchan(c%).n = 255
			FMadlchan(c%).s = 0
			FMadlchan(c%).v = 255
			FMadlchan(c%).c = 0
			FMadlchan(c%).i = 0
		END IF
	NEXT
	DO
		c% = ASC(MID$(pat$, ofs%, 1))
		n% = ofs% + 1
		IF c% > 0 THEN
			chan% = c% AND 31
			IF effnum% >= 0 THEN
				FMadlchan(chan%).effres = effnum%
			END IF
			IF (c% AND 32) THEN
				note% = ASC(MID$(pat$, n%, 1)): n% = n% + 1
				ins% = ASC(MID$(pat$, n%, 1)): n% = n% + 1
				IF effnum% >= 0 OR FMadlchan(chan%).effres < 0 THEN
					IF effnum% >= 0 THEN ins% = ins% + 70
					FMadlchan(chan%).n = note%
					FMadlchan(chan%).s = ins%
				END IF
			END IF
			IF (c% AND 64) THEN
				vol% = ASC(MID$(pat$, n%, 1)): n% = n% + 1
				IF effnum% >= 0 OR FMadlchan(chan%).effres < 0 THEN
					FMadlchan(chan%).v = vol%
				END IF
			END IF
			IF (c% AND 128) THEN
				cmd% = ASC(MID$(pat$, n%, 1)): n% = n% + 1
				info% = ASC(MID$(pat$, n%, 1)): n% = n% + 1

				IF effnum% >= 0 AND cmd% = 3 THEN
					termination% = TRUE
					FMadlchan(chan%).effres = -1
				ELSE
					IF effnum% >= 0 OR FMadlchan(chan%).effres < 0 THEN
						FMadlchan(chan%).c = cmd%
						FMadlchan(chan%).i = info%
					END IF
					IF cmd% = 1 THEN FMdata.effectA = FMadlchan(chan%).i
					IF info% = 20 THEN FMdata.effectT = FMadlchan(chan%).i
				END IF
			END IF
		END IF
		ofs% = n%
	LOOP UNTIL c% = 0
	IF termination% THEN
		pat$ = ""
		ofs% = 1
		EXIT SUB
	END IF
END SUB

SUB FMtimer
	IF FMperiod(0) = 0 OR LEN(FMfilename$) = 0 THEN EXIT SUB
	pp# = .1882352941176471# * FMdata.effectT + FMdata.pperror
	IF pp# < 1 THEN pp# = 1 ELSE IF pp# > 64 THEN pp# = 64
	pp% = INT(pp#)
	FMdata.pperror = pp# - pp%
	PLAY "mbt255p=" + VARPTR$(pp%)
	FOR looper% = 0 TO 1
		IF FMdata.TickPos = 0 THEN
			IF FMdata.patdelay = 0 THEN
				IF FMdata.NeedPat THEN
					c% = 0
					DO
						CurPat% = FMorder%(FMdata.CurOrd)
						IF CurPat% < 254 THEN EXIT DO
						FMdata.CurOrd = (FMdata.CurOrd + 1) MOD FMdata.ordnum
						c% = c% + 1
					LOOP WHILE c% < FMdata.ordnum
					IF CurPat% <> FMdata.EdPat THEN
						FMdata.EdPat = CurPat%
						fp% = FREEFILE
						OPEN FMfilename$ FOR BINARY AS fp%
						SEEK fp%, &H61 + FMdata.ordnum + FMdata.insnum * 2 + CurPat% * 2
						patptr% = CVI(INPUT$(2, fp%))
						SEEK fp%, patptr% * 16& + 1
						patlen% = CVI(INPUT$(2, fp%))
						FMpattern$ = INPUT$(patlen%, fp%)
						CLOSE fp%
					END IF
					FMdata.CurRow = 0
					FMdata.NeedPat = FALSE
					FMdata.patpos = 1
				END IF
				WHILE FMdata.SkipRow > 0
					DO
						n% = 1
						c% = ASC(MID$(FMpattern$, FMdata.patpos, 1))
						IF (c% AND 32) THEN n% = n% + 2
						IF (c% AND 64) THEN n% = n% + 1
						IF (c% AND 128) THEN n% = n% + 2
						FMdata.patpos = FMdata.patpos + n%
					LOOP UNTIL c% = 0
					FMdata.SkipRow = FMdata.SkipRow - 1
					FMdata.CurRow = FMdata.CurRow + 1
				WEND
				FMplayrowfrom FMpattern$, FMdata.patpos, -1
			END IF
			FMdata.TickPos = FMdata.effectA
		END IF
		FOR x% = 0 TO 3
			IF FMeff(x%).effTickPos = 0 THEN
				c% = FMdata.effectA
				FMdata.effectA = FMeff(x%).effA
				FMplayrowfrom FMeffect$(x%), FMeff(x%).effptr, x%
				FMeff(x%).effA = FMdata.effectA
				FMdata.effectA = c%
				FMeff(x%).effTickPos = FMeff(x%).effA
				FMeff(x%).effTickPos = FMeff(x%).effA
			END IF
		NEXT
		loophere% = FALSE
		FOR x% = -1 TO 3
			IF x% >= 0 THEN
				CurTick% = FMeff(x%).effA - FMeff(x%).effTickPos
			ELSE
				CurTick% = FMdata.effectA - FMdata.TickPos  '0..(A-1)
			END IF
			FOR c% = 0 TO 8
				IF FMadlchan(c%).effres = x% THEN
					IF FMadlchan(c%).VibEff = 2 THEN FMadlchan(c%).VibEff = 1
					chan% = c%
					ope% = chan%
					IF chan% > 2 THEN ope% = ope% + 5
					IF chan% > 5 THEN ope% = ope% + 5
					notedelay% = 0
					notecut% = -1
					cmd% = FMadlchan(c%).c
					info% = FMadlchan(c%).i
					IF cmd% = 19 THEN
						sclass% = info% \ 16
						sinfo% = info% AND 15
						IF sclass% = 11 THEN
							IF CurTick% = 0 THEN
								IF sinfo% = 0 THEN
									FMdata.LoopBegin = FMdata.CurRow
								ELSE
									IF FMdata.LoopCount = 0 THEN
										FMdata.LoopCount = sinfo% + 1
									END IF
								END IF
							END IF
							IF sinfo% > 0 THEN loophere% = TRUE
						END IF
						IF sclass% = 12 THEN notecut% = sinfo%
						IF sclass% = 13 THEN notedelay% = sinfo%
						IF sclass% = 14 THEN
							IF CurTick% = 0 THEN
								IF FMdata.patdelay = 0 THEN
									FMdata.patdelay = sinfo%
									FMdata.patdelaymax = sinfo%
								ELSE
									FMdata.patdelay = FMdata.patdelay - 1
								END IF
							END IF
						END IF
					END IF
					IF notedelay% = CurTick% AND (FMdata.patdelay = FMdata.patdelaymax OR CurTick% > 0) THEN
						vol% = FMadlchan(c%).v
						note% = FMadlchan(c%).n
						ins% = FMadlchan(c%).s
						IF ins% = 0 THEN
							ins% = FMadlchan(c%).CurInst
						ELSE
							FMadlchan(c%).CurInst = ins%
						END IF
						IF ins% > 0 THEN
							IF vol% = 255 THEN
								vol% = FMinsdata(ins%).vol%
							ELSE
								FMtouch chan%, ope%, vol%, ins%
								FMadlchan(c%).CurVol = vol%
							END IF
							IF note% < 255 THEN
								FMnoteoff chan%, ope%
								IF note% <> 254 THEN
									oct% = note% \ 16
									note% = note% AND 15
									FMadlchan(c%).period = FMnote2period%(note%, oct%, ins%)
									FMupdate chan%, ope%, FMadlchan(c%).period, ins%, vol%
									FMadlchan(c%).CurVol = vol%
								END IF
							END IF
						END IF
					END IF
					IF FMadlchan(c%).CurInst > 0 THEN
						IF cmd% = 4 OR cmd% = 11 THEN
							vol% = FMadlchan(c%).CurVol
							IF info% = 0 THEN info% = FMadlchan(c%).DefD ELSE FMadlchan(c%).DefD = info%
							IF info% = 255 THEN
								vol% = 64
							ELSEIF info% >= 240 THEN
								IF CurTick% = 0 THEN vol% = vol% - (info% AND 15)
							ELSEIF info% < 16 THEN
								vol% = vol% - (info% AND 15)
							ELSEIF (info% AND 15) = 15 THEN
								IF CurTick% = 0 THEN vol% = vol% + (info% \ 16)
							ELSEIF info% <= 240 THEN
								vol% = vol% + (info% \ 16)
							END IF
							IF vol% < 0 THEN vol% = 0 ELSE IF vol% > 64 THEN vol% = 64
							FMadlchan(c%).CurVol = vol%
							FMtouch chan%, ope%, vol%, FMadlchan(c%).CurInst
						END IF
						IF cmd% = 5 OR cmd% = 6 THEN
							IF info% = 0 THEN info% = FMadlchan(c%).DefE ELSE FMadlchan(c%).DefE = info%
							IF cmd% = 6 THEN info% = -info%
							FMadlchan(c%).period = FMadlchan(c%).period + info% * 4
							FMupdate chan%, ope%, FMadlchan(c%).period, FMadlchan(c%).CurInst, FMadlchan(c%).CurVol
						END IF
						IF cmd% = 8 OR cmd% = 11 THEN
							IF cmd% = 11 THEN info% = 0
							IF info% = 0 THEN info% = FMadlchan(c%).DefH ELSE FMadlchan(c%).DefH = info%
							IF FMadlchan(c%).VibEff = 0 THEN
								FMadlchan(c%).VibPos = 0
							END IF
							vspeed% = info% \ 16
							vdepth% = info% AND 15
							value% = FMVibVal%(FMadlchan(c%).VibPos, 0) * vdepth% \ 32
							FMupdate chan%, ope%, FMadlchan(c%).period + value%, FMadlchan(c%).CurInst, FMadlchan(c%).CurVol
							FMadlchan(c%).VibPos = FMadlchan(c%).VibPos + vspeed%
							FMadlchan(c%).VibEff = 2
						END IF
						IF notecut% = CurTick% AND (FMdata.patdelay = FMdata.patdelaymax OR CurTick% > 0) THEN
							FMnoteoff chan%, ope%
						END IF
					END IF
					IF FMadlchan(c%).VibEff = 1 THEN
						FMadlchan(c%).VibEff = 0
						FMupdate chan%, ope%, FMadlchan(c%).period, FMadlchan(c%).CurInst, FMadlchan(c%).CurVol
					END IF
				END IF
			NEXT
		NEXT
		FMdata.TickPos = FMdata.TickPos - 1
		FOR x% = 0 TO 3
			FMeff(x%).effTickPos = FMeff(x%).effTickPos - 1
		NEXT
		IF FMdata.TickPos = 0 AND FMdata.patdelay = 0 THEN
			FMdata.patdelaymax = 0
			brkord% = -1
			brkrow% = -1
			FMdata.CurRow = FMdata.CurRow + 1
			IF FMdata.CurRow = 64 THEN
				brkrow% = 0
			END IF
			doLoop% = FALSE
			IF FMdata.LoopCount > 0 AND loophere% = TRUE THEN
				FMdata.LoopCount = FMdata.LoopCount - 1
				IF FMdata.LoopCount = 0 THEN
					FMdata.LoopBegin = FMdata.CurRow
				ELSE
					brkord% = FMdata.CurOrd
					brkrow% = FMdata.LoopBegin
					doLoop% = TRUE
				END IF
			END IF
			IF doLoop% = FALSE THEN
				FOR c% = 0 TO 8
					cmd% = FMadlchan(c%).c
					info% = FMadlchan(c%).i

					IF cmd% = 2 THEN
						brkord% = info%
						FMdata.LoopBegin = 0
					END IF
					IF cmd% = 3 THEN
						brkrow% = (info% \ 16) * 10 + (info% AND 15)
						FMdata.LoopBegin = 0
					END IF
				NEXT
				IF brkord% >= 0 AND brkrow% = -1 THEN brkrow% = 0
			END IF
			IF brkrow% >= 0 THEN
				FMdata.CurOrd = (FMdata.CurOrd + 1) MOD FMdata.ordnum
				FMdata.NeedPat = TRUE
				IF brkord% >= 0 THEN FMdata.CurOrd = brkord%
				FMdata.SkipRow = brkrow%
			END IF
		END IF
	NEXT
END SUB

SUB FMtouch (chan%, ope%, vol%, ins%)
	v% = vol% * 63 \ 64
	c% = (FMadlData%(ins%, 2) AND &HC0)
	c% = c% OR (63 + (FMadlData%(ins%, 2) AND 63) * v% \ 63 - v%)
	FMwrite &H40 + ope%, c%
	c% = (FMadlData%(ins%, 3) AND &HC0)
	c% = c% OR (63 + (FMadlData%(ins%, 3) AND 63) * v% \ 63 - v%)
	FMwrite &H43 + ope%, c%
	FMMPUwrite &HB0 + MIDIchan%(chan%)
	FMMPUwrite 7    'Master volume
	v% = FMMPUVol(vol%, ins%)
	FMMPUwrite v%
END SUB

SUB FMupdate (chan%, ope%, period%, ins%, vol%)
	IF ins% <= 0 THEN EXIT SUB
	FMwrite &H20 + ope%, FMadlData%(ins%, 0)
	FMwrite &H60 + ope%, FMadlData%(ins%, 4)
	FMwrite &H80 + ope%, FMadlData%(ins%, 6)
	FMwrite &HE0 + ope%, FMadlData%(ins%, 8) AND 3
	FMwrite &H23 + ope%, FMadlData%(ins%, 1)
	FMwrite &H63 + ope%, FMadlData%(ins%, 5)
	FMwrite &H83 + ope%, FMadlData%(ins%, 7)
	FMwrite &HE3 + ope%, FMadlData%(ins%, 9) AND 3
	FMwrite &HC0 + chan%, FMadlData%(ins%, 10) OR &H30
	IF FMinsdata(ins%).gm < 128 THEN
		IF period% = 0 THEN
			n% = 0
		ELSE
			n% = FMinsdata(ins%).gmadd + CINT(60.10259 + 17.31234 * LOG(FMperiod(0) / period%))
			IF n% < 1 THEN n% = 1
			IF n% > 127 THEN n% = 127
		END IF
		IF MIDIchan%(chan%) = -1 THEN
			MIDIchan%(chan%) = chan%
			MIDInote%(chan%) = n%
			FMMPUwrite &HC0 + MIDIchan%(chan%)
			FMMPUwrite FMinsdata(ins%).gm
			FMMPUwrite &H90 + MIDIchan%(chan%)
			FMMPUwrite MIDInote%(chan%)
			FMMPUwrite 127
		END IF
	ELSE
		IF MIDIchan%(chan%) = -1 THEN
			MIDIchan%(chan%) = 9
			MIDInote%(chan%) = FMinsdata(ins%).gm + 35 - 128
			FMMPUwrite &H90 + MIDIchan%(chan%)
			FMMPUwrite MIDInote%(chan%)
			FMMPUwrite 127
		END IF
	END IF
	FMtouch chan%, ope%, vol%, ins%
	oct% = 0
	IF period% = 0 THEN
		Herz& = 0
	ELSE
		Herz& = FMperiod(0) * 5500& / period%
	END IF
	WHILE Herz& >= 512
		oct% = oct% + 1
		Herz& = Herz& \ 2
	WEND
	FMwrite &HA0 + chan%, Herz& AND 255
	FMwrite &HB0 + chan%, 32 OR ((Herz& \ 256) AND 3) OR ((oct% AND 7) * 4)
END SUB

FUNCTION FMVibVal% (ind%, mode%)
	IF mode% >= 4 THEN
		ind% = ind% AND 63
	ELSEIF ind% >= 64 THEN
		ind% = 0
	END IF
	SELECT CASE mode%
		CASE 0:
			FMVibVal% = 255 * SIN(ind% * 9.817477042468103D-02)
			EXIT FUNCTION
		CASE 1:
			IF ind% = 0 THEN FMVibVal% = 0 ELSE FMVibVal% = (-256 + ind% * 8)
			EXIT FUNCTION
		CASE 2:
			IF ind% < 0 THEN FMVibVal% = 0 ELSE FMVibVal% = 255
			EXIT FUNCTION
	END SELECT
	EXIT FUNCTION
END FUNCTION

SUB FMwrite (i%, d%)
	OUT OPLBASE, i%: a% = INP(OPLBASE): OUT OPLBASE + 1, d%: a% = INP(OPLBASE)
END SUB

SUB MOUSEdriver (ax%, bx%, cx%, dx%)
	DEF SEG = VARSEG(MOUSEcode%(0))
	CALL Absolute(ax%, bx%, cx%, dx%, VARPTR(MOUSEcode%(0)))
	DEF SEG
END SUB

FUNCTION MOUSEinit%
	ax% = 0
	MOUSEdriver ax%, 0, 0, 0
	MOUSEinit% = ax%
END FUNCTION

SUB MOUSEinitLib
	PokeString VARSEG(MOUSEcode%(0)), VARPTR(MOUSEcode%(0)), "5589E58B5E0C8B07508B5E0A8B07508B5E088B0F8B5E068B175B581E07CD33538B5E0C8907588B5E0A89078B5E08890F8B5E0689175DCA0800"
END SUB

SUB MOUSEstatus (lb%, rb%, xm%, ym%)
	ax% = 3
	MOUSEdriver ax%, bx%, cx%, dx%
	lb% = ((bx% AND 1) <> 0)
	rb% = ((bx% AND 2) <> 0)
	xm% = (cx% / 2)
	ym% = dx%
END SUB

SUB PARSERdoFlags
	' Process words and looks for #X constructs
	' Skips word 0
	FOR i% = 1 TO MAXWORDS
		IF LEFT$(words$(i%), 1) = "$" THEN
			idx% = VAL(RIGHT$(words$(i%), LEN(words$(i%)) - 1))
			IF idx% >= 0 AND idx% <= 255 THEN
				words$(i%) = LTRIM$(STR$(flags%(idx%)))
			END IF
		END IF
	NEXT i%
END SUB

SUB PARSERparse (T$)
	T$ = T$ + " "
	quotes% = 0
	curWord% = 0
	hadQuotes% = 0
	FOR i% = 0 TO MAXWORDS: words$(i%) = "": NEXT i%
	o$ = ""
	FOR i% = 1 TO LEN(T$)
		m$ = MID$(T$, i%, 1)
		IF m$ = CHR$(34) THEN
			quotes% = NOT quotes%
			hadQuotes% = -1
		ELSEIF (m$ = "," OR m$ = " " OR m$ = "=" OR m$ = CHR$(9)) AND NOT quotes% THEN
			IF LEN(o$) > 0 THEN
				IF NOT hadQuotes% THEN
					words$(curWord%) = LTRIM$(RTRIM$(o$))
				ELSE
					words$(curWord%) = o$
				END IF
				hadQuotes% = 0
				o$ = ""
				IF curWord% < MAXWORDS THEN curWord% = curWord% + 1
			END IF
		ELSE
			o$ = o$ + m$
		END IF
	NEXT i%
END SUB

SUB PokeString (segment%, offset%, code$)
	DEF SEG = segment%
	l% = LEN(code$) \ 2 - 1
	FOR i% = 0 TO l%
		d% = VAL("&h" + MID$(code$, i% * 2 + 1, 2))
		POKE offset% + i%, d%
	NEXT i%
	DEF SEG
END SUB

SUB QAGLaction (action$, zone$, x%, y%)
	inventoryIsOn% = 0: buttonPressed% = 0
	inventoryPrefix$ = "": itemDesc$ = ""
   
	MOUSEstatus l%, B%, xm%, ym%
	x% = xm% - 4: y% = ym% - 4
	QAGLmouseLimit x%, y%
	ccrsr% = 99: cx% = x%: cy% = y%
	
	QAGLsve
	QAGLactionStatusBar
	
	GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
	DO
		MOUSEstatus l%, B%, xm%, ym%
		x% = xm% - 4: y% = ym% - 4
		QAGLmouseLimit x%, y%
		
		' Check zone
		
		' Check inventory
		invprefix$ = ""
		IF xm% > 224 AND ym% < 8 THEN
			IF NOT inventoryIsOn% THEN
				PCOPY 7, 1 ' Pseudo Rec
				FOR i% = 0 TO 9
					idItem% = inventory(i%).idItem
					' Get
					SCREEN , , 6, 0
					GET (items(idItem%).x, items(idItem%).y)-(31 + items(idItem%).x, 31 + items(idItem%).y), QAGLloadPutBuffer%(0)
					' Put
					SCREEN , , 1, 0
					PUT (32 * i%, 8), QAGLloadPutBuffer%(0), PSET
				NEXT i%
				QAGLactionStatusBar
				PCOPY 1, 0: PCOPY 7, 1
				SCREEN , , 0, 0
				GET (cx%, cy%)-(7 + cx%, 7 + cy%), QAGLcursors%(0, 0)
				inventoryIsOn% = -1
			END IF
		ELSE
			IF inventoryIsOn% THEN
				IF ym% >= 40 THEN
					QAGLrec
					QAGLactionStatusBar
					GET (cx%, cy%)-(7 + cx%, 7 + cy%), QAGLcursors%(0, 0)
					inventoryIsOn% = 0
					inventoryPrefix$ = ""
					itemDesc$ = ""
				ELSE
					itemDesc$ = RTRIM$(LTRIM$(items(inventory(xm% \ 32).idItem).desc))
					inventoryPrefix$ = "USAR " + itemDesc$ + " EN "
					LOCATE 1, 2: PRINT QAGLprocrust$(itemDesc$, 16);
				END IF
			ELSE
				crsr% = 3
				zone$ = ""
				zoneSelected% = -1
				FOR i% = 0 TO maxZone%
					IF xm% >= zones(i%).x1 AND xm% <= zones(i%).x2 AND ym% >= zones(i%).y1 AND ym% <= zones(i%).y2 THEN
						zone$ = zones(i%).title
						zoneSelected% = i%
						IF zones(i%).flag = 0 THEN
							crsr% = 2
						ELSE
							crsr% = 4
						END IF
						EXIT FOR
					END IF
				NEXT i%
				IF inventoryPrefix$ <> "" THEN dt$ = inventoryPrefix$ + zone$ ELSE dt$ = zone$
				LOCATE 1, 2: PRINT QAGLprocrust$(dt$, 27)
			END IF
		END IF
			
		IF cx% <> x% OR cy% <> y% OR ccrsr% <> crsr% THEN
			PUT (cx%, cy%), QAGLcursors%(0, 0), PSET
			GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
			PUT (x%, y%), QAGLcursors%(0, crsr%), XOR
			cx% = x%
			cy% = y%
			ccrsr% = crsr%
		END IF
		
		IF l% OR r% THEN
			IF NOT buttonPressed% THEN
				IF inventoryIsOn% THEN
					QAGLrec
					QAGLactionStatusBar
					GET (cx%, cy%)-(7 + cx%, 7 + cy%), QAGLcursors%(0, 0)
					inventoryIsOn% = 0
					IF itemDesc$ = "VACIO" THEN
						inventoryPrefix$ = ""
						itemDesc$ = ""
					END IF
				ELSE
					EXIT DO
				END IF
				buttonPressed% = -1
			END IF
		ELSE
			buttonPressed% = 0
		END IF
		k$ = INKEY$: IF k$ = CHR$(27) THEN breakMe% = -1: EXIT SUB
	LOOP
	PUT (cx%, cy%), QAGLcursors%(0, 0), PSET
	DO
		MOUSEstatus l%, B%, xm%, ym%
		IF NOT l% AND NOT r% THEN EXIT DO
	LOOP

	' Exit?
	QAGLrec
	QAGLactionStatusBar
	IF zoneSelected% < 0 THEN EXIT SUB
	IF itemDesc$ <> "" THEN zone$ = RTRIM$(zone$): action$ = "USAR_" + QAGLprocessForLabel$(itemDesc$) + "_EN": EXIT SUB
	IF zones(zoneSelected%).flag > 0 THEN zone$ = RTRIM$(zone$): action$ = "IR": EXIT SUB
   
	' Paint box at.
	Xb% = x% \ 8 + 1 - 3: Yb% = y% \ 8 + 1
	IF Xb% < 1 THEN Xb% = 1
	IF Yb% < 1 THEN Yb% = 1
	IF Xb% > 35 THEN Xb% = 35
	IF Yb% > 23 THEN Yb% = 23
	x0% = (Xb% - 1) * 8 - 4: x1% = x0% + 55
	y0% = (Yb% - 1) * 8 - 4: y1% = y0% + 23
	LINE (x0%, y0%)-(x1%, y1%), 0, BF
	QAGLfancyBoxWire x0%, y0%, x1%, y1%
	
	COLOR 15: LOCATE Yb%, Xb%: PRINT "MIRAR"; : LOCATE Yb% + 1, Xb%: PRINT "ACCION";
	clot$ = ""
	
	GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
	DO
		MOUSEstatus l%, B%, xm%, ym%
		x% = xm% - 4: y% = ym% - 4
		QAGLmouseLimit x%, y%
		
		' Check action
		crsr% = 1
		action$ = ""
		IF xm% >= x0% AND xm% <= x1% AND ym% >= y0% AND ym% <= y1% THEN
			IF ym% < y0% + 12 THEN
				action$ = "MIRAR"
			ELSE
				action$ = "ACCION"
			END IF
			lot$ = action$ + " " + zone$
		ELSE
			lot$ = zone$
		END IF
				
		IF clot$ <> lot$ THEN
			clot$ = lot$
			LOCATE 1, 2: PRINT QAGLprocrust$(lot$, 27);
		END IF
		
		IF cx% <> x% OR cy% <> y% OR ccrsr% <> crsr% THEN
			PUT (cx%, cy%), QAGLcursors%(0, 0), PSET
			GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
			PUT (x%, y%), QAGLcursors%(0, crsr%), XOR
			cx% = x%
			cy% = y%
			ccrsr% = crsr%
		END IF
		
		IF l% OR r% THEN EXIT DO
		k$ = INKEY$: IF k$ = CHR$(27) THEN breakMe% = -1: EXIT SUB
	LOOP
	DO
		MOUSEstatus l%, B%, xm%, ym%
		IF NOT l% AND NOT r% THEN EXIT DO
	LOOP
	
	zone$ = RTRIM$(zone$)
	QAGLrec
END SUB

SUB QAGLactionStatusBar
	COLOR 15: LOCATE 1, 1: PRINT SPACE$(40); : LINE (224, 0)-(224, 7), 7: LOCATE 1, 30: PRINT "INVENTARIO"
END SUB

SUB QAGLadvanceScriptTo (f%, fileName$, label$)
	CLOSE #f%
	loops% = 0
	OPEN fileName$ FOR INPUT AS #f%
	label$ = UCASE$(label$)
	DO
		LINE INPUT #f%, linea$
		linea$ = UCASE$(LTRIM$(RTRIM$(linea$)))
		IF linea$ = label$ THEN EXIT DO
		IF EOF(f%) THEN
			IF loops% = 0 THEN
				CLOSE #f%: OPEN fileName$ FOR INPUT AS #f%: loops% = 1
			ELSE
				EXIT DO
			END IF
		END IF
	LOOP
END SUB

SUB QAGLcenter (T$)
	LOCATE QAGLboxY%, 21 - LEN(T$) \ 2: PRINT T$;
	QAGLboxY% = QAGLboxY% + 2
END SUB

FUNCTION QAGLchooseAnswer% (a1$, a2$, a3$)
END FUNCTION

SUB QAGLfancyBoxWire (x0%, y0%, x1%, y1%)
	LINE (x0%, y0%)-(x1% - 1, y0%), 15
	PSET (x1%, y0%), 7
	LINE (x0%, y0%)-(x0%, y1% - 1), 15
	PSET (x0%, y1%), 7
	LINE (x0% + 1, y1%)-(x1%, y1%), 8
	LINE (x1%, y0% + 1)-(x1%, y1%), 8
	LINE (x0% - 1, y0% - 1)-(x1% + 1, y1% + 1), 1, B
END SUB

FUNCTION QAGLfileExists% (fileName$)
	f% = FREEFILE
	OPEN fileName$ FOR BINARY AS #f%
	IF LOF(f%) = 0 THEN
		CLOSE #f%
		KILL fileName$
		QAGLfileExists% = 0
	ELSE
		CLOSE #f%
		QAGLfileExists% = -1
	END IF
END FUNCTION

FUNCTION QAGLlabelExists% (fileName$, label$)
	found% = 0
	label$ = UCASE$(LTRIM$(RTRIM$(label$)))
	FOR i% = 0 TO maxLabels% - 1
		IF labelNameBuffer$(i%) = label$ THEN
			found% = labelFPosBuffer%(i%)
		END IF
	NEXT i%
	QAGLlabelExists% = found%
END FUNCTION

SUB QAGLloadCursors (fileName$)
	DEF SEG = VARSEG(QAGLcursors%(0, 0))
	BLOAD fileName$, VARPTR(QAGLcursors%(0, 0))
	DEF SEG
END SUB

SUB QAGLloadPal (fileName$)
	DIM d AS STRING * 1
	f% = FREEFILE
	OPEN fileName$ FOR BINARY AS #f%
	OUT &H3C8, 0
	FOR i% = 0 TO 255
		GET #f%, , d: OUT &H3C9, ASC(d)
		GET #f%, , d: OUT &H3C9, ASC(d)
		GET #f%, , d: OUT &H3C9, ASC(d)
	NEXT i%
	CLOSE f%
END SUB

SUB QAGLmouseLimit (x%, y%)
	IF x% < 0 THEN x% = 0
	IF y% < 0 THEN y% = 0
	IF x% > 312 THEN x% = 312
	IF y% > 192 THEN y% = 192
END SUB

SUB QAGLopenBox (type$)
	QAGLboxX1% = 38
	SELECT CASE UCASE$(type$)
		CASE "RIGHT":
			LINE (164, 4)-(315, 195), 0, BF
			'LINE (164, 4)-(315, 195), 7, B
			QAGLfancyBoxWire 164, 4, 315, 195
			QAGLboxX0% = 23
			QAGLboxY% = 2
		CASE "BOTTOM":
			LINE (4, 140)-(315, 195), 0, BF
			'LINE (4, 140)-(315, 195), 7, B
			QAGLfancyBoxWire 4, 140, 315, 195
			QAGLboxX0% = 3
			QAGLboxY% = 19
		CASE "CENTER":
			LINE (4, 68)-(315, 123), 0, BF
			'LINE (4, 68)-(315, 123), 7, B
			QAGLfancyBoxWire 4, 68, 315, 123
			QAGLboxX0% = 3
			QAGLboxY% = 10
	END SELECT
END SUB

SUB QAGLparseFileForLabels (fileName$)
	maxLabels% = 0
	f% = FREEFILE: OPEN fileName$ FOR INPUT AS #f%
	WHILE NOT EOF(f%)
		curPos% = SEEK(f%)
		LINE INPUT #f%, linea$
		linea$ = LTRIM$(RTRIM$(linea$))
		IF LEN(linea$) > 1 THEN
			IF LEFT$(linea$, 1) = ":" THEN
			labelFPosBuffer%(maxLabels%) = curPos%
			labelNameBuffer$(maxLabels%) = UCASE$(linea$)
			maxLabels% = maxLabels% + 1
			END IF
		END IF
	WEND
	CLOSE #f%
END SUB

FUNCTION QAGLpreprocess$ (word$)
	output$ = ""
	i% = 1
	WHILE i% <= LEN(word$)
		m$ = MID$(word$, i%, 1)
		IF m$ = "\" THEN
			i% = i% + 1: m$ = MID$(word$, i%, 1)
			SELECT CASE m$
				CASE "a": m$ = " "
				CASE "e": m$ = "‚"
				CASE "i": m$ = "¡"
				CASE "o": m$ = "¢"
				CASE "u": m$ = "£"
				CASE "v": m$ = ""
				CASE "¤": m$ = "¤"
				CASE "A": m$ = " "
				CASE "E": m$ = ""
				CASE "I": m$ = "¡"
				CASE "O": m$ = "¢"
				CASE "U": m$ = "£"
				CASE "¥": m$ = "¥"
				CASE "!": m$ = "­"
				CASE "?": m$ = "¨"
			END SELECT
			output$ = output$ + m$
		ELSE
			output$ = output$ + m$
		END IF
		i% = i% + 1
	WEND
	QAGLpreprocess$ = output$
END FUNCTION

SUB QAGLprint (text$)
	text$ = text$ + " ": o$ = ""
	x% = QAGLboxX0%
	COLOR 15
	FOR i% = 1 TO LEN(text$)
		m$ = MID$(text$, i%, 1)
		IF m$ = " " THEN
			IF LEN(o$) > 0 THEN
				o$ = QAGLpreprocess$(o$)
				IF LEN(o$) + x% > QAGLboxX1% THEN
					x% = QAGLboxX0%: QAGLboxY% = QAGLboxY% + 1
				END IF
				LOCATE QAGLboxY%, x%: PRINT o$;
				LET x% = x% + LEN(o$) + 1
				o$ = ""
			END IF
		ELSE
			o$ = o$ + m$
		END IF
	NEXT i%
	QAGLboxY% = QAGLboxY% + 2
END SUB

FUNCTION QAGLprocessForLabel$ (s$)
	res$ = ""
	FOR i% = 1 TO LEN(s$)
		m$ = MID$(s$, i%, 1): IF m$ = " " THEN m$ = "_"
		res$ = res$ + m$
	NEXT i%
	QAGLprocessForLabel$ = res$
END FUNCTION

FUNCTION QAGLprocrust$ (s$, l%)
	IF LEN(s$) >= l% THEN res$ = LEFT$(s$, l%) ELSE res$ = s$ + SPACE$(l% - LEN(s$))
	QAGLprocrust$ = res$
END FUNCTION

SUB QAGLrec
	PCOPY 7, 0
END SUB

FUNCTION QAGLrunScript% (fileName$, label$, auxs$, auxv%)
	IF NOT QAGLfileExists%(fileName$) THEN PRINT "NO SCRIPT " + fileName$ + ".": QAGLrunScript% = 255: EXIT FUNCTION
	QAGLparseFileForLabels fileName$
	
	f% = FREEFILE
	OPEN fileName$ FOR INPUT AS #f%
	IF label$ <> "" THEN
		QAGLadvanceScriptTo f%, fileName$, label$
	END IF
	debug% = 0

	panic% = 0
	actionPrefix$ = ""
	breakMe% = 0
	engineFlagsOffset% = 250
	
	WHILE NOT EOF(f%) AND NOT panic%
		LINE INPUT #f%, linea$
		linea$ = LTRIM$(RTRIM$(linea$))
		PARSERparse linea$
		PARSERdoFlags
		comm$ = UCASE$(words$(0))
		IF LEN(comm$) > 1 THEN
			IF LEFT$(comm$, 1) = "$" THEN
				' $X Y -> SET X Y
				comm$ = "SET"
				words$(2) = words$(1)
				words$(1) = RIGHT$(words$(0), LEN(words$(0)) - 1)
			END IF
		END IF
		SELECT CASE comm$
			CASE "MUSIC":
				IF soundBlasterDetected% THEN
					IF UCASE$(words$(1)) = "PLAY" THEN
						FMload words$(2)
					ELSE
						PLAY STOP: FMbeSilent
					END IF
				END IF
			CASE "OPENBOX": QAGLsve: SCREEN , , 0, 0: QAGLopenBox words$(1)
			CASE "SOUND":
				IF soundBlasterDetected% THEN
					IF UCASE$(words$(2)) = "BG" THEN DMAplayVOCBG words$(1), 8000 ELSE DMAplayVOC words$(1), 8000
				END IF
			CASE "CLOSEBOX": QAGLrec
			CASE "PRINT": SCREEN , , 0, 0: QAGLprint words$(1)
			CASE "TEXTWT"
				' OPENBOX, PRINT..., WT, CLOSEBOX composite
				QAGLsve
				SCREEN , , 0, 0: QAGLopenBox words$(1)
				i% = 2
				WHILE words$(i%) <> "" AND words$(i%) <> "END"
					QAGLprint words$(i%)
					i% = i% + 1
				WEND
				QAGLwt x%, y%, 3: flags%(engineFlagsOffset% + 3) = x%: flags%(engineFlagsOffset% + 4) = y%
				QAGLrec
			CASE "CLS": SCREEN , , 1, 0: CLS
			CASE "SLEEP": SLEEP VAL(words$(1))
			CASE "WT": SCREEN , , 0, 0: QAGLwt x%, y%, 3: flags%(engineFlagsOffset% + 3) = x%: flags%(engineFlagsOffset% + 4) = y%
			CASE "PUT": SCREEN , , 1, 0: EGAloadPut VAL(words$(1)), VAL(words$(2)), words$(3)
			CASE "SCREEN": SCREEN , , 1, 0: EGAloadPut 0, 0, words$(1)
			CASE "BLIT": PCOPY 1, 0: QAGLsve
			CASE "SET": flags%(VAL(words$(1))) = VAL(words$(2))
			CASE "ANSWER":
				flags%(engineFlagsOffset% + 1) = QAGLchooseAnswer%(words$(1), words$(2), words$(3))
			CASE "RESETZONES": maxZone% = -1
			CASE "ZONE":
				maxZone% = maxZone% + 1
				zones(maxZone%).title = words$(1)
				zones(maxZone%).x1 = VAL(words$(2))
				zones(maxZone%).y1 = VAL(words$(3))
				zones(maxZone%).x2 = VAL(words$(4))
				zones(maxZone%).y2 = VAL(words$(5))
				IF words$(6) = "" THEN
					zones(maxZone%).flag = 0
				ELSEIF words$(6) = "EXIT" THEN
					zones(maxZone%).flag = 1
				ELSE
					zones(maxZone%).flag = VAL(words$(6))
				END IF

				IF debug% THEN
					SCREEN , , 0, 0
					LINE (zones(maxZone%).x1, zones(maxZone%).y1)-(zones(maxZone%).x2, zones(maxZone%).y2), 12, B
					LOCATE zones(maxZone%).y1 \ 8 + 1, zones(maxZone%).x1 \ 8 + 1: PRINT zones(maxZone%).title
				END IF
			CASE "ZONEMODIFY":
				thisZone% = -1
				FOR i% = 0 To maxZone%
					IF words$(1) = zones(i%).title THEN 
						thisZone% = i%
						EXIT FOR
					END IF
				NEXT i%
				IF thisZone% >= 0 THEN
					zones(thisZone%).title = words$(2)
					zones(thisZone%).x1 = VAL(words$(3))
					zones(thisZone%).y1 = VAL(words$(4))
					zones(thisZone%).x2 = VAL(words$(5))
					zones(thisZone%).y2 = VAL(words$(6))
					IF words$(7) = "" THEN
						zones(thisZone%).flag = 0
					ELSEIF words$(7) = "EXIT" THEN
						zones(thisZone%).flag = 1
					ELSE
						zones(thisZone%).flag = VAL(words$(6))
					END IF

					IF debug% THEN
						SCREEN , , 0, 0
						LINE (zones(thisZone%).x1, zones(thisZone%).y1)-(zones(thisZone%).x2, zones(thisZone%).y2), 12, B
						LOCATE zones(thisZone%).y1 \ 8 + 1, zones(thisZone%).x1 \ 8 + 1: PRINT zones(thisZone%).title
					END IF
				END IF
			CASE "ZONEDELETE":
				thisZone% = -1
				FOR i% = 0 To maxZone%
					IF words$(1) = zones(i%).title THEN 
						thisZone% = i%
						EXIT FOR
					END IF
				NEXT i%
				IF thisZone% >= 0 THEN
					zones(thisZone%).x1 = -1
					zones(thisZone%).y1 = -1
					zones(thisZone%).x2 = -1
					zones(thisZone%).y2 = -1
				END IF
			CASE "DOACTIONS":
				SCREEN , , 0, 0
				actionPrefix$ = words$(1)
				QAGLaction action$, zone$, x%, y%
				action$ = LTRIM$(RTRIM$(UCASE$(action$)))
				zone$ = LTRIM$(RTRIM$(UCASE$(zone$)))
				IF action$ <> "" AND zone$ <> "" THEN
					autoLabel$ = actionPrefix$ + "_" + action$ + "_" + QAGLprocessForLabel$(zone$)
					fPos% = QAGLlabelExists%(fileName$, autoLabel$)
					IF fPos% > 0 THEN
						SEEK #f%, fPos%
					ELSE
						autoLabel$ = actionPrefix$ + "_DEFAULT_ACTION"
						fPos% = QAGLlabelExists%(fileName$, autoLabel$)
						IF fPos% > 0 THEN SEEK #f%, fPos%
					END IF
				END IF
			CASE "INPUT":
				idx% = VAL(words$(1))
				res% = -1
				WHILE res% = -1
					k$ = INKEY$
					IF k$ >= "0" AND k$ <= "9" THEN
						res% = VAL(k$)
					END IF
				WEND
				flags%(idx%) = res%
			CASE "GOTO":
				fPos% = QAGLlabelExists%(fileName$, words$(1))
				IF fPos% > 0 THEN SEEK #f%, fPos% ELSE panic% = -1
				'QAGLadvanceScriptTo f%, fileName$, words$(1)
			CASE "GOTOF":
				fPos% = QAGLlabelExists%(fileName$, words$(1) + "_" + LTRIM$(STR$(flags%(VAL(words$(2))))))
				IF fPos% > 0 THEN SEEK #f%, fPos%
				'QAGLadvanceScriptTo f%, fileName$, words$(1) + "_" + LTRIM$(STR$(flags%(VAL(words$(2)))))
			CASE "RETURN":
				fPos% = QAGLlabelExists%(fileName$, actionPrefix$ + "_MAINLOOP")
				IF fPos% > 0 THEN SEEK #f%, fPos% ELSE panic% = -1
				'QAGLadvanceScriptTo f%, fileName$, actionPrefix$ + "_MAINLOOP"
			CASE "EQ":
				v1% = VAL(words$(1))
				v2% = VAL(words$(2))
				label$ = words$(3)
				IF v1% = v2% THEN
					IF label$ <> "" THEN
						fPos% = QAGLlabelExists%(fileName$, label$)
						IF fPos% > 0 THEN SEEK #f%, fPos%
						'QAGLadvanceScriptTo f%, fileName$, label$
					END IF
				END IF
			CASE "NEQ":
				v1% = VAL(words$(1))
				v2% = VAL(words$(2))
				label$ = words$(3)
				IF v1% <> v2% THEN
					IF label$ <> "" THEN
						fPos% = QAGLlabelExists%(fileName$, label$)
						IF fPos% > 0 THEN SEEK #f%, fPos%
						'QAGLadvanceScriptTo f%, fileName$, label$
					END IF
				END IF
			CASE "LT":
				v1% = VAL(words$(1))
				v2% = VAL(words$(2))
				label$ = words$(3)
				IF v1% < v2% THEN
					IF label$ <> "" THEN
						fPos% = QAGLlabelExists%(fileName$, label$)
						IF fPos% > 0 THEN SEEK #f%, fPos%
						'QAGLadvanceScriptTo f%, fileName$, label$
					END IF
				END IF
			CASE "GE":
				v1% = VAL(words$(1))
				v2% = VAL(words$(2))
				label$ = words$(3)
				IF v1% > v2% THEN
					IF label$ <> "" THEN
						fPos% = QAGLlabelExists%(fileName$, label$)
						IF fPos% > 0 THEN SEEK #f%, fPos%
						'QAGLadvanceScriptTo f%, fileName$, label$
					END IF
				END IF
			CASE "RUN":
				fileName$ = words$(1)
				label$ = words$(2)
				CLOSE #f%
				IF NOT QAGLfileExists%(fileName$) THEN PRINT "NO SCRIPT " + fileName$ + ".": QAGLrunScript% = 255: EXIT FUNCTION
				QAGLparseFileForLabels fileName$
				f% = FREEFILE
				OPEN fileName$ FOR INPUT AS #f%
				IF label$ = "" OR label$ = "INI" THEN
					fPos% = QAGLlabelExists%(fileName$, label$)
					IF fPos% > 0 THEN SEEK #f%, fPos%
					'QAGLadvanceScriptTo f%, fileName$, label$
				END IF
			CASE "THE_END": panic% = -1
			CASE "INVENTORY": IF words$(1) = "ON" THEN inventoryOn% = -1 ELSE inventoryOn% = 0
			CASE "CLEARINVENTORY": FOR i% = 0 TO 9: inventory(i%).idItem = 0: inventory(i%).flags = 0: NEXT i%
			CASE "CLEARITEMS": lastItem% = 1: itScrX% = 32: itScrY% = 0
			CASE "DEFEMPTY":
				items(0).desc = "VACIO"
				items(0).file = words$(1)
				items(0).x = 0
				items(0).y = 0
				SCREEN , , 6, 0
				EGAloadPut 0, 0, words$(1)
				SCREEN , , 0, 0
			CASE "DEFITEM":
				items(lastItem%).desc = words$(1)
				items(lastItem%).file = words$(2)
				items(lastItem%).x = itScrX%
				items(lastItem%).y = itScrY%
				SCREEN , , 6, 0
				EGAloadPut itScrX%, itScrY%, words$(2)
				SCREEN , , 0, 0
				itScrX% = itScrX% + 32: IF itScrX% = 320 THEN itScrY% = itScrY% + 32: itScrX% = 0
				lastItem% = lastItem% + 1
			CASE "GRAB":
				FOR i% = 0 TO lastItem% - 1
					IF RTRIM$(items(i%).desc) = words$(1) THEN
						' Find free inventory slot
						slot% = -1: FOR j% = 0 TO 9
							IF inventory(j%).idItem = 0 THEN
								slot% = j%
								EXIT FOR
							END IF
						NEXT j%

						QAGLsve
						SCREEN , , 0, 0
						QAGLopenBox "CENTER"
						QAGLboxY% = 12
						IF slot% < 0 THEN
							QAGLcenter "No puedes coger más objetos"
						ELSE
							QAGLcenter "Coges [" + RTRIM$(items(i%).desc) + "]"
							inventory(slot%).idItem = i%
						END IF
						QAGLwt xd%, yd%, 3
						QAGLrec
						EXIT FOR
					END IF
				NEXT i%
			CASE "DROP":
				FOR i% = 0 TO lastItem% - 1
					IF RTRIM$(items(i%).desc) = words$(1) THEN
						FOR j% = 0 TO 9
							IF inventory(j%).idItem = i% THEN
								inventory(j%).idItem = 0
								EXIT FOR
							END IF
						NEXT j%
						EXIT FOR
					END IF
				NEXT i%
			CASE "HASITEM":
				FOR i% = 0 TO lastItem% - 1
					IF RTRIM$(items(i%).desc) = words$(1) THEN
						FOR j% = 0 TO 9
							IF inventory(j%).idItem = i% THEN
								fPos% = QAGLlabelExists%(fileName$, words$(2))
								IF fPos% > 0 THEN SEEK #f%, fPos%
								EXIT FOR
							END IF
						NEXT j%
						EXIT FOR
					END IF
				NEXT i%
		END SELECT
		IF flags%(engineFlagsOffset% + 1) = 9 THEN panic% = -1
		IF breakMe% THEN panic% = -1
	WEND
	CLOSE #f%
	'PRINT "DEBUG KEY!": SLEEP
END FUNCTION

SUB QAGLsve
	PCOPY 0, 7
END SUB

SUB QAGLtbox (segment%, offset%, text$, x%, y%, w%, col%, tw%)
END SUB

SUB QAGLwt (x%, y%, crsr%)
	MOUSEstatus l%, B%, xm%, ym%
	x% = xm% - 4: y% = ym% - 4
	QAGLmouseLimit x%, y%
	GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
	PUT (x%, y%), QAGLcursors%(0, crsr%), XOR
	cx% = x%: cy% = y%
	WHILE INKEY$ <> "": WEND
	DO
		MOUSEstatus l%, B%, xm%, ym%
		x% = xm% - 4: y% = ym% - 4
		QAGLmouseLimit x%, y%
		IF cx% <> x% OR cy% <> y% THEN
			PUT (cx%, cy%), QAGLcursors%(0, 0), PSET
			GET (x%, y%)-(7 + x%, 7 + y%), QAGLcursors%(0, 0)
			PUT (x%, y%), QAGLcursors%(0, crsr%), XOR
			cx% = x%
			cy% = y%
		END IF
		IF l% OR r% THEN EXIT DO
		k$ = INKEY$: IF k$ = CHR$(27) THEN breakMe% = -1: EXIT SUB
		IF k$ <> "" THEN EXIT DO
	LOOP
	DO
		MOUSEstatus l%, B%, xm%, ym%
		IF NOT l% AND NOT r% AND INKEY$ = "" THEN EXIT DO
	LOOP
	PUT (cx%, cy%), QAGLcursors%(0, 0), PSET
END SUB

FUNCTION SBdspReset%
  OUT baseport% + &H6, &H1
  FOR ct% = 1 TO 100
  NEXT ct%
  OUT baseport% + &H6, &H0
  ct% = 0
  stat% = 0
  WHILE (stat% <> &HAA) AND (ct% < 100)
	stat% = INP(baseport% + &HE)
	stat% = INP(baseport% + &HA)
	ct% = ct% + 1
  WEND
  IF stat% = &HAA THEN SBdspReset% = 0 ELSE SBdspReset% = -1
END FUNCTION

FUNCTION SBgetDMA%
  OUT baseport% + &H4, &H81
  SELECT CASE INP(baseport% + &H5) AND &HB
	CASE &H1
	  SBgetDMA% = 0
	CASE &H2
	  SBgetDMA% = 1
	CASE &H8
	  SBgetDMA% = 3
	CASE ELSE
	  SBgetDMA% = -1
  END SELECT
END FUNCTION

FUNCTION SBgetIRQ%
  OUT baseport% + &H4, &H80
  SELECT CASE INP(baseport% + &H5) AND &HF
	CASE &H1
	  SBgetIRQ% = 2
	CASE &H2
	  SBgetIRQ% = 5
	CASE &H4
	  SBgetIRQ% = 7
	CASE &H8
	  SBgetIRQ% = 10
	CASE ELSE
	  SBgetIRQ% = -1
  END SELECT
END FUNCTION

FUNCTION SBisSb%
  baseport% = &H220
  sbdetected% = -1
  WHILE (baseport% <= &H280) AND (sbdetected% = -1)
	sbdetected% = SBdspReset%
	IF sbdetected% = -1 THEN baseport% = baseport% + &H20
  WEND
  SBisSb% = NOT sbdetected%
END FUNCTION

