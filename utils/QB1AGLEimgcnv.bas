' PUT image converter for QB1AGLE
' Copyleft 2015 by The Mojon Twins

' fbc QB1AGLEimgcnv.bas cmdlineparser.bas

#include "file.bi"
#include "fbpng.bi"
#include "fbgfx.bi"
#include once "crt.bi"

#include "cmdlineparser.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

#define MSB( i ) ( ( ( i ) Shr 8 ) And 255 )
#define LSB( i ) ( i And 255 )

Dim Shared As Integer QB1AGLEpal (16) = {_
	&HFF0000AA, &HFF000000, &HFF00AA00, &HFF00AAAA, &HFFAA0000, &HFFAA00AA, &HFFAA5500, &HFFAAAAAA, _
	&HFF555555, &HFF5555FF, &HFF55FF55, &HFF55FFFF, &HFFFF5555, &HFFFF55FF, &HFFFFFF55, &HFFFFFFFF _
}


Sub usage
	Puts "$ QB1AGLEimgcnv.exe in=file.png out=file.put [mode=trans] [cutout=x0,y0,x1,y1]"
	Puts ""
	Puts "in        Input filename"
	Puts "out       Output filaname"
	Puts "mode      solid or trans, solid is default."
	Puts "cutout    output rectangle (coordinates inclusive) instead of full image"
End Sub

Function findPalColour (c As Integer) As uByte
	Dim As Integer i, fnd
	Dim As uByte res
	res = &HFF: For i = 0 To 15
		If QB1AGLEpal (i) = c Then res = i: fnd = -1: Exit For
	Next i
	findPalColour = res
End Function

Sub coordinatesStringToArray (coordsString as String, coords () As Integer)
	Dim As Integer i, idx
	Dim As String m, coordString
	
	coordsString = coordsString & ","
	idx = 0
	
	For i = 1 To Len (coordsString)
		m = Mid (coordsString, i, 1)
		If m = "," Then
			coords (idx) = Val (coordString)
			idx = idx + 1
			coordString = ""			
		Else
			coordString = coordString & m
		End If
	Next i
End Sub

Dim As String inFn, outFn, mode
Dim As Integer inF, outF
Dim As Integer x0, y0, x1, y1, x, y, length, bitPlane, bits, c
Dim As uByte bitPlanes (3)
Dim As Integer w, h, w0
Dim As Any Ptr img
Dim As Integer coords (8)
Dim As uByte d, bitMask, bitPlaneMask

screenres 640, 480, 32, , -1

' Read parameters
sclpParseAttrs

' Input / Output are mandatory
inFn = sclpGetValue ("in"): If inFn = "" Then usage: End
outFn = sclpGetValue ("out"): If outFn = "" Then usage: End

' Mode. Default is solid.
mode = sclpGetValue ("mode"): If mode = "" Then mode = "solid"
If mode <> "solid" And mode <> "trans" Then usage: End

' Get input file dimensions
img = png_load (sclpGetValue ("in"))
If ImageInfo (img, w, h, , , , ) Then
	' Error!
End If

' Cutout size
If sclpGetValue ("cutout") <> "" Then
	coordinatesStringToArray sclpGetValue ("cutout"), coords ()
	x0 = coords (0)
	y0 = coords (1)
	x1 = coords (2)
	y1 = coords (3)
Else
	x0 = 0: y0 = 0: x1 = w - 1: y1 = h - 1
End If

' Fix so width is always multiple of 8
w = x1 - x0 + 1: h = y1 - y0 + 1
'Puts "w = " & w & ", h = " & h

If w <> ((w \ 8) * 8) Then
	w0 = w
	w = (w0 \ 8) * 8
	x1 = x0 + w - 1
	Puts "Warning, width = " & w0 & " not a multiple of 8. Trimming to " & w
End If

' Check
If w = 0 Or h = 0 Then Puts "Error: selected rectangle dimensions cannot be 0": End
If w > 320 Or h > 200 Then Puts "Error: input image must be smaller or equal to 320x200": End

' Proper output filename
If sclpGetValue ("properfn") <> "" and mode = "put" Then
	If Len (outFn) < 3 Then outFn = String (3 - Len (outFn), "0") & outFn Else outFn = Left (outFn, 3)
	outFn = outFn + Hex (w, 3) + Hex (h, 2) + ".PUT"
End If

' Open output filename
Kill outFn
outF = FreeFile
Open outFn For Binary As #outF

' Write QB header
d = &HFD: Put #outF, , d

' Depending on format, write header
If mode = "solid" Then
	' Segment = 0000, Offset = 0000, Length = w * h \ 2 + 4. LSB then MSB.
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	length = w * h \ 2 + 4
	d = LSB (length): Put #outF, , d
	d = MSB (length): Put #outF, , d	
Else
	' Segment = 0000, Offset = 0000, Length = 2 * (w * h \ 2 + 4). LSB then MSB.
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	d = &H00: Put #outF, , d
	length = (w * h \ 2 + 4) * 2
	d = LSB (length): Put #outF, , d
	d = MSB (length): Put #outF, , d
End If

' Now read and write the image
d = LSB (w): Put #outF, , d
d = MSB (w): Put #outF, , d
d = LSB (h): Put #outF, , d
d = MSB (h): Put #outF, , d

For y = y0 To y1
	' Three bitplanes
	For	bitPlane = 0 To 3
		'bitPlaneMask = 1 Shl (3 - bitPlane)
		bitPlaneMask = 1 Shl bitPlane
		For x = x0 To x1 Step 8
			bitPlanes (bitPlane) = 0
			For bits = 0 To 7
				bitMask = 1 Shl (7 - bits)
				c = findPalColour (Point (x + bits, y, img))
				If c = &HFF Then c = 0
				If c And bitPlaneMask Then bitPlanes (bitPlane) = bitPlanes (bitPlane) Or bitMask
			Next bits
			Put #outF, , bitPlanes (bitPlane)
		Next x
	Next bitPlane
Next y

' If needed, write the mask
If mode = "trans" Then
	' Now read and write the mask. That's a F for a non-palette colour, 0 otherwise.
	d = LSB (w): Put #outF, , d
	d = MSB (w): Put #outF, , d
	d = LSB (h): Put #outF, , d
	d = MSB (h): Put #outF, , d
	
	For y = y0 To y1
		' Three bitplanes
		For	bitPlane = 0 To 3
			For x = x0 To x1 Step 8
				bitPlanes (bitPlane) = 0
				For bits = 0 To 7
					bitMask = 1 Shl (7 - bits)
					c = findPalColour (Point (x + bits, y, img))
					If c = &HFF Then bitPlanes (bitPlane) = bitPlanes (bitPlane) Or bitMask
				Next bits
				Put #outF, , bitPlanes (bitPlane)
			Next x
		Next bitPlane
	Next y
End If

Puts "Wrote " & outFn & ", (" & x0 & ", " & y0 & ")-(" & x1 & ", " & y1 & "), " & w & "x" & h & ", mode = " & mode & ", " & Lof (outF) & " bytes."
Close outF
