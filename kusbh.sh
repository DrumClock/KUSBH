#!/usr/bin/env bash
#
# KUSBH - Klipper USB Helper
# Interaktivni instalator (ve stylu KIAUH)
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
CONF="/etc/kusbh.conf"

DEFAULT_ITEMS="config database"

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

is_installed() { [ -f "$DST_SCRIPT" ] && [ -f "$DST_RULE" ]; }
is_git_repo()  { [ -d "${SCRIPT_DIR}/.git" ]; }

reload_udev() {
    echo "  -> Nacitam pravidla UDEVu..."
    $SUDO udevadm control --reload-rules && $SUDO udevadm trigger
}

# Najde printer_data (stejne jako mountcopy).
detect_printer_data() {
    for d in /home/*/printer_data; do
        [ -d "$d" ] || continue
        PRINTER_DATA="$d"
        [ -d "$d/config" ] && break
    done
}

# Vrati aktualne nastavene BACKUP_ITEMS (z conf, jinak default).
current_items() {
    if [ -f "$CONF" ]; then
        ( . "$CONF" 2>/dev/null; echo "${BACKUP_ITEMS:-$DEFAULT_ITEMS}" )
    else
        echo "$DEFAULT_ITEMS"
    fi
}

# Zapise vyber do /etc/kusbh.conf
write_conf() {
    local items="$1"
    printf '%s\n' "# KUSBH configuration" \
                  "# Slozky z printer_data, ktere se zaloguji na USB (oddelene mezerou)." \
                  "BACKUP_ITEMS=\"${items}\"" | $SUDO tee "$CONF" >/dev/null
}

# --- Interaktivni vyber slozek pro zalohu ------------------------------------
configure_backup() {
    header
    echo "  Vyber slozek pro zalohu (USB se slozkou 'backup')"
    echo ""

    PRINTER_DATA=""
    detect_printer_data
    if [ -z "${PRINTER_DATA:-}" ]; then
        printf "  ${C_RED}printer_data nenalezen.${C_RESET}\n"
        printf "  ${C_DIM}Ponechavam vychozi: ${DEFAULT_ITEMS}${C_RESET}\n"
        write_conf "$DEFAULT_ITEMS"
        pause
        return
    fi

    # Kandidati = podslozky printer_data
    local items=() d
    for d in "$PRINTER_DATA"/*/; do
        [ -d "$d" ] || continue
        items+=("$(basename "$d")")
    done
    if [ "${#items[@]}" -eq 0 ]; then
        printf "  ${C_YELLOW}V printer_data nejsou zadne slozky.${C_RESET}\n"
        write_conf "$DEFAULT_ITEMS"
        pause
        return
    fi

    # Predvybrane = aktualni nastaveni (nebo default)
    declare -A picked
    local it c cur
    cur="$(current_items)"
    for it in "${items[@]}"; do picked[$it]=0; done
    for c in $cur; do
        for it in "${items[@]}"; do [ "$it" = "$c" ] && picked[$it]=1; done
    done

    local choice i
    while true; do
        header
        echo "  Vyber slozek pro zalohu - prepni cislem, Enter potvrdi."
        printf "  ${C_DIM}Slozka printer_data: %s${C_RESET}\n\n" "$PRINTER_DATA"
        i=1
        for it in "${items[@]}"; do
            if [ "${picked[$it]:-0}" = 1 ]; then
                printf "   %2d) ${C_GREEN}[x]${C_RESET} %s\n" "$i" "$it"
            else
                printf "   %2d) [ ] %s\n" "$i" "$it"
            fi
            i=$((i+1))
        done
        echo ""
        echo "    a) vybrat vse    z) zrusit vyber"
        echo ""
        line
        read -r -p "   Volba (Enter = hotovo): " choice
        case "$choice" in
            "" ) break ;;
            a|A) for it in "${items[@]}"; do picked[$it]=1; done ;;
            z|Z) for it in "${items[@]}"; do picked[$it]=0; done ;;
            *[!0-9]*) ;;  # ignoruj necislo
            *)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#items[@]}" ]; then
                    it="${items[$((choice-1))]}"
                    if [ "${picked[$it]:-0}" = 1 ]; then picked[$it]=0; else picked[$it]=1; fi
                fi
                ;;
        esac
    done

    # Sestav seznam
    local sel=""
    for it in "${items[@]}"; do
        [ "${picked[$it]:-0}" = 1 ] && sel="$sel $it"
    done
    sel="$(echo $sel | xargs)"
    [ -z "$sel" ] && sel="$DEFAULT_ITEMS"

    write_conf "$sel"
    header
    printf "  ${C_GREEN}Ulozeno.${C_RESET} Zaloha bude obsahovat: ${C_CYAN}%s${C_RESET}\n" "$sel"
    printf "  ${C_DIM}(zapsano do %s)${C_RESET}\n" "$CONF"
    pause
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

    # Zapis vychozi config, pokud jeste neexistuje
    if [ ! -f "$CONF" ]; then
        write_conf "$DEFAULT_ITEMS"
    fi

    reload_udev

    echo ""
    printf "  ${C_GREEN}Hotovo. mount_copy je nainstalovan.${C_RESET}\n"
    printf "  ${C_DIM}Nyni muzes vybrat slozky pro zalohu.${C_RESET}\n"
    echo ""
    read -r -p "  Nastavit slozky pro zalohu ted? [A/n]: " ans
    case "$ans" in
        n|N) : ;;
        *) configure_backup ;;
    esac
}

