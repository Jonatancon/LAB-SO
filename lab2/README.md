# Laboratorio 2 — API de Procesos: wish shell

**Curso:** Sistemas Operativos
**Universidad de Antioquia**

---

## 1. Integrantes

| Nombre completo              | Correo institucional           |
| ---------------------------- | ------------------------------ |
| Jonatan Stiven Restrepo Lora | jhonatan.restrepol@udea.edu.co |

---

## 2. Descripción general

Este laboratorio implementa `wish` (Wisconsin Shell), un intérprete de comandos escrito en C. El shell soporta dos modos de ejecución, tres comandos integrados, redirección de salida y ejecución de comandos en paralelo.

| Característica        | Descripción                                                                 |
| --------------------- | --------------------------------------------------------------------------- |
| Modo interactivo      | Muestra el prompt `wish>` y espera comandos del usuario                     |
| Modo batch            | Lee y ejecuta comandos desde un archivo sin mostrar el prompt               |
| Comandos externos     | Busca y ejecuta ejecutables usando `fork()` + `execv()`                     |
| Built-in `exit`       | Termina el shell con `exit(0)`                                              |
| Built-in `cd`         | Cambia el directorio de trabajo con `chdir()`                               |
| Built-in `path`       | Actualiza el search path del shell                                          |
| Redirección `>`       | Redirige stdout y stderr al archivo especificado                            |
| Comandos paralelos `&`| Ejecuta múltiples comandos simultáneamente con `fork()` + `waitpid()`      |

---

## 3. Documentación de funciones

### 3.1 `print_error`

| Campo           | Detalle                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Escribe el mensaje de error estándar `"An error has occurred\n"` a `stderr` usando la llamada al sistema `write`. |
| **Parámetros**  | Ninguno.                                                                                                     |
| **Retorna**     | `void`.                                                                                                      |

---

### 3.2 `init_path`

| Campo           | Detalle                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Inicializa el search path con el valor por defecto `/bin`. Reserva memoria dinámica para el arreglo de directorios y copia el string. |
| **Parámetros**  | Ninguno.                                                                                                                             |
| **Retorna**     | `void`.                                                                                                                              |

---

### 3.3 `free_path`

| Campo           | Detalle                                                                                                                                                           |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Libera toda la memoria del search path actual. Primero libera cada string individual y luego el arreglo de punteros. Deja `search_path = NULL` y `path_count = 0`. |
| **Parámetros**  | Ninguno.                                                                                                                                                          |
| **Retorna**     | `void`.                                                                                                                                                           |

---

### 3.4 `builtin_exit`

| Campo           | Detalle                                                                                                         |
| --------------- | --------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Implementa el comando integrado `exit`. Si `argc != 1` imprime error y retorna sin terminar. Si `argc == 1` llama `exit(0)`. |
| **Parámetros**  | `args` — arreglo de argumentos (no usado); `argc` — cantidad de tokens incluyendo el comando.                   |
| **Retorna**     | `void`.                                                                                                         |

---

### 3.5 `builtin_cd`

| Campo           | Detalle                                                                                                                                        |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Implementa el comando integrado `cd`. Requiere exactamente un argumento. Usa `chdir()` para cambiar el directorio; si falla, imprime el error. |
| **Parámetros**  | `args` — arreglo de argumentos donde `args[1]` es el directorio destino; `argc` — cantidad de tokens.                                         |
| **Retorna**     | `void`.                                                                                                                                        |

---

### 3.6 `builtin_path`

| Campo           | Detalle                                                                                                                                                                                        |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Implementa el comando integrado `path`. Llama `free_path()` para descartar el path anterior y construye uno nuevo con los directorios recibidos como argumentos. Sin argumentos deja el path vacío. |
| **Parámetros**  | `args` — arreglo donde `args[1..n]` son los nuevos directorios; `argc` — cantidad de tokens.                                                                                                   |
| **Retorna**     | `void`.                                                                                                                                                                                        |

---

### 3.7 `find_executable`

| Campo           | Detalle                                                                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Recorre cada directorio del search path, construye la ruta completa con `snprintf` y verifica si el ejecutable existe y es ejecutable con `access(path, X_OK)`. Retorna la primera coincidencia. |
| **Parámetros**  | `cmd` — nombre del comando a buscar.                                                                                                                                                 |
| **Retorna**     | String con la ruta completa (heap-allocated, el llamador debe liberar) o `NULL` si no se encuentra.                                                                                 |

---

### 3.8 `execute_command`

| Campo           | Detalle                                                                                                                                                                                                                                      |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Busca el ejecutable con `find_executable`, hace `fork()` y en el proceso hijo maneja la redirección con `dup2()` si corresponde, luego ejecuta el programa con `execv()`. El proceso padre libera la memoria y retorna el PID del hijo. |
| **Parámetros**  | `args` — arreglo de argumentos del comando; `argc` — cantidad de argumentos; `redirect_file` — nombre del archivo de redirección o `NULL`.                                                                                                  |
| **Retorna**     | `pid_t` del proceso hijo creado, o `-1` si hubo error (ejecutable no encontrado o `fork` falló).                                                                                                                                            |

---

### 3.9 `parse_single_command`

