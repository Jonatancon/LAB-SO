#!/bin/bash

# =====================================================================
# Script de pruebas automaticas - Lab 1 Sistemas Operativos
# Universidad de Antioquia
# =====================================================================

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
title() { echo -e "\n${YELLOW}==============================${NC}"; echo -e "${YELLOW} $1${NC}"; echo -e "${YELLOW}==============================${NC}"; }

# =====================================================================
# RUTAS
# =====================================================================
WCAT=./wcat/wcat
WGREP=./wgrep/wgrep
WZIP=./wzip/wzip
WUNZIP=./wunzip/wunzip
REC=./recursos

DOC1=$REC/documento1.txt
DOC2=$REC/documento2.txt
DOC3=$REC/documento3.txt
DOC4=$REC/documento4.txt
WGREP1=$REC/wgrep1.txt
WZIPTXT=$REC/wzip.txt
COMPRIMIDO=/tmp/comprimido.z

# =====================================================================
# COMPILACION
# =====================================================================
title "COMPILANDO PROGRAMAS"

compile() {
  gcc -o $1 $2 2>/dev/null
  if [ $? -eq 0 ]; then pass "Compilacion $3"; else fail "Compilacion $3"; fi
}

compile $WCAT    ./wcat/wcat.c       "wcat"
compile $WGREP   ./wgrep/wgrep.c     "wgrep"
compile $WZIP    ./wzip/wzip.c       "wzip"
compile $WUNZIP  ./wunzip/wunzip.c   "wunzip"

# =====================================================================
# PRUEBAS WCAT
# =====================================================================
title "PRUEBAS WCAT"

# 1. Sin argumentos debe salir con codigo 0
$WCAT > /dev/null 2>&1
[ $? -eq 0 ] && pass "Sin argumentos sale con exit 0" || fail "Sin argumentos debe salir con exit 0"

# 2. Leer un archivo existente
OUTPUT=$($WCAT $DOC1 2>&1)
echo "$OUTPUT" | grep -q "La terminal es tu mejor amiga" \
  && pass "Lee un archivo correctamente" \
  || fail "No lee el archivo correctamente"

# 3. Leer multiples archivos
OUTPUT=$($WCAT $DOC1 $DOC2 2>&1)
echo "$OUTPUT" | grep -q "La terminal es tu mejor amiga" \
  && echo "$OUTPUT" | grep -q "El bosque de los bugs" \
  && pass "Lee multiples archivos correctamente" \
  || fail "No lee multiples archivos correctamente"

# 4. Archivo no existente mensaje exacto
OUTPUT=$($WCAT archivo_falso.txt 2>&1)
[ "$OUTPUT" = "wcat: cannot open file" ] \
  && pass "Mensaje exacto archivo no encontrado" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 5. Archivo no existente sale con exit 1
$WCAT archivo_falso.txt > /dev/null 2>&1
[ $? -eq 1 ] && pass "Archivo no encontrado sale con exit 1" || fail "Archivo no encontrado debe salir con exit 1"

# 6. Error en medio de lista detiene ejecucion
OUTPUT=$($WCAT $DOC1 archivo_falso.txt $DOC2 2>&1)
echo "$OUTPUT" | grep -q "wcat: cannot open file" \
  && ! echo "$OUTPUT" | grep -q "El bosque de los bugs" \
  && pass "Error en medio de lista detiene ejecucion" \
  || fail "Error en medio de lista no detiene ejecucion"

# 7. Lee los 4 documentos
OUTPUT=$($WCAT $DOC1 $DOC2 $DOC3 $DOC4 2>&1)
echo "$OUTPUT" | grep -q "punteros" \
  && echo "$OUTPUT" | grep -q "bosque" \
  && pass "Lee los 4 documentos correctamente" \
  || fail "No lee los 4 documentos correctamente"

# =====================================================================
# PRUEBAS WGREP
# =====================================================================
title "PRUEBAS WGREP"

# 1. Sin argumentos mensaje exacto
OUTPUT=$($WGREP 2>&1)
[ "$OUTPUT" = "wgrep: searchterm [file ...]" ] \
  && pass "Sin argumentos mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 2. Sin argumentos sale con exit 1
$WGREP > /dev/null 2>&1
[ $? -eq 1 ] && pass "Sin argumentos sale con exit 1" || fail "Sin argumentos debe salir con exit 1"

# 3. Buscar termino existente en archivo
OUTPUT=$($WGREP foo $WGREP1 2>&1)
echo "$OUTPUT" | grep -q "foo" \
  && pass "Encuentra termino en archivo" \
  || fail "No encuentra termino en archivo"

# 4. Solo imprime lineas que contienen el termino
OUTPUT=$($WGREP foo $WGREP1 2>&1)
! echo "$OUTPUT" | grep -q "esta linea no tiene nada" \
  && pass "No imprime lineas sin el termino" \
  || fail "Imprime lineas que no contienen el termino"

# 5. Case sensitive foo vs Foo
OUTPUT=$($WGREP Foo $WGREP1 2>&1)
[ -z "$OUTPUT" ] \
  && pass "Busqueda case sensitive funciona" \
  || fail "Busqueda no es case sensitive"

# 6. Archivo no encontrado mensaje exacto
OUTPUT=$($WGREP foo archivo_falso.txt 2>&1)
[ "$OUTPUT" = "wgrep: cannot open file" ] \
  && pass "Archivo no encontrado mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 7. Archivo no encontrado sale con exit 1
$WGREP foo archivo_falso.txt > /dev/null 2>&1
[ $? -eq 1 ] && pass "Archivo no encontrado sale con exit 1" || fail "Archivo no encontrado debe salir con exit 1"

