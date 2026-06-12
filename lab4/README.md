# Práctica No. 4 — API de Hilos (Pthreads)

Laboratorio de Sistemas Operativos · Facultad de Ingeniería · Ingeniería de Sistemas · Universidad de Antioquia

Implementación de paralelización con POSIX Threads sobre dos problemas: cálculo de π por integración numérica y generación de la secuencia de Fibonacci, junto con el análisis de rendimiento (Speedup y Eficiencia).

---

## a. Integrantes

| Nombre completo                | Correo                           |
| ------------------------------ | -------------------------------- |
| [Jonatan Stiven Restrepo Lora] | [jhonatan.restrepol@udea.edu.co] |

---

## Compilación y ejecución

```bash
# Serial
gcc -O2 -o pi_s src/pi.c -lm
./pi_s 2000000000

# Paralelo (segundo argumento = número de hilos)
gcc -O2 -o pi_p src/pi_p.c -lpthread -lm
./pi_p 2000000000 4

# Fibonacci (argumento = N elementos)
gcc -O2 -o fibonacci src/fibonacci.c -lpthread
./fibonacci 10
```

El notebook `analisis.ipynb` automatiza la compilación, la captura de las características del sistema, la medición de tiempos (3 repeticiones promediadas) y la generación de tablas y gráficas. Requiere Linux con `gcc`, ejecutado en la misma carpeta que los fuentes.

---

## b. Documentación de funciones

### `pi.c` (serial)

- **`f(double x)`** — Integrando `4 / (1 + x²)`, cuya integral definida de 0 a 1 es π. Declarada `static inline`.
- **`CalcPi(int n)`** — Aproxima π por la regla del punto medio: divide [0,1] en `n` rectángulos, evalúa `f` en el centro de cada uno (`(i + 0.5)·fH`), acumula las áreas y multiplica la suma por el ancho `fH = 1/n`. Núcleo computacional de la aplicación.
- **`GetTime(void)`** — Devuelve el tiempo actual en segundos (resolución de microsegundos vía `gettimeofday`). Usada para instrumentar exclusivamente la llamada a `CalcPi`.
- **`main(int argc, char *argv[])`** — Valida que se reciba `n` por línea de comandos, valida su rango, cronometra `CalcPi` e imprime el valor de π y el tiempo medido.

### `pi_p.c` (paralelo)

- **`f(double x)`** — Idéntica al integrando de la versión serial.
- **`GetTime(void)`** — Idéntica a la versión serial.
- **`struct ThreadArg`** — Argumentos por hilo: sub-rango asignado `[start, end)` y el ancho compartido `fH`.
- **`worker(void *arg)`** — Función de hilo. Calcula la suma parcial de `f(fX)` sobre su sub-rango en una variable **local**, reserva un `double` con `malloc` y retorna su dirección vía `pthread_exit`/`return`. No escribe en memoria compartida, por lo que **no requiere mutex** (cero contención).
- **`CalcPiParallel(long n, int T)`** — Orquesta la paralelización: particiona las `n` iteraciones en bloques entre los `T` hilos (repartiendo el residuo `n % T` entre los primeros hilos para balancear la carga ±1 iteración), crea los hilos con `pthread_create`, los sincroniza con `pthread_join`, agrega las sumas parciales y multiplica el total por `fH` una sola vez al final.
- **`main(int argc, char *argv[])`** — Valida `n` y el número de hilos `T` recibidos por línea de comandos, cronometra `CalcPiParallel` e imprime π, el número de hilos y el tiempo medido.

### `fibonacci.c`

- **`struct FibArg`** — Empaqueta el puntero al arreglo compartido (`seq`) y su tamaño (`n`) para pasarlos al hilo trabajador.
- **`worker(void *arg)`** — Función de hilo. Llena el arreglo compartido con la secuencia de Fibonacci (`seq[0]=seq[1]=1`, `seq[i]=seq[i-1]+seq[i-2]`). Único escritor del arreglo.
- **`main(int argc, char *argv[])`** — Valida `N`, reserva el arreglo compartido con `malloc`, lanza un único hilo trabajador pasándole la dirección del `struct FibArg`, se bloquea con `pthread_join` hasta que el trabajador termine y luego imprime la secuencia. El `join` garantiza que `main` no lea posiciones aún no escritas.

---

## c. Problemas presentados y soluciones

