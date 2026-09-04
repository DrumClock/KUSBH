#!/usr/bin/env bash
#
# mount_copy - interaktivni instalator (ve stylu KIAUH)
#
# Spusteni:  ./install.sh
#

set -u

# --- Cesty -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_SCRIPT="${SCRIPT_DIR}/mountcopy"
SRC_RULE="${SCRIPT_DIR}/99-mountcopy.rules"

DST_SCRIPT="/usr/bin/mountcopy"
DST_RULE="/etc/udev/rules.d/99-mountcopy.rules"

# --- Barvy -------------------------------------------------------------------
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"
C_YELLOW="\033[1;33m"
C_DIM="\033[2m"

# --- sudo helper -------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# --- Pomocne funkce ----------------------------------------------------------
line() { printf "${C_CYAN}=======================================================${C_RESET}\n"; }

header() {
    clear
    line
    printf "${C_CYAN}       KUSBH  -  Klipper USB Helper${C_RESET}\n"
    line
    echo ""
}

pause() {
    echo ""
    read -r -p "Stiskni Enter pro navrat do menu..." _
}

is_installed() {
    [ -f "$DST_SCRIPT" ] && [ -f "$DST_RULE" ]
}

is_git_repo() {
    [ -d "${SCRIPT_DIR}/.git" ]
}

reload_udev() {
    echo "  -> Nacitam pravidla UDEVu..."
    $SUDO udevadm control --reload-rules && $SUDO udevadm trigger
}

# --- Akce --------------------------------------------------------------------
do_install() {
    header
    echo "  Instalace..."
    echo ""

    if [ ! -f "$SRC_SCRIPT" ] || [ ! -f "$SRC_RULE" ]; then
        printf "  ${C_RED}Chyba:${C_RESET} v tomto adresari chybi 'mountcopy' nebo '99-mountcopy.rules'.\n"
        printf "  ${C_DIM}Spoustej install.sh ze slozky s projektem.${C_RESET}\n"
        pause
        return
    fi

    echo "  -> Kopiruju skript do ${DST_SCRIPT}"
    $SUDO cp "$SRC_SCRIPT" "$DST_SCRIPT" || { printf "  ${C_RED}Kopirovani selhalo.${C_RESET}\n"; pause; return; }
    $SUDO chmod +x "$DST_SCRIPT"

    echo "  -> Kopiruju udev pravidlo do ${DST_RULE}"
    $SUDO cp "$SRC_RULE" "$DST_RULE" || { printf "  ${C_RED}Kopirovani selhalo.${C_RESET}\n"; pause; return; }

    reload_udev

    echo ""
    printf "  ${C_GREEN}Hotovo. mount_copy je nainstalovan.${C_RESET}\n"
    pause
}

do_uninstall() {
    header
    echo "  Odinstalace..."
    echo ""

    local removed=0
    if [ -f "$DST_RULE" ]; then
        echo "  -> Odstranuji ${DST_RULE}"
        $SUDO rm -f "$DST_RULE" && removed=1
    fi
    if [ -f "$DST_SCRIPT" ]; then
        echo "  -> Odstranuji ${DST_SCRIPT}"
        $SUDO rm -f "$DST_SCRIPT" && removed=1
    fi

    if [ "$removed" -eq 0 ]; then
        printf "  ${C_YELLOW}Neni co odstranovat - mount_copy nebyl nainstalovan.${C_RESET}\n"
        pause
        return
    fi

    reload_udev
    echo ""
    printf "  ${C_GREEN}Hotovo. mount_copy byl odstranen.${C_RESET}\n"
    pause
}

do_update() {
    header
    echo "  Aktualizace z GitHubu..."
    echo ""

    if ! is_git_repo; then
        printf "  ${C_YELLOW}Tato slozka neni git repozitar - aktualizace pres git neni mozna.${C_RESET}\n"
        printf "  ${C_DIM}Nainstaluj projekt pres 'git clone', pak pujde aktualizovat.${C_RESET}\n"
        pause
        return
    fi

    if ! command -v git >/dev/null 2>&1; then
        printf "  ${C_RED}git neni nainstalovan.${C_RESET}\n"
        pause
        return
    fi

    echo "  -> git pull"
    if ! git -C "$SCRIPT_DIR" pull --ff-only; then
        printf "  ${C_RED}git pull selhal.${C_RESET}\n"
        pause
        return
    fi

    # Pokud uz je nastroj nainstalovan, rovnou aktualizujeme i nainstalovane soubory.
    if is_installed; then
        echo ""
        echo "  -> Aktualizuji nainstalovane soubory..."
        $SUDO cp "$SRC_SCRIPT" "$DST_SCRIPT" && $SUDO chmod +x "$DST_SCRIPT"
        $SUDO cp "$SRC_RULE" "$DST_RULE"
        reload_udev
    fi

    echo ""
    printf "  ${C_GREEN}Hotovo. Projekt je aktualni.${C_RESET}\n"
    pause
}

do_status() {
    header
    echo "  Stav instalace:"
    echo ""
    if [ -f "$DST_SCRIPT" ]; then
        printf "   Skript udev  : ${C_GREEN}nainstalovan${C_RESET}  (%s)\n" "$DST_SCRIPT"
    else
        printf "   Skript udev  : ${C_RED}chybi${C_RESET}\n"
    fi
    if [ -f "$DST_RULE" ]; then
        printf "   Pravidlo udev: ${C_GREEN}nainstalovano${C_RESET} (%s)\n" "$DST_RULE"
    else
        printf "   Pravidlo udev: ${C_RED}chybi${C_RESET}\n"
    fi
    if is_git_repo; then
        printf "   Zdroj        : ${C_GREEN}git repozitar${C_RESET} (%s)\n" "$SCRIPT_DIR"
    else
        printf "   Zdroj        : ${C_DIM}mistni slozka${C_RESET} (%s)\n" "$SCRIPT_DIR"
    fi
    pause
}

# --- Menu --------------------------------------------------------------------
main_menu() {
    while true; do
        header
        if is_installed; then
            printf "   Stav: ${C_GREEN}nainstalovano${C_RESET}\n\n"
        else
            printf "   Stav: ${C_RED}nenainstalovano${C_RESET}\n\n"
        fi
        echo "   1) Instalovat"
        echo "   2) Odinstalovat"
        echo "   3) Aktualizovat  (git pull)"
        echo "   4) Stav"
        echo ""
        echo "   q) Konec"
        echo ""
        line
        read -r -p "   Volba: " choice
        case "$choice" in
            1) do_install ;;
            2) do_uninstall ;;
            3) do_update ;;
            4) do_status ;;
            q|Q) header; echo "  Nashledanou."; echo ""; exit 0 ;;
            *) ;;
        esac
    done
}

main_menu
