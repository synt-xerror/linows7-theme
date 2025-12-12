#!/bin/bash

# Configurações de cores
source ../../src/toybox.sh
source ../../src/status
lang=$(<../../src/lang)

CUR_DIR=$(pwd)
USE_SCRIPT="install.sh"

# Checagem de dependências
lechoe "Verificando dependências..." "Checking dependencies..."
if ! command -v cmake &>/dev/null; then
    lechoe "${RED}CMake não encontrado.${NC}" "${RED}CMake not found.${NC}"
    exit 1
fi
if ! command -v ninja &>/dev/null && ! command -v make &>/dev/null; then
    lechoe "${RED}Nem Ninja nem Make encontrados.${NC}" "${RED}Neither Ninja nor Make found.${NC}"
    exit 1
fi
lechoe "Dependências OK!" "Dependencies OK!"

# Função genérica para compilar pastas
compile_folder() {
    local folder="$1"
    local msg_pt="$2"
    local msg_en="$3"

    lechoe "$msg_pt" "$msg_en"
    cd "$folder" || { lechoe "Erro: pasta não encontrada: $folder" "Error: folder not found: $folder"; return 1; }
    sh "$USE_SCRIPT" "$@"
    cd "$CUR_DIR" || return 1
    lechoe "Concluído." "Done."
}

# Compilação das partes
compile_folder "$PWD/misc/libplasma" "Compilando libplasma..." "Compiling libplasma..."
compile_folder "$PWD/kwin/decoration" "Compilando SMOD decorations..." "Compiling SMOD decorations..."
compile_folder "$PWD/plasma/aerothemeplasma-kcmloader" "Compilando KCM loader..." "Compiling KCM loader..."

lechoe "Compilando efeitos KWin..." "Compiling KWin effects..."
for f in "$PWD/kwin/effects_cpp/"*; do
    compile_folder "$f" "Compilando $(basename "$f")..." "Compiling $(basename "$f")..."
done
