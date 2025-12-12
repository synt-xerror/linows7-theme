#!/bin/bash

set -e
CUR_DIR=$(pwd)
TMP_DIR="/tmp/atp"
mkdir -p "$TMP_DIR"

source ../../src/toybox.sh
source ../../src/status
lang=$(<../../src/lang)

# Funções de mensagens já importadas: lechoe, lreadp, loading, etc.

# Verifica dependências
lechoe "Verificando dependências..." "Checking dependencies..."
for cmd in tar unzip pkexec update-mime-database; do
    if ! command -v "$cmd" &>/dev/null; then
        lechoe "${RED}$cmd não encontrado. Abortando.${NC}" "${RED}$cmd not found. Aborting.${NC}"
        exit 1
    fi
done
lechoe "Dependências OK!" "Dependencies OK!"

# Instala Kvantum
lechoe "Instalando tema Kvantum..." "Installing Kvantum theme..."
KV_DIR="$HOME/.config"
cp -r "$PWD/misc/kvantum/Kvantum" "$KV_DIR"
lechoe "Concluído." "Done."

# Instala sons
lechoe "Instalando temas sonoros..." "Installing sound themes..."
SOUNDS_DIR="$HOME/.local/share/sounds"
mkdir -p "$SOUNDS_DIR"
tar -xf "$PWD/misc/sounds/sounds.tar.gz" --directory "$SOUNDS_DIR"
lechoe "Concluído." "Done."

# Instala ícones
lechoe "Instalando tema de ícones..." "Installing icon theme..."
ICONS_DIR="$HOME/.local/share/icons"
mkdir -p "$ICONS_DIR"
tar -xf "$PWD/misc/icons/Windows 7 Aero" --directory "$ICONS_DIR"
lechoe "Concluído." "Done."

# Instala wallpapers
lechoe "Instalando wallpapers..." "Installing wallpapers.."
WALLP_DIR="$HOME/.local/share/wallpapers"
mkdir -p "$WALLP_DIR"
mkdir -p "$WALLP_DIR/Windows 7"
mv "$PWD/misc/wallpapers/*" "$WALLP_DIR/Windows 7"
lechoe "Concluído." "Done."

# Instala fotos de perfil
lechoe "Instalando fotos de perfil..." "Installing profile pictures..."
PIC_DIR="/usr/share/plasma/avatars"
mkdir -p "$PIC_DIR/Windows 7"
mv "$PWD/misc/pictures/*" "$PIC_DIR/Windows 7"
lechoe "Concluído." "Done."

# Instala cursor
lechoe "Instalando tema de cursor (pode pedir senha)..." "Installing cursor theme (may require password)..."
CURSOR_DIR="/usr/share/icons"
pkexec tar -xf "$PWD/misc/cursors/aero-drop.tar.gz" --directory "$CURSOR_DIR"
lechoe "Concluído." "Done."

# Instala mimetypes
lechoe "Instalando mimetypes..." "Installing mimetypes..."
MIMETYPE_DIR="$HOME/.local/share/mime/packages"
mkdir -p "$MIMETYPE_DIR"
for f in "$PWD/misc/mimetype/"*; do
    cp -r "$f" "$MIMETYPE_DIR"
done
update-mime-database "$HOME/.local/share/mime"
lechoe "Concluído." "Done."

# Instala fontes Segoe UI opcional
lreadp "Deseja instalar configuração customizada de fontes Segoe UI? (Recomendado) (y/N): " \
       "Do you want to install custom Segoe UI font configuration? (Recommended) (y/N): " answer
FONTCONF_DIR="$HOME/.config"
if [[ "$answer" =~ ^[Yy]$ ]]; then
    [[ -f "$FONTCONF_DIR/fontconfig/fonts.conf" ]] && cp "$FONTCONF_DIR/fontconfig/fonts.conf" "$FONTCONF_DIR/fontconfig/fonts.conf.old"
    lechoe "Instalando configuração de fontes..." "Installing font configuration..."
    cp -r "$PWD/misc/fontconfig/" "$FONTCONF_DIR"
    
    HAS_VAR=$(grep "QML_DISABLE_DISTANCEFIELD" /etc/environment || true)
    if [[ -z "$HAS_VAR" ]]; then
        lechoe "Adicionando QML_DISABLE_DISTANCEFIELD=1..." "Adding QML_DISABLE_DISTANCEFIELD=1..."
        pkexec sh -c "echo 'QML_DISABLE_DISTANCEFIELD=1' >> /etc/environment"
    fi
fi
lechoe "Concluído." "Done."

# Branding opcional
lreadp "Deseja instalar branding customizado para Info Center? (y/N): " \
       "Do you want to install custom branding for Info Center? (y/N): " answer
BRANDING_DIR="$HOME/.config/kdedefaults"
mkdir -p "$BRANDING_DIR"
if [[ "$answer" =~ ^[Yy]$ ]]; then
    for f in "$PWD/misc/branding/"*; do
        cp -r "$f" "$BRANDING_DIR"
    done
    kwriteconfig6 --file "$BRANDING_DIR/kcm-about-distrorc" --group General --key LogoPath "$BRANDING_DIR/kcminfo.png"
fi
lechoe "Concluído." "Done."

# Terminal font opcional
lreadp "Deseja instalar fonte para Terminal (Terminal Vector)? (y/N): " \
       "Do you want to install command prompt font (Terminal Vector)? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    curl -L https://www.yohng.com/files/TerminalVector.zip > "$TMP_DIR/TerminalVector.zip"
    unzip "$TMP_DIR/TerminalVector.zip" -d "$TMP_DIR"
    kfontinst "$TMP_DIR/TerminalVector.ttf"
fi
lechoe "Concluído." "Done."

# Plymouth opcional
lreadp "Deseja instalar tema Plymouth? (y/N): " "Do you want to install Plymouth theme? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    if ! command -v git &>/dev/null; then
        lechoe "Git não encontrado! Instalação manual necessária." "Git not found! Manual installation required."
        lechoe "Baixe o repositório em https://github.com/furkrn/PlymouthVista" "Download repo from https://github.com/furkrn/PlymouthVista"
    else
        git clone https://github.com/furkrn/PlymouthVista "$TMP_DIR/PlymouthVista"
        cd "$TMP_DIR/PlymouthVista"
        chmod +x compile.sh install.sh
        ./compile.sh
        pkexec --keep-cwd ./install.sh
        lechoe "Para mais detalhes, veja https://github.com/furkrn/PlymouthVista" "For more details, check https://github.com/furkrn/PlymouthVista"
    fi

    # Plymouth wait-animation opcional
    lreadp "Deseja segurar a animação do Plymouth até o final? (y/N): " \
        "Do you want to wait for the Plymouth animation to finish? (y/N): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        SERVICE_FILE="/etc/systemd/system/plymouth-wait-animation.service"
        lechoe "Criando serviço plymouth-wait-animation..." "Creating plymouth-wait-animation service..."

pkexec tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Wait for Plymouth animation to complete
DefaultDependencies=no
After=plymouth-start.service
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/sleep 7

[Install]
WantedBy=multi-user.target
EOF

        lechoe "Reload do systemd..." "Reloading systemd..."
        pkexec systemctl daemon-reload

        lechoe "Ativando serviço plymouth-wait-animation..." "Enabling plymouth-wait-animation service..."
        pkexec systemctl enable plymouth-wait-animation.service

        lechoe "Serviço criado e ativado. A animação será exibida até o final." \
            "Service created and enabled. Animation will play fully."
    fi

fi

lechoe "Instalação concluída!" "Installation complete!"