# 8. Buscar en multiples archivos
OUTPUT=$($WGREP punteros $DOC1 $DOC2 $DOC3 2>&1)
echo "$OUTPUT" | grep -q "punteros" \
  && pass "Busca en multiples archivos" \
  || fail "No busca en multiples archivos"

# 9. Termino no encontrado no imprime nada y sale con exit 0
OUTPUT=$($WGREP zzzzzzzzz $WGREP1 2>&1)
[ -z "$OUTPUT" ] \
  && pass "Termino no encontrado no imprime nada" \
  || fail "Termino no encontrado no debe imprimir nada"

$WGREP zzzzzzzzz $WGREP1 > /dev/null 2>&1
[ $? -eq 0 ] && pass "Termino no encontrado sale con exit 0" || fail "Termino no encontrado debe salir con exit 0"

# =====================================================================
# PRUEBAS WZIP
# =====================================================================
title "PRUEBAS WZIP"

# 1. Sin argumentos mensaje exacto
OUTPUT=$($WZIP 2>&1)
[ "$OUTPUT" = "wzip: file1 [file2 ...]" ] \
  && pass "Sin argumentos mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 2. Sin argumentos sale con exit 1
$WZIP > /dev/null 2>&1
[ $? -eq 1 ] && pass "Sin argumentos sale con exit 1" || fail "Sin argumentos debe salir con exit 1"

# 3. Comprime un archivo y genera salida
$WZIP $WZIPTXT > $COMPRIMIDO 2>&1
[ -s $COMPRIMIDO ] \
  && pass "Genera archivo comprimido con contenido" \
  || fail "No genera archivo comprimido"

# 4. Archivo comprimido es mas pequeno que el original
ORIGINAL_SIZE=$(wc -c < $WZIPTXT)
COMPRESSED_SIZE=$(wc -c < $COMPRIMIDO)
[ $COMPRESSED_SIZE -lt $ORIGINAL_SIZE ] \
  && pass "Archivo comprimido es mas pequeno que el original" \
  || fail "Archivo comprimido deberia ser mas pequeno"

# 5. Formato exacto multiplos de 5 bytes
COMPRESSED_SIZE=$(wc -c < $COMPRIMIDO)
[ $((COMPRESSED_SIZE % 5)) -eq 0 ] \
  && pass "Formato exacto bloques de 5 bytes" \
  || fail "El archivo comprimido no tiene bloques de 5 bytes"

# 6. Archivo no encontrado mensaje exacto
OUTPUT=$($WZIP archivo_falso.txt 2>&1)
[ "$OUTPUT" = "wzip: cannot open file" ] \
  && pass "Archivo no encontrado mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 7. Archivo no encontrado sale con exit 1
$WZIP archivo_falso.txt > /dev/null 2>&1
[ $? -eq 1 ] && pass "Archivo no encontrado sale con exit 1" || fail "Archivo no encontrado debe salir con exit 1"

# =====================================================================
# PRUEBAS WUNZIP
# =====================================================================
title "PRUEBAS WUNZIP"

# 1. Sin argumentos mensaje exacto
OUTPUT=$($WUNZIP 2>&1)
[ "$OUTPUT" = "wunzip: file1 [file2 ...]" ] \
  && pass "Sin argumentos mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 2. Sin argumentos sale con exit 1
$WUNZIP > /dev/null 2>&1
[ $? -eq 1 ] && pass "Sin argumentos sale con exit 1" || fail "Sin argumentos debe salir con exit 1"

# 3. Descomprime correctamente
OUTPUT=$($WUNZIP $COMPRIMIDO 2>&1)
ORIGINAL=$(cat $WZIPTXT)
[ "$OUTPUT" = "$ORIGINAL" ] \
  && pass "Descomprime y restaura el contenido original" \
  || fail "El contenido descomprimido no coincide con el original"

# 4. Archivo no encontrado mensaje exacto
OUTPUT=$($WUNZIP archivo_falso.z 2>&1)
[ "$OUTPUT" = "wunzip: cannot open file" ] \
  && pass "Archivo no encontrado mensaje exacto" \
  || fail "Mensaje incorrecto: se obtuvo '$OUTPUT'"

# 5. Archivo no encontrado sale con exit 1
$WUNZIP archivo_falso.z > /dev/null 2>&1
[ $? -eq 1 ] && pass "Archivo no encontrado sale con exit 1" || fail "Archivo no encontrado debe salir con exit 1"

# 6. Comprimir y descomprimir multiples archivos produce salida continua
$WZIP $DOC1 $DOC2 > /tmp/multi.z 2>&1
OUTPUT=$($WUNZIP /tmp/multi.z 2>&1)
echo "$OUTPUT" | grep -q "La terminal es tu mejor amiga" \
  && echo "$OUTPUT" | grep -q "El bosque de los bugs" \
  && pass "Multiples archivos se comprimen y descomprimen como salida continua" \
  || fail "Multiples archivos no se manejan correctamente"

# =====================================================================
# RESUMEN
# =====================================================================
title "RESUMEN"
echo -e "Pruebas pasadas: ${GREEN}$PASS${NC}"
echo -e "Pruebas fallidas: ${RED}$FAIL${NC}"
echo -e "Total: $((PASS + FAIL))\n"

[ $FAIL -eq 0 ] \
  && echo -e "${GREEN}Todos los criterios de aceptacion fueron cumplidos${NC}" \
  || echo -e "${RED}Algunos criterios de aceptacion fallaron, revisa los FAIL${NC}"
