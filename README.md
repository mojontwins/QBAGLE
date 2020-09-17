# QBAGLE v1.0

QBAGLE es un sistema sencillo para crear aventuras gráficas de pantalla fija (o en primera persona) para MSDOS usando el modo EGA. Está basada en QBasic, por lo que necesita este intérprete para funcionar (incluido en `/bin/`).

QBAGLE es en realidad un intérprete de aventuras que se definen en base a un script y una serie de recursos (gráficos, músicas y sonidos). Las aventuras se basan en colocar una imagen y definir una serie de zonas activas en la pantalla sobre las que el usuario podrá hacer click. Las zonas pueden definirse como salidas, de forma que al hacer click sobre ellas se salte a otro punto del script (a otra localización por ejemplo) o como objetos o zonas de interés, que harán aparecer un sencillo menú con dos opciones: "MIRAR" o "ACCION". También se define un sencillo inventario que podemos ir poblando con objetos y que podrán ser utilizados con las zonas definidas.

# Ejecutando QBAGLE

Para ejecutar QBAGLE necesitas un PC con MSDOS o un emulador como DosBox o PcEm. Tendrás que tener `QBASIC.EXE`, `QBASIC.HLP` y `QBASIC.INI` accesibles (o bien mediante la variable `PATH` o bien en el mismo directorio que el juego).

El intérprete principal, `QB1AGLE.BAS`, cargará por defecto un archivo `SAMPLE.SPT` colocado en el mismo directorio. Si el script principal de tu aventura tiene otro nombre, deberás modificar la linea 253:

```bas
	res% = QAGLrunScript%("SAMPLE.SPT", "", "", 0)
```

## El ejemplo

La forma más fácil de que veas esto en acción es ejecutando el ejemplo mediante DosBox. Suponemos que tienes una idea básica de cómo funciona DosBox, así que partiremos de que tienes montado el directorio base de QBAGLE como unidad `D:` (por ejemplo). Para comprobarlo, al hacer `dir` deberíamos obtener este listado:

![dir](docs/main.png)

Hecho esto, entramos en `EXAMPLES\SIMPLE`:

```
D:\>cd EXAMPLES\SIMPLE
```

Desde aquí, ejecutamos el intérprete `QB1AGLE.BAS` invocando al `QBASIC.EXE` que está en `/bin`:

```
D:\EXAMPLES\SIMPLE>..\..\bin\QBASIC /run QB1AGLE.BAS
```

En el ejemplo podemos ver más o menos qué tipo de juegos podremos hacer con este sistema.

# Haciendo tu propio juego

Hacer un juego se basa en tener tus recursos, convertirlos al formato soportado por el motor (formato `PUT`, compatible con el comando del mismo nombre de QBasic), y escribir un script en un lenguaje sencillo. Hay tres tipos de recursos:

## Imagenes

Las imagenes están en un formato que QBasic pueda leer y procesar fácilmente. Hay dos tipos:

* Imágenes sólidas: se vuelcan a la pantalla tal cual.
* Imágenes transparentes: se vuelcan a la pantalla con transparencia, dejando ver lo que había antes en aquellos píxels de color "transparente".

El conversor incluido, `QB1AGLEimgcnv.exe`, procesará imagenes que empléen la paleta EGA estándar:

![EGA](docs/EGA.png)

Cualquier píxel de otro color será considerado como "transparente".

`QB1AGLEimgcnv.exe` tomará los siguientes parámetros:

```
	$ QB1AGLEimgcnv.exe in=file.png out=file.put [mode=trans] [cutout=x0,y0,x1,y1]

	in        Input filename
	out       Output filaname
	mode      solid or trans, solid is default.
	cutout    output rectangle (coordinates inclusive) instead of full image
```

Donde: 

* `in` es el nombre (con ruta opcional) de archivo de entrada, en formato `png`.
* `out` es el nombre (con ruta opcional) de archivo de salida, en formato `PUT`.
* `mode` indica si la salida será transparente o sólida. Si no se especifica este parámetro, será sólida.
* `cutout` define las coordeandas de las esquinas opuestas del rectángulo que se va a procesar. Si se omite, se procesará toda la imagen.

Restricciones y gotchas:

* Las imagenes transparentes ocupan el doble que las sólidas, pues almacenan la máscara. No emplées imagenes transparentes si no es necesario.
* Las imagenes deben tener un ancho múltiplo de 8 píxels.
* Si se especifica `cutout`, `x0, y0` debe ser las coordenadas del píxel superior izquierdo del rectángulo que se va a recortar y `x1, y1` las del inferior derecho.

## Música

