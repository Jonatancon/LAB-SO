# Laboratorio 1 — Herramientas Unix en C

**Curso:** Sistemas Operativos
**Universidad de Antioquia**

---

## 1. Integrantes

| Nombre completo              | Correo institucional           |
| ---------------------------- | ------------------------------ |
| Jonatan Stiven Restrepo Lora | jhonatan.restrepol@udea.edu.co |

---

## 2. Descripción general

Este laboratorio implementa cuatro herramientas de línea de comandos inspiradas en utilidades Unix clásicas, escritas en C. Cada programa se compila de forma independiente.

| Programa | Función principal                                                 |
| -------- | ----------------------------------------------------------------- |
| `wcat`   | Muestra el contenido de uno o más archivos en pantalla            |
| `wgrep`  | Busca líneas que contengan un término en archivos o stdin         |
| `wzip`   | Comprime archivos usando codificación por longitud de racha (RLE) |
| `wunzip` | Descomprime archivos generados por `wzip`                         |

---

## 3. Documentación de funciones

### 3.1 `wcat`

#### `FILE *openFile(char *ruta)`

| Campo           | Detalle                                                                                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Abre un archivo en modo lectura de texto (`"r"`). Si el archivo no existe o no puede abrirse, imprime `wcat: cannot open file` y termina el proceso con `exit(1)`. |
| **Parámetros**  | `ruta` — cadena de caracteres con la ruta al archivo.                                                                                                              |
| **Retorna**     | Puntero `FILE *` al archivo abierto exitosamente.                                                                                                                  |

#### `void printFile(FILE *file)`

| Campo           | Detalle                                                                                                                                    |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Lee el archivo línea a línea usando un buffer de 1024 bytes e imprime cada línea en `stdout`. Al terminar, cierra el archivo con `fclose`. |
| **Parámetros**  | `file` — puntero `FILE *` al archivo ya abierto.                                                                                           |
| **Retorna**     | `void`.                                                                                                                                    |

#### `int main(int argc, char *argv[])`

| Campo           | Detalle                                                                                                                                                                                 |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Punto de entrada. Si no se reciben argumentos, termina sin error. De lo contrario, itera sobre cada argumento (nombre de archivo), lo abre con `openFile` y lo imprime con `printFile`. |
| **Parámetros**  | `argc` — cantidad de argumentos; `argv` — arreglo de cadenas con los nombres de archivo.                                                                                                |
| **Retorna**     | `0` al finalizar correctamente.                                                                                                                                                         |

---

### 3.2 `wgrep`

#### `FILE *openFile(char *ruta)`

| Campo           | Detalle                                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Abre un archivo en modo lectura de texto (`"r"`). Si falla, imprime `wgrep: cannot open file` y termina con `exit(1)`. |
| **Parámetros**  | `ruta` — cadena con la ruta al archivo.                                                                                |
| **Retorna**     | Puntero `FILE *` al archivo abierto.                                                                                   |

#### `void find(char *palabra, FILE *file)`

| Campo           | Detalle                                                                                                                                                                                                                                  |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Lee el archivo línea a línea usando `getline` (gestión automática de memoria). Por cada línea, usa `strstr` para verificar si contiene la cadena buscada; en caso afirmativo, imprime la línea completa. Al terminar, cierra el archivo. |
| **Parámetros**  | `palabra` — término de búsqueda; `file` — puntero al archivo (o `stdin`).                                                                                                                                                                |
| **Retorna**     | `void`.                                                                                                                                                                                                                                  |

#### `int main(int argc, char *argv[])`

| Campo           | Detalle                                                                                                                                                                                  |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Valida los argumentos. Sin argumentos: imprime el uso correcto y termina con error. Con solo el término de búsqueda: lee de `stdin`. Con archivos adicionales: abre y busca en cada uno. |
| **Parámetros**  | `argc` — cantidad de argumentos; `argv[1]` — término a buscar; `argv[2..n]` — archivos donde buscar.                                                                                     |
| **Retorna**     | `0` al finalizar correctamente, `1` si faltan argumentos.                                                                                                                                |

---

### 3.3 `wzip`

#### `FILE *openFile(char *ruta)`

| Campo           | Detalle                                                                                                               |
| --------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Abre un archivo en modo lectura binaria (`"rb"`). Si falla, imprime `wzip: cannot open file` y termina con `exit(1)`. |
| **Parámetros**  | `ruta` — cadena con la ruta al archivo.                                                                               |
| **Retorna**     | Puntero `FILE *` al archivo abierto.                                                                                  |

