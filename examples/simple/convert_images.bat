@echo off

..\..\utils\QB1AGLEimgcnv.exe in=reswip\office.png out=gfx\scr00bg.put
..\..\utils\QB1AGLEimgcnv.exe in=reswip\opendoor.png out=gfx\scr00c1.put
..\..\utils\QB1AGLEimgcnv.exe in=reswip\id_card_266_126.png out=gfx\scr00c2.put
..\..\utils\QB1AGLEimgcnv.exe in=reswip\empty_266_126.png out=gfx\scr00c3.put
..\..\utils\QB1AGLEimgcnv.exe in=reswip\CD03CH2.png out=gfx\scr00ch.put mode=trans
rem inventario:
..\..\utils\QB1AGLEimgcnv.exe in=reswip\allitems.png out=gfx\itempty.cut cutout=0,0,31,31
..\..\utils\QB1AGLEimgcnv.exe in=reswip\allitems.png out=gfx\itemkey.cut cutout=32,0,63,31
..\..\utils\QB1AGLEimgcnv.exe in=reswip\allitems.png out=gfx\itemid.cut cutout=64,0,95,31
..\..\utils\QB1AGLEimgcnv.exe in=reswip\allitems.png out=gfx\itempant.cut cutout=96,0,127,31

