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

# Construyendo el script

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