#### `void readCharacter(FILE *file)`

| Campo           | Detalle                                                                                                                                                                                                                                                                                      |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Implementa la compresión RLE (_Run-Length Encoding_). Lee el archivo carácter a carácter con `fgetc`. Lleva la cuenta de caracteres consecutivos iguales; cuando cambia el carácter, escribe en `stdout` binario un par `(count: int, char: char)`. Escribe el último par al llegar a `EOF`. |
| **Parámetros**  | `file` — puntero al archivo a comprimir.                                                                                                                                                                                                                                                     |
| **Retorna**     | `void`.                                                                                                                                                                                                                                                                                      |

#### `int main(int argc, char *argv[])`

| Campo           | Detalle                                                                                                                     |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Valida que se pase al menos un archivo. Itera sobre cada archivo, lo abre, lo comprime escribiendo en `stdout` y lo cierra. |
| **Parámetros**  | `argc` — cantidad de argumentos; `argv` — arreglo con los nombres de archivo.                                               |
| **Retorna**     | `0` al finalizar correctamente, `1` si no se pasan argumentos.                                                              |

---

### 3.4 `wunzip`

#### `FILE *openFile(char *ruta)`

| Campo           | Detalle                                                                                                                 |
| --------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Abre un archivo en modo lectura binaria (`"rb"`). Si falla, imprime `wunzip: cannot open file` y termina con `exit(1)`. |
| **Parámetros**  | `ruta` — cadena con la ruta al archivo.                                                                                 |
| **Retorna**     | Puntero `FILE *` al archivo abierto.                                                                                    |

#### `void decompress(FILE *file)`

| Campo           | Detalle                                                                                                                                                                                                                                                  |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Lee repetidamente pares binarios `(int count, char caracter)` del archivo usando `fread`. Por cada par, imprime el carácter `count` veces en `stdout`. El ciclo termina cuando `fread` no puede leer un par completo (fin de archivo o datos corruptos). |
| **Parámetros**  | `file` — puntero al archivo comprimido (generado por `wzip`).                                                                                                                                                                                            |
| **Retorna**     | `void`.                                                                                                                                                                                                                                                  |

#### `int main(int argc, char *argv[])`

| Campo           | Detalle                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| **Descripción** | Valida que se pase al menos un archivo. Itera sobre cada archivo, lo abre, lo descomprime y lo cierra. |
| **Parámetros**  | `argc` — cantidad de argumentos; `argv` — arreglo con los nombres de archivo comprimidos.              |
| **Retorna**     | `0` al finalizar correctamente, `1` si no se pasan argumentos.                                         |

---

## 4. Problemas presentados durante el desarrollo

### 4.1 Adaptación a la sintaxis de C

- **Ausencia de tipos de datos de alto nivel:** no existe un tipo nativo `string`; las cadenas son arreglos de `char` terminados en `'\0'`, lo que requirió aprender a usar funciones como `strcmp`, `strstr` y `strlen`.
- **Gestión manual de la entrada:** sin estructuras como `input()` de Python, leer líneas requirió entender el funcionamiento de `fgets` y `getline`, incluyendo sus diferencias en cuanto a gestión de memoria.

### 4.2 Diferencias entre tipos de datos

- **`char` vs `int` para caracteres:** `fgetc` retorna `int` (no `char`) para poder representar `EOF` (que vale `-1`). Usar `char` para almacenar el retorno de `fgetc` causó que `EOF` no se detectara correctamente en algunas plataformas.
- **Punteros y arreglos:** entender que `char *ruta` y un arreglo de caracteres son equivalentes en ciertos contextos, pero diferentes en cuanto a memoria asignada, fue un punto de confusión inicial.
- **`size_t`:** el tipo retornado por `sizeof` y requerido por funciones como `getline` es `size_t` (entero sin signo). Usarlo incorrectamente con `int` generó advertencias del compilador.

### 4.3 Manejo de memoria y punteros `FILE`

- **Puntero `NULL` en `fopen`:** inicialmente se asumió que `fopen` siempre tendría éxito. La omisión de la verificación contra `NULL` provocaba fallos de segmentación al intentar leer un archivo inexistente.
- **`fclose` y recursos:** cerrar el archivo en la función `printFile` / `decompress` en lugar de en `main` generó confusión sobre el ciclo de vida del recurso, pero se mantuvo así porque la función es la única responsable de consumir el archivo.
- **Memoria de `getline`:** `getline` gestiona dinámicamente el buffer `line`. Pasarle un puntero no inicializado (sin ponerlo en `NULL`) o no liberar la memoria con `free` son errores comunes que se identificaron durante el desarrollo.
- **E/S binaria con `fread`/`fwrite`:** la diferencia entre modo texto (`"r"`) y modo binario (`"rb"`) fue crítica para `wzip`/`wunzip`; usar modo texto causaba que ciertos bytes (como `0x0A` en Windows) fueran transformados automáticamente, corrompiendo el archivo comprimido.