| Problema                                                                                                | Solución                                                                                                                                                                    |
| ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| El parámetro `n = 2×10⁹` está cerca del límite de `int` (INT_MAX = 2 147 483 647).                      | En `pi.c` se parsea con `strtol` y se valida el rango antes de castear; en `pi_p.c` se usa `long` para `n` e índices, eliminando cualquier riesgo de overflow del contador. |
| Riesgo de contención si los hilos actualizan una suma global compartida con mutex.                      | Cada hilo acumula en una variable **local** y retorna su suma parcial vía `pthread_join`; `main` las agrega. Diseño sin sección crítica → sin mutex → sin contención.       |
| Reparto desigual de iteraciones cuando `n` no es múltiplo del número de hilos.                          | Partición por bloques con reparto del residuo (`n % T`) entre los primeros hilos, de modo que ninguno difiere en más de una iteración.                                      |
| En Fibonacci, `main` podía leer el arreglo antes de que el trabajador terminara (condición de carrera). | `pthread_join` actúa como barrera _happens-before_: `main` solo imprime después de que el hilo retorna.                                                                     |
| Para N grande (>100k) los valores de Fibonacci desbordan cualquier entero.                              | En la prueba sin hilos para medición de tiempo se usa `unsigned long long` con wraparound; el objetivo allí es medir el tiempo del bucle, no los valores exactos.           |

---

## d. Pruebas realizadas

- **Verificación de π:** ambas versiones convergen a `3.14159265358...` con `n` grande; la versión paralela produce el mismo valor que la serial independientemente del número de hilos, confirmando que la partición y agregación son correctas.
- **Verificación de Fibonacci:** `./fibonacci 10` imprime `1 1 2 3 5 8 13 21 34 55`; `./fibonacci 15` extiende correctamente la secuencia hasta `610`.
- **Consistencia Tp(1) ≈ Ts:** la versión paralela con un hilo rinde dentro del 1.11% de la serial, validando que el overhead de threading es mínimo.
- **Mediciones de rendimiento:** ejecutadas con `n = 2×10⁹`, 3 repeticiones promediadas por configuración, para N = 1, 2, 4, 8, 16 hilos. Resultados consolidados en `analisis.ipynb`.

### Resultados de rendimiento (resumen)

Sistema de prueba: Intel Core i3-10105 (4 núcleos físicos, 8 lógicos), 15.5 GB RAM, Linux 6.17, gcc 13.3.0.

| N (Hilos) | Tp (s) | Speedup (Ts/Tp) | Eficiencia (S/N) |
| --------- | ------ | --------------- | ---------------- |
| 1         | 2.2191 | 0.989           | 0.989            |
| 2         | 1.0948 | 2.005           | 1.002            |
| 4         | 0.5637 | 3.893           | 0.973            |
| 8         | 0.6002 | 3.657           | 0.457            |
| 16        | 0.5616 | 3.908           | 0.244            |

Ts (serial) = 2.1947 s. Análisis detallado en el notebook.

---

## e. Video de sustentación

---

## f. Manifiesto de transparencia (uso de IA generativa)

Se utilizó IA generativa (Claude) en los siguientes puntos:

- **Generación del reporte/informe:** redacción y estructuración de este `README.md` y del análisis de resultados del notebook.
- Apoyo en la redacción de comentarios del código y en la interpretación de las métricas de Speedup y Eficiencia.

---

## g. Conclusiones

1. El cálculo de π por integración numérica es _embarrassingly parallel_: la partición por bloques con suma parcial local y retorno vía `pthread_join` evita por completo el uso de mutex y la contención asociada.

2. El Speedup crece de forma casi lineal hasta los 4 núcleos físicos (2 hilos → 2.005×, 4 hilos → 3.893×) y luego se satura en ~3.9×, confirmando que el techo de escalabilidad lo impone el número de núcleos físicos, no la cantidad de hilos lanzados.

3. El Hyper-Threading no aporta en esta carga: pasar de 4 a 8 hilos no mejora (incluso empeora a 3.657×), porque el cálculo es compute-bound y satura las unidades de ejecución de cada core; el SMT solo ayuda cuando hay latencias de memoria que ocultar.

4. La eficiencia decae monótonamente (0.989 → 0.244) al superar los núcleos físicos: el speedup queda fijo en ~3.9 y se divide entre un N creciente. La pérdida es estructural (límite de hardware), no por sincronización, consistente con la Ley de Amdahl.

5. Tp(1) ≈ Ts (overhead +1.11%) valida que la infraestructura de hilos introduce un costo fijo mínimo. El punto óptimo de operación es 4 hilos: 3.893× de speedup con 97.3% de eficiencia.

6. En Fibonacci no hay paralelismo real porque la recurrencia `F(i)=F(i-1)+F(i-2)` es inherentemente secuencial; `pthread_join` es suficiente como mecanismo de sincronización productor-consumidor con un único escritor, garantizando que `main` no acceda a datos antes de que sean generados.

---

## h. Notebook de análisis

Ver [`analisis.ipynb`](analisis.ipynb) — incluye captura del sistema, mediciones automatizadas, tabla de métricas, gráficos de Speedup y Eficiencia, y el análisis completo de ambas secciones.
