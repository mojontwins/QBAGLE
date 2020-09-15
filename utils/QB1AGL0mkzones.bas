' ZONE creater for QB1AGL0
' Copyleft 2015 by The Mojon Twins

' fbc QB1AGL0mkzones.bas cmdlineparser.bas

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

Const EST_IDLE = 0
Const EST_DRAWING = 1

Sub usage 
	Puts "$ QB1AGL0mkzones.exe in=file.png out=file.spt [impos=x,y]"
	Puts ""
	Puts "in        Input filename"
	Puts "out       Output filaname"
	Puts "impos     put image there, otherwise on 0,0."
	Puts ""
	Puts "While editting:"
	Puts "    Left mouse (hold) to draw up to 16 rectangles."
	Puts "    Space toggle EXITS/ZONES."
	Puts "    Right-click on rectangle to delete."
	Puts "    Press ENTER to Save & Exit"
	Puts "    Press ESC to Exit"
End Sub

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

Type zone
	x1 As Integer
	x2 As Integer
	y1 As Integer
	y2 As Integer
	desc As String * 16
	flag As Integer
	on As Integer
End Type

Dim As Integer xImg0, yImg0, i
Dim As Integer outF
Dim As String inFn, outFn, k
Dim As Integer coords (8)
Dim As Any Ptr img, buffer
Dim As Integer xM, yM, wheelM, buttnM
Dim As Integer buttnWas
Dim As Integer mouseUp, mouseDown
Dim As zone zones (16)
Dim As Integer zonesIndex, clr
Dim As Integer state
Dim As Integer mode
Dim As Integer pressed

' Read parameters
sclpParseAttrs

' Input / Output are mandatory
inFn = sclpGetValue ("in"): If inFn = "" Then usage: End
outFn = sclpGetValue ("out"): If outFn = "" Then usage: End

' impos
If sclpGetValue ("impos") <> "" Then
	coordinatesStringToArray sclpGetValue ("impos"), coords ()
	xImg0 = coords (0)
	yImg0 = coords (1)
Else 
	xImg0 = 0: yImg0 = 0
End If

screenres 320, 200, 32
buffer = ImageCreate (320, 200, RGB (0, 0, 0))
img = png_load (inFn)

zonesIndex = 0: state = EST_IDLE: mode = 0
Do
	Line buffer, (0, 0)-(319,199), RGB (0, 0, 0), bf
	Put buffer, (xImg0, yImg0), img, Pset
	If mode Then Draw String buffer, (0, 192), "EXIT", RGB (255, 255, 255) Else Draw String buffer, (0, 192), "NORMAL", RGB (255, 255, 255)
	
	k = Inkey
	If Asc (k) = 27 Then Exit Do
	If Asc (k) = 13 Then 
		outF = FreeFile
		Open outFn For Output As #outF
		For i = 0 To 16
			If zones (i).on Then
				Print #outF, "ZONE """ & zones (i).desc & """, " & zones (i).x1 & ", " & zones (i).y1 & ", " & zones (i).x2 & ", " & zones (i).y2;
				If zones (i).flag <> 0 Then Print #outF, ", EXIT" Else Print #outF, ""
			End If
		Next i
		Close #outF
		Exit Do
	End If
	If Asc (k) = 32 Then
		If Not pressed Then
			pressed = -1
			mode = 1 - mode
		End If
	Else
		pressed = 0
	End If
	
	GetMouse xM, yM, wheelM, buttnM
	
	' Detect mouse up/down events
	If buttnM = -1 Then buttnM = buttnWas
	
	mouseDown = ((buttnM And 1) = 1 And (buttnWas And 1) = 0)
	mouseUp = ((buttnM And 1) = 0 And (buttnWas And 1) = 1)
	buttnWas = buttnM
	
	' New zones
	If mouseDown Then 
		' Find zonesIndex
		state = EST_IDLE
		For i = 0 To 16
			If zones (i).on = 0 Then
				zones (i).on = -1
				zonesIndex = i
				state = EST_DRAWING
				zones (zonesIndex).x1 = xM: zones (zonesIndex).y1 = yM
				Exit For
			End If
		Next i		
	End If
	
	If (buttnM And 1) = 1 And state = EST_DRAWING Then
		zones (zonesIndex).x2 = xM: zones (zonesIndex).y2 = yM
		If mode = 1 Then zones (zonesIndex).flag = 1 Else zones (zonesIndex).flag = 0
	End If
	
	If mouseUp And state = EST_DRAWING Then
		If zones (zonesIndex).x1 <> 0 And zones (zonesIndex).y1 <> 0 And zones (zonesIndex).x2 <> 0 And zones (zonesIndex).y2 <> 0 Then
			While Inkey <> "": Wend
			Locate 1, 1: Print Space (40): Locate 1,1: Input "DESC:", zones (zonesIndex).desc
		End If
	End If
	
	' Erase
	If (buttnM And 2) = 2 Then
		For i = 0 To 16
			If xM >= zones (i).x1 And xM <= zones (i).x2 And yM >= zones (i).y1 And yM <= zones (i).y2 Then
				zones (i).on = 0
			End If
		Next i
	End If
	
	' Draw
	For i = 0 To 16
		If zones (i).on Then
			If zones (i).flag <> 0 Then clr = RGB (0, 255, 0) Else clr = RGB (250, 240, 255)
			Line buffer, (zones (i).x1, zones (i).y1)-(zones (i).x2, zones (i).y2), clr, B
			Draw String buffer, (zones (i).x1 + 1, zones (i).y1 + 1), zones (i).desc
		End if
	Next i
	
	Put (0, 0), buffer, Pset
Loop