| Campo           | Detalle                                                                                                                                                                                                                         |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Tokeniza un comando usando `strsep` separando por espacios y tabulaciones. Detecta el operador `>` y clasifica cada token como argumento o archivo de redirección. Valida errores de sintaxis y despacha al built-in o externo correspondiente. |
| **Parámetros**  | `cmd_str` — string con el comando completo (sin `&`).                                                                                                                                                                          |
| **Retorna**     | `pid_t` del proceso hijo si fue un externo, `-1` si fue un built-in o hubo error.                                                                                                                                              |

---

### 3.10 `process_line`

| Campo           | Detalle                                                                                                                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción** | Elimina el salto de línea final, divide la línea por `&` para obtener segmentos paralelos, lanza cada uno con `parse_single_command` y recolecta los PIDs retornados. Al final hace `waitpid` sobre cada PID real para esperar a todos los hijos. |
| **Parámetros**  | `line` — string con la línea completa leída del input.                                                                                                                                                                              |
| **Retorna**     | `void`.                                                                                                                                                                                                                             |

---

### 3.11 `main`

| Campo           | Detalle                                                                                                                                                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción** | Punto de entrada. Inicializa el path, determina el modo (interactivo o batch) según los argumentos recibidos, y entra en el loop principal: muestra el prompt si es interactivo, lee una línea con `getline` y la procesa. Termina en EOF. |
| **Parámetros**  | `argc` — cantidad de argumentos del programa; `argv` — arreglo de argumentos.                                                                                                                                             |
| **Retorna**     | No retorna en condiciones normales; termina con `exit(0)`.                                                                                                                                                                |

---

## 4. Problemas presentados durante el desarrollo

### 4.1 Nombres incorrectos de los built-ins

Al diseñar los built-ins se usaron los nombres `chd` y `route` en lugar de `cd` y `path` que exige el spec. Esto se detectó al comparar el código contra el enunciado y se corrigió renombrando todas las ocurrencias en el código.

### 4.2 Bug en el conteo de procesos hijos para `wait`

La primera versión contaba cuántos comandos externos se lanzaban e intentaba hacer `wait(NULL)` esa cantidad de veces. El problema es que si `find_executable` fallaba, no se creaba ningún proceso hijo pero el contador ya había aumentado, quedando el shell bloqueado esperando un proceso que nunca existió. La solución fue cambiar `execute_command` para que retorne el `pid_t` real del hijo, y usar `waitpid(pid)` sobre cada PID concreto recolectado.

### 4.3 Redirección con y sin espacios alrededor del `>`

El parser necesitaba manejar tanto `ls > out.txt` (con espacios) como `ls>out.txt` (sin espacios). Se resolvió buscando el carácter `>` dentro de cada token con `strchr` y dividiendo el token en dos partes si era necesario.

### 4.4 Copia del segmento antes de parsear

`strsep` modifica el string original al reemplazar los delimitadores con `'\0'`. Al dividir por `&` y luego volver a tokenizar cada segmento con `strsep`, el string original quedaba corrupto. Se solucionó haciendo una copia local con `strncpy` antes de llamar a `parse_single_command`.

---

## 5. Pruebas realizadas

### Compilación

```bash
gcc -Wall -Werror -o wish wish.c
```

### 5.1 Modos de ejecución

```bash
# Modo interactivo
./wish
wish> echo hola
wish> exit

# Modo batch
./wish batch.txt

# Error: más de un argumento
./wish archivo1 archivo2
```

### 5.2 Built-in exit

```bash
./wish
wish> exit argumento    # error, shell continúa
wish> echo sigo aquí
wish> exit              # termina correctamente
```

### 5.3 Built-in cd

```bash
./wish
wish> pwd
wish> cd /tmp
wish> pwd               # debe mostrar /tmp
wish> cd                # error: sin argumentos
wish> cd /tmp /home     # error: demasiados argumentos
wish> cd /no/existe     # error: directorio inexistente
```

### 5.4 Built-in path

```bash
./wish
wish> path /bin /usr/bin    # agrega dos directorios
wish> wc --version          # funciona desde /usr/bin
wish> path                  # path vacío
wish> ls                    # error: no se encuentra
wish> path /bin             # restaurar
wish> ls                    # vuelve a funcionar
```

### 5.5 Redirección

```bash
./wish
wish> ls -la /tmp > /tmp/salida.txt
# verificar:
cat /tmp/salida.txt

# stderr también redirigido
wish> ls /no/existe > /tmp/error.txt
cat /tmp/error.txt

# errores de sintaxis
wish> ls >
wish> ls > archivo1 archivo2
wish> ls > a > b
```

### 5.6 Comandos paralelos

```bash
./wish
wish> echo uno & echo dos & echo tres

# verificar que corren en paralelo (~3 seg, no ~9)
time echo "sleep 3 & sleep 3 & sleep 3" | ./wish
```

### 5.7 Script de pruebas automatizado

```bash
bash test.sh
# Resultado: 26 pruebas, 0 fallos
```

---

## 6. Video de sustentación

[Ver video en YouTube](https://youtu.be/rdyddccUbWE)

---

## 7. Manifiesto de transparencia

Durante el desarrollo de este laboratorio **se utilizó inteligencia artificial generativa** (específicamente Claude) en dos aspectos puntuales:

- **Consulta de funcionalidades:** se usó como referencia para entender el comportamiento de llamadas al sistema no familiares como `dup2`, `execv`, `waitpid`, `access` y `strsep`, equivalente a consultar las man pages.
- **Diseño del script de pruebas:** se utilizó para estructurar los casos de prueba del archivo `test.sh`, cubriendo los escenarios descritos en el enunciado.

