#!/usr/bin/env bash
#
# KUSBH - Klipper USB Helper
# Instalace z GitHubu (ve stylu KIAUH)
#
# Pouziti (jednim prikazem):
#   bash <(curl -fsSL https://raw.githubusercontent.com/drumclock/KUSBH/main/bootstrap.sh)
#
# Nebo klasicky:
#   cd ~
#   git clone https://github.com/drumclock/KUSBH.git
#   ./KUSBH/install.sh
#

set -u

REPO_URL="https://github.com/drumclock/KUSBH.git"
BRANCH="main"
TARGET_DIR="${HOME}/KUSBH"

# --- Barvy -------------------------------------------------------------------
C_RESET="\033[0m"; C_CYAN="\033[1;36m"; C_GREEN="\033[1;32m"
C_RED="\033[1;31m"; C_YELLOW="\033[1;33m"; C_DIM="\033[2m"

line() { printf "${C_CYAN}=======================================================${C_RESET}\n"; }
header() {
    clear
    line
    printf "${C_CYAN}     KUSBH  -  Klipper USB Helper  (instalace)${C_RESET}\n"
    line
    echo ""
}

if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; else SUDO=""; fi

header

# --- git musi byt k dispozici ------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
    printf "  ${C_YELLOW}git neni nainstalovan. Zkousim doinstalovat...${C_RESET}\n"
    $SUDO apt-get update && $SUDO apt-get install -y git || {
        printf "  ${C_RED}Nepodarilo se nainstalovat git. Nainstaluj ho rucne a spust znovu.${C_RESET}\n"
        exit 1
    }
fi

# --- Klonovani / aktualizace -------------------------------------------------
if [ -d "${TARGET_DIR}/.git" ]; then
    echo "  -> Repozitar uz existuje, aktualizuji (git pull)..."
    git -C "$TARGET_DIR" pull --ff-only || {
        printf "  ${C_RED}git pull selhal.${C_RESET}\n"; exit 1; }
else
    echo "  -> Stahuji repozitar do ${TARGET_DIR}..."
    git clone --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR" || {
        printf "  ${C_RED}git clone selhal. Zkontroluj, ze repozitar existuje.${C_RESET}\n"; exit 1; }
fi

chmod +x "${TARGET_DIR}/install.sh" 2>/dev/null

echo ""
printf "  ${C_GREEN}Hotovo. Spoustim menu...${C_RESET}\n"
sleep 1

# Spustime menu. Presmerovani z /dev/tty zajisti interaktivitu i pri "curl | bash".
if [ -e /dev/tty ]; then
    exec bash "${TARGET_DIR}/install.sh" </dev/tty
else
    exec bash "${TARGET_DIR}/install.sh"
fi
