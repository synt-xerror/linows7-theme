#!/bin/bash

set -e
CUR_DIR=$(pwd)
USE_PKEXEC="pkexec"

source ../../src/toybox.sh
source ../../src/status
lang=$(<../../src/lang)

# ---------------------------
# Sanity checks
# ---------------------------
if ! command -v kpackagetool6 &>/dev/null; then
    lechoe "kpackagetool6 não encontrado. Encerrando." \
          "kpackagetool6 not found. Stopping."
    exit 1
fi

if ! command -v $USE_PKEXEC &>/dev/null; then
    lechoe "pkexec não encontrado. Polkit é necessário. Encerrando." \
          "pkexec not found. Polkit required. Stopping."
    exit 1
fi

# ---------------------------
# install_component <path> <KPackage type>
# ---------------------------
install_component() {
    COMPONENT=$(basename "$1")
    TYPE="$2"

    INSTALLED=$(kpackagetool6 -l -t "$TYPE" | grep -F "$COMPONENT" || true)

    if [[ -z "$INSTALLED" ]]; then
        lecho "$COMPONENT não instalado — instalando..." \
              "$COMPONENT not installed — installing..."
        kpackagetool6 -t "$TYPE" -i "$1"
    else
        lecho "$COMPONENT encontrado — atualizando..." \
              "$COMPONENT found — upgrading..."
        kpackagetool6 -t "$TYPE" -u "$1"
    fi

    lecho "" ""
    cd "$CUR_DIR"
}

# ---------------------------
# SMOD resources
# ---------------------------
lecho "Instalando recursos SMOD..." \
      "Installing SMOD resources..."
$USE_PKEXEC cp -r "$PWD/kwin/smod" "/usr/share/"
lecho "Feito." "Done."
lecho "" ""

# ---------------------------
# KWin Effects
# ---------------------------
lecho "Instalando efeitos do KWin..." \
      "Installing KWin effects..."
for filename in "$PWD/kwin/effects/"*; do
    install_component "$filename" "KWin/Effect"
done
lecho "Feito." "Done."
lecho "" ""

# ---------------------------
# KWin Scripts
# ---------------------------
lecho "Instalando scripts do KWin..." \
      "Installing KWin scripts..."
for filename in "$PWD/kwin/scripts/"*; do
    install_component "$filename" "KWin/Script"
done
lecho "Feito." "Done."
lecho "" ""

# ---------------------------
# Task Switchers
# ---------------------------
lecho "Instalando alternadores de janela (Task Switchers)..." \
      "Installing window switchers..."
for filename in "$PWD/kwin/tabbox/"*; do
    install_component "$filename" "KWin/WindowSwitcher"
done
lecho "Feito." "Done."
lecho "" ""

# ---------------------------
# Outline
# ---------------------------
lecho "Instalando outline de janelas..." \
      "Installing window outline..."
KWIN_DIR="$HOME/.local/share/kwin"
mkdir -p "$KWIN_DIR"
cp -r "$PWD/kwin/outline" "$KWIN_DIR"
lecho "Feito." "Done."
lecho "" ""

# ---------------------------
# Symlinks X11/Wayland
# ---------------------------
LOCAL_DIR="$HOME/.local/share"
cd "$LOCAL_DIR"

lecho "Criando symlinks kwin-x11 e kwin-wayland..." \
      "Creating kwin-x11 and kwin-wayland symlinks..."

[[ ! -e kwin-x11 ]] && ln -s kwin kwin-x11
[[ ! -e kwin-wayland ]] && ln -s kwin kwin-wayland

lecho "Feito." "Done."
lecho "" ""

lecho "Todos os componentes foram instalados com sucesso!" \
      "All components installed successfully!"