---

## 5. Pruebas realizadas

### Compilación

```bash
# wcat
gcc -o wcat wcat/wcat.c

# wgrep
gcc -o wgrep wgrep/wgrep.c

# wzip
gcc -o wzip wzip/wzip.c

# wunzip
gcc -o wunzip wunzip/wunzip.c
```

### 5.1 Pruebas de `wcat`

```bash
# Caso normal: mostrar un archivo
./wcat recursos/archivo.txt

# Caso normal: mostrar múltiples archivos concatenados
./wcat recursos/archivo1.txt recursos/archivo2.txt

# Caso de error: archivo inexistente
./wcat no_existe.txt
# Salida esperada: wcat: cannot open file

# Caso borde: sin argumentos (debe terminar sin error ni salida)
./wcat
```

### 5.2 Pruebas de `wgrep`

```bash
# Caso normal: buscar término en un archivo
./wgrep "hola" recursos/archivo.txt

# Caso normal: buscar en múltiples archivos
./wgrep "error" recursos/log1.txt recursos/log2.txt

# Caso normal: lectura desde stdin (pipe)
cat recursos/archivo.txt | ./wgrep "mundo"

# Caso de error: sin argumentos
./wgrep
# Salida esperada: wgrep: searchterm [file ...]

# Caso de error: archivo inexistente
./wgrep "hola" no_existe.txt
# Salida esperada: wgrep: cannot open file

# Caso borde: término que no existe en el archivo (no produce salida)
./wgrep "xyzxyz" recursos/archivo.txt
```

### 5.3 Pruebas de `wzip`

```bash
# Caso normal: comprimir un archivo y guardar el resultado
./wzip recursos/archivo.txt > archivo.z

# Verificar que el archivo comprimido fue creado
ls -lh archivo.z

# Caso normal: comprimir múltiples archivos en un solo flujo
./wzip recursos/archivo1.txt recursos/archivo2.txt > combinado.z

# Caso de error: sin argumentos
./wzip
# Salida esperada: wzip: file1 [file2 ...]

# Caso de error: archivo inexistente
./wzip no_existe.txt > salida.z
# Salida esperada: wzip: cannot open file
```

### 5.4 Pruebas de `wunzip`

```bash
# Caso normal: descomprimir y verificar que el contenido es idéntico al original
./wzip recursos/archivo.txt > archivo.z
./wunzip archivo.z > recuperado.txt
diff recursos/archivo.txt recuperado.txt
# Sin salida = archivos idénticos

# Caso normal: descomprimir múltiples archivos
./wunzip archivo1.z archivo2.z

# Caso de error: sin argumentos
./wunzip
# Salida esperada: wunzip: file1 [file2 ...]

# Caso de error: archivo inexistente
./wunzip no_existe.z
# Salida esperada: wunzip: cannot open file

# Caso borde: archivo vacío
touch vacio.txt
./wzip vacio.txt > vacio.z
./wunzip vacio.z
# Sin salida (comportamiento correcto)
```

---

## 6. Video de sustentación

[Enlace al video](https://youtu.be/JJ1le0em_7Q)

---

## 7. Manifiesto de transparencia

Durante el desarrollo de este laboratorio **se utilizó inteligencia artificial generativa** (específicamente modelos de lenguaje como Claude) **únicamente como herramienta de consulta de documentación**, equivalente al uso de `man pages` o recursos como cppreference.com.

El uso de IA se limitó a:

- Consultar la firma y comportamiento de funciones estándar de C no familiares para el equipo: `fopen`, `fgets`, `fclose`, `fwrite`, `fread`, `getline` y `strstr`.
- Resolver dudas puntuales sobre la diferencia entre modo texto y modo binario en `fopen`.
- Entender el manejo de memoria dinámica de `getline` y cuándo se debe liberar el buffer.

Este apoyo **aceleró el proceso de aprendizaje de la biblioteca estándar de C** sin reemplazar el razonamiento, el diseño de los algoritmos ni la escritura del código, que fueron realizadas de forma manual.
