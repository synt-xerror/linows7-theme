#!/bin/bash
set -e

source ../../src/toybox.sh
source ../../src/status
lang=$(<../../src/lang)
CUR_DIR=$(pwd)

# Funções de mensagens já importadas: lechoe, loading, lmenu, etc.

# Verifica dependências
lechoe "Verificando dependências..." "Checking dependencies..."
for cmd in kpackagetool6 cmake tar sddmthemeinstaller; do
    if ! command -v "$cmd" &>/dev/null; then
        lechoe "${RED}$cmd não encontrado. Abortando.${NC}" "${RED}$cmd not found. Aborting.${NC}"
        exit 1
    fi
done
lechoe "Dependências OK!" "Dependencies OK!"

# Função genérica para instalar ou atualizar componentes KDE
install_component() {
    local folder="$1"
    local type="$2"
    local comp=$(basename "$folder")
    local installed=$(kpackagetool6 -l -t "$type" | grep -F "$comp")

    if [[ -z "$installed" ]]; then
        lechoe "Instalando $comp..." "Installing $comp..."
        kpackagetool6 -t "$type" -i "$folder"
    else
        lechoe "Atualizando $comp..." "Updating $comp..."
        kpackagetool6 -t "$type" -u "$folder"
    fi
    echo ""
    cd "$CUR_DIR"
}

# Lista de componentes para instalar
declare -A components=(
    ["Plasma/LookAndFeel"]="$PWD/plasma/look-and-feel/authui7"
    ["Plasma/LayoutTemplate"]="$PWD/plasma/layout-templates/io.gitgud.wackyideas.taskbar"
    ["Plasma/Theme"]="$PWD/plasma/desktoptheme/Seven-Black"
    ["Plasma/Shell"]="$PWD/plasma/shells/io.gitgud.wackyideas.desktop"
)

# Instala todos os componentes
for type in "${!components[@]}"; do
    install_component "${components[$type]}" "$type"
done

# Instala o esquema de cores
lechoe "Instalando esquema de cores..." "Installing color scheme..."
COLOR_DIR="$HOME/.local/share/color-schemes"
mkdir -p "$COLOR_DIR"
cp "$PWD/plasma/color_scheme/Aero.colors" "$COLOR_DIR"
# plasma-apply-colorscheme Aero

# Instala o tema SDDM
lechoe "Instalando entradas do gerenciador de login..." "Installing login manager entries..."
cd "$CUR_DIR/plasma/sddm/login-sessions" && sh install.sh

lechoe "Instalando tema do SDDM..." "Installing SDDM theme..."
cd "$CUR_DIR/plasma/sddm"
tar -zcf "sddm-theme-mod.tar.gz" "sddm-theme-mod"
sddmthemeinstaller -i "sddm-theme-mod.tar.gz"
rm "sddm-theme-mod.tar.gz"

lechoe "Todos os componentes foram instalados/atualizados!" "All components installed/updated!"
# setsid plasmashell --replace & # opcional: reinicia plasmashell