La música se reproduce usando un conjunto de subrutinas creadas por Bisqwit ( https://bisqwit.iki.fi/source/fmengineqb.html ) que reproducen archivos S3M de Scream Tracker 3 que empléen sonidos FM (no samples). Actualmente no conozco otra forma de crearlos que no sea usando el propio Scream Tracker 3, al que te tendrás que acostumbrar y ejecutar en DosBOX (por ejemplo).

## Sonido

El motor es capaz de tocar archivos en formato .VOC de 8 bits sin signo a 8000Hz de hasta 8192 bytes (8Kb). Realmente oldschool. Busca tu conversor favorito para conseguirlos.

# Construyendo el script: conceptos

## El buffer fuera de pantalla.

A la hora de componer la imagen (poner un fondo, colocar sobre él pequeños recortes transparentes con objetos o cosas que deban cambiar dependiendo del estado del juego, etc), todo se hace en un buffer que debe copiarse a la pantalla visual (en realidad se hace en una página de VRAM no visible). Para ello usamos el comando `BLIT`.

## Estado del juego: Flags e inventario.

El juego no es una entidad estática. Tenemos herramientas para que la narración vaya en diferentes direcciones, y para ello tenemos dos herramientas para representar el "estado" del juego en todo momento:

### Flags

En el motor disponemos de 256 flags donde podemos almacenar valores enteros (números de -32768 a 32767). Los flags se nombran con el símbolo `$` seguido del número de flag. Por ejemplo, este comando:

```
	$10 = 1
```

Dará al flag 10 el valor 1. Inicialmente todos los flags valen 0, pero es buena práctica inicializarlos de todos modos. Los flags pueden usarse en condicionales e instrucciones de GOTO compuesto, como veremos en este manual.

### Inventario

Como hemos dicho nuestro inventario puede contener hasta 10 items. El inventario se maneja con una serie de comandos y se comprueba con una serie de condiciones que nos permiten limpiar el inventario, aadir o quitar objetos, o comprobar si tenemos un objeto en concreto.

## Etiquetas

Las etiquetas marcan un punto en el script. Deben ir al principio de la linea y empezar por dos puntos :. Servirán de destino para las instrucciones de salto.

## Comentarios

Todo el texto que aparezca a la derecha del símbolo # será ignorado por el intérprete.

# Manual de programación

## Imprimir texto

Para imprimir textos (descripciones, diálogos) primero hay que abrir una ventana de texto, y luego imprimir en ella. Cuando terminemos, podremos por ejemplo esperar a pulsar una tecla y luego cerrar la ventana de texto:

```
	OPENBOX RIGHT
	PRINT "Seguramente ya me conoces y sabes que me gusta el bocadillo de ch\opped."
	PRINT "Ay\udame a hacer un par de cosas sencillas, que me tengo que ir a trabajar..."
	WT
	CLOSEBOX	
```

* `OPENBOX RIGHT` abre una ventana de texto a la derecha. Hay tres tipos de ventanas de texto: un cuadro centrado aproximadamente de 1/3 de la altura de la pantalla (`OPENBOX CENTER`), uno pegado a la parte inferior de la pantalla e igualmente de aproximadamente 1/3 de la pantalla de altura (`OPENBOX BOTTOM`) y otro que ocupa toda la mitad derecha de la pantalla (`OPENBOX RIGHT`).

* `PRINT` imprime un párrafo con el texto que se le indica, dentro del cuadro que acabamos de abrir. Puedes añadir los párrafos que quieras (siempre que quepan).

* `WT` interrumpe la ejecución hasta que pulsemos una tecla o hagamos click.

* `CLOSEBOX` cierra la ventana y la elimina de pantalla, mostrando de nuevo el fondo que hubiera detrás.

Como construcciones como la de arriba son muy comunes, hemos añadido una abreviatura que junta todos esos comandos en uno:

```
	TEXTWT RIGHT, "Seguramente ya me conoces y sabes que me gusta el bocadillo de ch\opped.", "Ay\udame a hacer un par de cosas sencillas, que me tengo que ir a trabajar..."
```

El primer parámetro puede ser `RIGHT`, `CENTER` o `BOTTOM` y equivale al que se pasaba a `OPENBOX`. Luego, separados por comas y entre comillas, va la lista de párrafos. El comportamiento, como hemos dicho, es el mismo de antes: abre una caja de texto en el lugar especificado, imprime en ella, espera a que pulsemos una tecla o hagamos click, y finalmente "cierra" la caja de texto (eliminándola de la pantalla y restaurando el fondo).

## Mostrar imagenes

Hay dos formas de mostrar imagenes, sin importar que estas sean transparentes o sólidas:

* `SCREEN file` carga `file` del disco (puede incluir una ruta relativa o absoluta) y la dibuja en (0, 0). Suele utilizarse para cargar imagenes que ocupen toda la pantalla.

* `PUT x, y, file` carga `file` del disco (puede incluir una ruta relativa o absoluta) y la dibuja en (x, y).

Como se ha mencionado anteriormente, las imagenes no se mostrarán inmediatamente, sino que se irán dibujando en un buffer. Para hacerlo todo visible hay que ejecutar el comando `BLIT`, que copiará el buffer a la pantalla.

Además, tenemos `CLS` que borrará el buffer.

## Saltos

### Saltos incondicionales

Para saltar incondicionalmente a una etiqueta, usaremos `GOTO :etiqueta`. 

Para volver a `<action_prefix>_MAINLOOP` usaremos `RETURN` (ver `ACTION` más adelante).

### Saltos condicionales

* `GOTOF :etiqueta, flag` saltará a una etiqueta `:etiqueta_N` donde `N` es el valor de `flag`.

* `EQ v1, v2, :etiqueta` saltará a `:etiqueta` si `v1` y `v2` son *iguales*. Nótese que tanto `v1` como `v2` pueden ser un flag (si empiezan con `$`).

* `NEQ v1, v2, :etiqueta`, análogo, pero saltando si `v1` y `v2` son *distintos*.

* `LT v1, v2, :etiqueta`, análogo, pero saltando si `v1` < `v2`.

* `GE v1, v2, :etiqueta`, análogo, pero saltando si `v1` >= `v2`.

## Encadenando

* `RUN script, :etiqueta` ejecutará el script `script` (puede incluir una ruta relativa o absoluta) a partir de la etiqueta `:etiquieta`. Si `:etiqueta` se omite o vale `INI` se ejecutará desde el principio.

## Zonas

Las zonas son rectángulos de la pantalla que el jugador puede pulsar para saltar a otra localización o interactuar con lo que haya dibujado ahí.

* `RESETZONES` elimina todas las zonas definidas.

* `ZONE title, x1, y1, x2, y2, [EXIT]` define una zona llamada `title` como un rectángulo que va desde `(x1, y1)` (esquina superior izquierda) hasta `(x2, y2)` (esquina superior derecha). `title` es importante ya que identificará a esta zona en nuestro script. 

El parámetro `EXIT`, si se incluye, hace que esta zona identifique una "salida". Pronto veremos qué significa esto.

Las zonas se pueden superponer, teniendo en cuenta que las zonas se procesan en orden, por lo que si necesitas incluir una zona más pequeña dentro de una grande deberás crear antes la pequeña.

Para ayudarte a definir las zonas hemos incluid una utilidad, `QB1AGL0mkzones.exe`, que puede cargar un archivo png y te deja dibujar rectángulos con el ratón que luego exporta como texto y que puedes usar directamente en tu script.

Una vez definidas las zonas, podemos ejecutar `DOACTIONS` para que el motor deje al usuario interactuar con las zonas:

`DOACTIONS action_prefix`

Cuando el script llegue a este punto se dejará al usuario interactuar con la escena, haciendo click. Si se hace click sobre una zona y esta está definida como salida, el motor hará un `GOTO` a una etiqueta `<action_prefix>_IR_<zona>`, donde `<zona>` será la zona donde ha pulsado el usuario.

Si la zona no está definida como salida, el motor presentará un menú de dos opciones (es muy fácil cambiar el motor para añadir más opciones, por cierto; ver más adelante): `MIRAR` y `ACCION`. Dependiendo de la que pulse el usuario, el motor hará un `GOTO` a una etiqueta `<action_prefix>_<verb>_<zona>`, donde `<verb>` será el verbo que eligió el usuario y `<zona>` la zona sobre la que pulsó.

Si el usuario pulsa pero no acierta en ninguna zona, `DOACTIONS` no hará nada y el script seguirá su ejecución.

Normalmente, lo que se hace es definir una etiqueta `:<action_prefix>_MAINLOOP` antes de `DOACTIONS action_prefix`, con dos objetivos:

* Colocar un `GOTO :<action_prefix>_MAINLOOP` detrás de `DOACTIONS action_prefix` para que se vuelva a ejecutar la parte en la que se deja al usuario interactuar con la escena.
* Conseguir que `RETURN` vuelva al `DOACTIONS` de la escena.

Para ilustrarlo mejor, consideremos un ejemplo sencillo:

``` 
	:LocEjemplo
		RESETZONES
		ZONE OBJETO, 0, 0, 159, 199
		ZONE SALIDA, 160, 0, 319, 199, EXIT

	:LocEjemplo_MAINLOOP
		DOACTIONS LocEjemplo
		GOTO :LocEjemplo_MAINLOOP

	:LocEjemplo_MIRAR_OBJETO
		TEXTWT BOTTOM, "Mirar objeto"
		RETURN

	:LocEjemplo_ACCION_OBJETO
		TEXTWT BOTTOM, "Accion objeto"
		RETURN

	:LocEjemplo_IR_SALIDA
		TEXTWT BOTTOM, "Salida"

	:OtraLocEjemplo
		# ...
```

Estamos definiendo una localización "LocEjemplo". Primero ejecutamos `RESETZONES` y definimos dos grandes zonas: la mitad izquierda de la pantalla representará a un objeto, y la derecha una salida.

`DOACTIONS LocEjemplo` definirá `<action_prefix>` como `LocEjemplo` y dejará que el usuario interactúe con las zonas. Dependiendo de qué pulse, generará GOTOs a las etiquetas `:LocEjemplo_MIRAR_OBJETO`, `:LocEjemplo_ACCION_OBJETO` o `:LocEjemplo_IR_SALIDA`. Si no se pulsa sobre ninguna zona (en este ejemplo no es posible) seguiría ejecutando el script, encontraría `GOTO :LocEjemplo_MAINLOOP` y volvería atrás.

En cada una de las etiquetas imprimimos un texto y luego ejecutamos `RETURN`, que en realidad es un alias de `GOTO LocEjemplo_MAINLOOP` que resulta bastante más cómodo y legible.

## El inventario