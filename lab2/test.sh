#!/bin/bash

# Script de pruebas para wish - Wisconsin Shell
# Compila wish y verifica cada funcionalidad del spec

WISH="./wish"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
section() { echo -e "\n${YELLOW}=== $1 ===${NC}"; }

# --------------------------------------------------------------------------
# Compilar
# --------------------------------------------------------------------------
section "Compilación"
gcc -Wall -Werror -o wish wish.c 2>/dev/null
if [ $? -eq 0 ]; then
    pass "Compilación exitosa"
else
    echo -e "${RED}ERROR: No compiló. Abortando pruebas.${NC}"
    exit 1
fi

# --------------------------------------------------------------------------
# Helper: ejecutar wish en modo batch con stdin
# --------------------------------------------------------------------------
run_wish() {
    echo "$1" | $WISH 2>/tmp/wish_stderr
}

run_wish_batch() {
    local tmpfile=$(mktemp /tmp/wish_batch_XXXX.txt)
    echo "$1" > "$tmpfile"
    $WISH "$tmpfile" 2>/tmp/wish_stderr
    local ret=$?
    rm -f "$tmpfile"
    return $ret
}

# --------------------------------------------------------------------------
# 1. Modo interactivo básico - el proceso debe correr sin crashear
# --------------------------------------------------------------------------
section "1. Ejecución básica"

output=$(echo "exit" | $WISH 2>/dev/null)
if [ $? -eq 0 ]; then
    pass "Shell inicia y termina con exit"
else
    fail "Shell no termina correctamente con exit"
fi

# Más de un argumento → error + exit(1)
$WISH arg1 arg2 2>/dev/null
if [ $? -eq 1 ]; then
    pass "Más de un argumento produce error y exit(1)"
else
    fail "Más de un argumento no produce exit(1)"
fi

# --------------------------------------------------------------------------
# 2. Comandos externos
# --------------------------------------------------------------------------
section "2. Comandos externos"

output=$(run_wish "ls /bin/ls")
if echo "$output" | grep -q "/bin/ls"; then
    pass "ls /bin/ls ejecuta correctamente"
else
    fail "ls /bin/ls no produjo salida esperada (got: '$output')"
fi

output=$(run_wish_batch "echo hola mundo")
if [ "$output" = "hola mundo" ]; then
    pass "echo con argumentos"
else
    fail "echo falló (got: '$output')"
fi

# Comando que no existe
run_wish "comandoquenoexiste" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "Comando inexistente produce error correcto"
else
    fail "Comando inexistente no produjo el mensaje de error esperado"
fi

# --------------------------------------------------------------------------
# 3. Built-in: exit
# --------------------------------------------------------------------------
section "3. Built-in: exit"

echo "exit" | $WISH 2>/dev/null
if [ $? -eq 0 ]; then
    pass "exit sin argumentos termina con código 0"
else
    fail "exit no terminó con código 0"
fi

# exit con argumento → error, shell sigue corriendo
output=$(printf "exit argumento\necho seguimos\nexit" | $WISH 2>/tmp/wish_stderr)
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred" && echo "$output" | grep -q "seguimos"; then
    pass "exit con argumento produce error pero shell continúa"
else
    fail "exit con argumento no se manejó correctamente"
fi

# --------------------------------------------------------------------------
# 4. Built-in: cd
# --------------------------------------------------------------------------
section "4. Built-in: cd"

output=$(printf "cd /tmp\npwd" | $WISH 2>/dev/null)
if echo "$output" | grep -q "/tmp"; then
    pass "cd /tmp cambia el directorio"
else
    fail "cd /tmp no cambió el directorio (got: '$output')"
fi

# cd sin argumentos → error
run_wish "cd" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "cd sin argumentos produce error"
else
    fail "cd sin argumentos no produjo error"
fi

# cd con dos argumentos → error
run_wish "cd /tmp /home" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "cd con dos argumentos produce error"
else
    fail "cd con dos argumentos no produjo error"
fi

# cd a directorio inexistente → error
run_wish "cd /directorio/que/no/existe" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "cd a directorio inexistente produce error"
else
    fail "cd a directorio inexistente no produjo error"
fi

# --------------------------------------------------------------------------
# 5. Built-in: path
# --------------------------------------------------------------------------
section "5. Built-in: path"

# path vacío → no se pueden ejecutar externos
output=$(printf "path\nls" | $WISH 2>/tmp/wish_stderr)
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "path vacío impide ejecución de comandos externos"
else
    fail "path vacío no impidió ejecutar ls"
fi

# path /bin /usr/bin → ambos directorios disponibles
output=$(printf "path /bin /usr/bin\nwc --version" | $WISH 2>/dev/null)
if echo "$output" | grep -qi "wc\|word"; then
    pass "path con múltiples directorios permite ejecutar wc"
else
    fail "path /bin /usr/bin no permitió ejecutar wc"
