#!/bin/bash

CUR_DIR=$(pwd)
USE_SCRIPT="install.sh"

source ../../src/toybox.sh
source ../../src/status
lang=$(<../../src/lang)

# Verifica dependências
lechoe "Verificando dependências..." "Checking dependencies..."
for cmd in kpackagetool6 cmake; do
    if ! command -v "$cmd" &>/dev/null; then
        lechoe "${RED}$cmd não encontrado. Abortando.${NC}" "${RED}$cmd not found. Aborting.${NC}"
        exit 1
    fi
done

if ! command -v ninja &>/dev/null && ! command -v make &>/dev/null; then
    lechoe "${RED}Nem Ninja nem Make encontrados. Abortando.${NC}" "${RED}Neither Ninja nor Make found. Aborting.${NC}"
    exit 1
fi
lechoe "Dependências OK!" "Dependencies OK!"

# Compila plasmoids se não houver --no-compile
if [[ $1 == '--no-compile' ]]; then
    lechoe "Pulando compilação..." "Skipping compilation..."
else
    lechoe "Compilando plasmoids..." "Compiling plasmoids..."
    for folder in "$PWD/plasma/plasmoids/src/"*; do
        [[ ! -d "$folder" ]] && continue
        lechoe "Compilando $(basename "$folder")..." "Compiling $(basename "$folder")..."
        cd "$folder" || continue
        sh "$USE_SCRIPT" "$@"
        cd "$CUR_DIR" || exit
        lechoe "Concluído." "Done."
    done
fi

# Função para instalar ou atualizar plasmoids
install_plasmoid() {
    local folder="$1"
    local plasmoid=$(basename "$folder")
    [[ "$plasmoid" == "src" ]] && { lechoe "Pulando $plasmoid..." "Skipping $plasmoid..."; return; }

    local installed
    installed=$(kpackagetool6 -l -t "Plasma/Applet" | grep "$plasmoid")
    if [[ -z "$installed" ]]; then
        lechoe "Instalando $plasmoid..." "Installing $plasmoid..."
        kpackagetool6 -t "Plasma/Applet" -i "$folder"
    else
        lechoe "Atualizando $plasmoid..." "Updating $plasmoid..."
        kpackagetool6 -t "Plasma/Applet" -u "$folder"
    fi
    echo ""
}

# Para manter configurações, reinicia o plasmashell
lechoe "Reiniciando plasmashell..." "Restarting plasmashell..."
killall plasmashell &>/dev/null

# Instala ou atualiza todos os plasmoids
for folder in "$PWD/plasma/plasmoids/"*; do
    [[ ! -d "$folder" ]] && continue
    install_plasmoid "$folder"
done

# Reinicia plasmashell de forma desacoplada
setsid plasmashell --replace &

lechoe "Todos os plasmoids foram instalados/atualizados." "All plasmoids installed/updated."