do_uninstall() {
    header
    echo "  Odinstalace..."
    echo ""

    local removed=0
    if [ -f "$DST_RULE" ]; then echo "  -> Odstranuji ${DST_RULE}"; $SUDO rm -f "$DST_RULE" && removed=1; fi
    if [ -f "$DST_SCRIPT" ]; then echo "  -> Odstranuji ${DST_SCRIPT}"; $SUDO rm -f "$DST_SCRIPT" && removed=1; fi
    if [ -f "$CONF" ]; then echo "  -> Odstranuji ${CONF}"; $SUDO rm -f "$CONF"; fi

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
        pause; return
    fi
    if ! command -v git >/dev/null 2>&1; then
        printf "  ${C_RED}git neni nainstalovan.${C_RESET}\n"; pause; return
    fi

    echo "  -> git pull"
    if ! git -C "$SCRIPT_DIR" pull --ff-only; then
        printf "  ${C_RED}git pull selhal.${C_RESET}\n"; pause; return
    fi

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
    printf "   Zaloha slozky: ${C_CYAN}%s${C_RESET}\n" "$(current_items)"
    if is_git_repo; then
        printf "   Zdroj        : ${C_GREEN}git repozitar${C_RESET}\n"
    else
        printf "   Zdroj        : ${C_DIM}mistni slozka${C_RESET}\n"
    fi
    pause
}

# --- Menu --------------------------------------------------------------------
main_menu() {
    local choice
    while true; do
        header
        if is_installed; then
            printf "   Stav: ${C_GREEN}nainstalovano${C_RESET}   |   zaloha: ${C_CYAN}%s${C_RESET}\n\n" "$(current_items)"
        else
            printf "   Stav: ${C_RED}nenainstalovano${C_RESET}\n\n"
        fi
        echo "   1) Instalovat"
        echo "   2) Odinstalovat"
        echo "   3) Aktualizovat        (git pull)"
        echo "   4) Slozky pro zalohu"
        echo "   5) Stav"
        echo ""
        echo "   q) Konec"
        echo ""
        line
        read -r -p "   Volba: " choice
        case "$choice" in
            1) do_install ;;
            2) do_uninstall ;;
            3) do_update ;;
            4) configure_backup ;;
            5) do_status ;;
            q|Q) header; echo "  Nashledanou."; echo ""; exit 0 ;;
            *) ;;
        esac
    done
}

main_menu