fi

# path sobrescribe el anterior: setear path a /tmp (sin ejecutables) → ls falla
output=$(run_wish_batch "$(printf 'path /bin\npath /tmp\nls')")
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "path sobrescribe el anterior (ls no accesible desde /tmp)"
else
    fail "path no sobrescribió correctamente"
fi

# --------------------------------------------------------------------------
# 6. Redirección de salida
# --------------------------------------------------------------------------
section "6. Redirección de salida"

REDIR_FILE="/tmp/wish_redir_test.txt"
rm -f "$REDIR_FILE"

run_wish "ls /bin/ls > $REDIR_FILE"
if [ -f "$REDIR_FILE" ] && grep -q "/bin/ls" "$REDIR_FILE"; then
    pass "Redirección > crea archivo con stdout"
else
    fail "Redirección > falló"
fi

# stderr también va al archivo
rm -f "$REDIR_FILE"
run_wish "ls /ruta/inexistente > $REDIR_FILE" 2>/dev/null
if [ -f "$REDIR_FILE" ] && [ -s "$REDIR_FILE" ]; then
    pass "Redirección > también captura stderr"
else
    fail "Redirección > no capturó stderr"
fi

# Trunca el archivo si ya existe
echo "contenido anterior" > "$REDIR_FILE"
run_wish "echo nuevo > $REDIR_FILE"
content=$(cat "$REDIR_FILE")
if [ "$content" = "nuevo" ]; then
    pass "Redirección trunca archivo existente"
else
    fail "Redirección no truncó archivo (got: '$content')"
fi

# Sin nombre de archivo tras > → error
run_wish "ls >" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "> sin nombre de archivo produce error"
else
    fail "> sin nombre de archivo no produjo error"
fi

# Múltiples > → error
run_wish "ls > /tmp/a > /tmp/b" 2>/tmp/wish_stderr
stderr=$(cat /tmp/wish_stderr)
if echo "$stderr" | grep -q "An error has occurred"; then
    pass "Múltiples > producen error"
else
    fail "Múltiples > no produjeron error"
fi

rm -f "$REDIR_FILE" /tmp/a /tmp/b

# --------------------------------------------------------------------------
# 7. Comandos paralelos con &
# --------------------------------------------------------------------------
section "7. Comandos paralelos (&)"

start=$(date +%s%N)
output=$(run_wish "sleep 1 & sleep 1 & sleep 1")
end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))

if [ "$elapsed" -lt 2500 ]; then
    pass "Tres sleep 1 en paralelo terminan en < 2.5s (tardaron ${elapsed}ms)"
else
    fail "Los sleep paralelos tardaron demasiado (${elapsed}ms), posiblemente secuenciales"
fi

# Mezcla de comandos paralelos (batch para evitar prompt en salida)
output=$(run_wish_batch "echo A & echo B & echo C")
count=$(echo "$output" | grep -cE "^[ABC]$")
if [ "$count" -eq 3 ]; then
    pass "Tres comandos paralelos producen las tres salidas"
else
    fail "Comandos paralelos no produjeron 3 salidas (got: '$output')"
fi

# --------------------------------------------------------------------------
# 8. Modo batch
# --------------------------------------------------------------------------
section "8. Modo batch"

BATCH_OUT=$(run_wish_batch "echo desde_batch")
if echo "$BATCH_OUT" | grep -q "desde_batch"; then
    pass "Modo batch ejecuta comandos del archivo"
else
    fail "Modo batch no ejecutó el comando"
fi

# En modo batch el prompt NO debe aparecer
BATCH_OUT=$(run_wish_batch "echo ok")
if echo "$BATCH_OUT" | grep -q "wish>"; then
    fail "Modo batch imprimió el prompt (no debería)"
else
    pass "Modo batch no imprime prompt"
fi

# Batch file inexistente → error + exit(1)
$WISH /archivo/que/no/existe 2>/dev/null
if [ $? -eq 1 ]; then
    pass "Batch file inexistente produce exit(1)"
else
    fail "Batch file inexistente no produjo exit(1)"
fi

# Usar el batch.txt del proyecto
if [ -f "batch.txt" ]; then
    $WISH batch.txt > /tmp/wish_batch_full.txt 2>/tmp/wish_batch_stderr.txt
    if grep -q "directorio cambiado a tmp" /tmp/wish_batch_full.txt; then
        pass "batch.txt se ejecuta correctamente (cd y echo funcionan)"
    else
        fail "batch.txt no produjo la salida esperada"
    fi
fi

# --------------------------------------------------------------------------
# Resumen
# --------------------------------------------------------------------------
echo ""
echo "========================================"
echo -e "Resultado: ${GREEN}${PASS} pasaron${NC} | ${RED}${FAIL} fallaron${NC}"
echo "========================================"

[ $FAIL -eq 0 ] && exit 0 || exit 1
