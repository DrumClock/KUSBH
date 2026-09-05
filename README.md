# KUSBH — Klipper USB Helper

**Jazyk / Language:** 🇨🇿 **Čeština** · 🇬🇧 **English** — klikni na sekci níže pro rozbalení / click a section below to expand.

<details open>
<summary><b>🇨🇿 Česky</b></summary>

<br>

> Jednoduchá pomůcka pro přenos G-code mezi USB flash diskem a Klipperem
> a pro zálohu konfigurace Klipperu na USB. Stačí zasunout USB — o zbytek
> se postará udev.

## ✨ Funkce

- **📥 Import** — vložíš USB s `*.gcode` → soubory se zkopírují do tiskové složky.
- **📤 Export** — vložíš prázdný USB → všechny `*.gcode` se přesunou z tiskárny na USB.
- **💾 Záloha** — vložíš USB se složkou `backup` → zazálohuje se `config` a `database`
  do podsložky s datem a časem (staré zálohy se nepřepisují).
- **🛡️ Ochrana tisku** — když se tiskne, ostatní soubory se přenesou normálně, ale
  právě tištěný soubor se **nikdy** nepřepíše ani neodstěhuje.
- **💬 Hlášení** — průběh se ukazuje na displeji (`M117`) i v konzoli (`RESPOND MSG=`).
- **🔎 Autodetekce** — cesta k `printer_data` se najde sama (pi, biqu, mks…).

## 🚀 Instalace z GitHubu (ve stylu KIAUH)

Jedním příkazem (stáhne repozitář a rovnou spustí menu):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/drumclock/KUSBH/main/bootstrap.sh)
```

Nebo klasicky:

```bash
cd ~
git clone https://github.com/drumclock/KUSBH.git
./KUSBH/install.sh
```

## 🧭 Menu (`install.sh`)

```text
1) Instalovat
2) Odinstalovat
3) Aktualizovat  (git pull)
4) Slozky pro zalohu
5) Stav
q) Konec
```

Skript si sám najde potřebné soubory a v případě potřeby si vyžádá heslo (`sudo`).

## 💾 Jak zálohovat

Na USB vytvoř složku `backup` a disk zasuň. Zálohy se ukládají takto:

```text
backup/2025-09-04_19-33-01/
```

Když je na USB složka `backup`, provede se **jen záloha** (import/export G-code se přeskočí).
Které složky se zálohují si vybereš **při instalaci** (nebo kdykoli přes
menu → *Složky pro zálohu*). Instalátor nabídne složky, které v `printer_data`
reálně existují; výběr se uloží do `/etc/kusbh.conf` (`BACKUP_ITEMS`).
Výchozí je `config` + `database`.

## 💬 Hlášení na displeji / v konzoli

Po zasunutí USB uvidíš průběh, např.:

```text
KUSBH: USB detekovan
KUSBH: import 3 souboru
KUSBH: export 2 (tisk chranen)
KUSBH: hotovo, muzes vyjmout USB
```

> **Pozn.:** `RESPOND MSG=` vyžaduje v konfiguraci Klipperu sekci `[respond]`.
> Pokud ji nemáš (v konzoli by se objevilo *Unknown command RESPOND*), nastav
> `USE_RESPOND=0`. Zpráva na displeji se po 10 s sama smaže.

## ⚙️ Konfigurace

Vše se nastavuje nahoře v souboru `mountcopy`. Cestu k `printer_data`
nastavovat **nemusíš** — najde se automaticky.

| Proměnná        | Výchozí                   | Popis                                                        |
|-----------------|---------------------------|--------------------------------------------------------------|
| `MOONRAKER_URL` | `http://localhost:7125`   | Adresa Moonrakeru (detekce tisku + hlášení).                 |
| `NOTIFY`        | `1`                       | Zapne hlášení `M117`/`RESPOND`. `0` = vypnuto.               |
| `USE_RESPOND`   | `1`                       | Posílat i do konzole (vyžaduje `[respond]`). `0` = jen `M117`. |
| `CLEAR_AFTER`   | `10`                      | Za kolik sekund smazat displej. `0` = nemazat.               |

## 🔧 Ruční instalace (bez menu)

```bash
sudo cp 99-mountcopy.rules /etc/udev/rules.d/
sudo cp mountcopy /usr/bin
sudo chmod +x /usr/bin/mountcopy
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## 🗑️ Ruční odinstalace

```bash
sudo rm /etc/udev/rules.d/99-mountcopy.rules
sudo rm /usr/bin/mountcopy
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## ⚠️ Upozornění

Skript sám pozná probíhající tisk (přes Moonraker) a právě tištěný soubor
ochrání. Pokud ale **Moonraker není dostupný**, ochrana se neuplatní — potom
platí staré doporučení: **USB během tisku raději nepoužívej**, mohlo by dojít
k přepsání nebo smazání tištěného souboru.

</details>

<details>
<summary><b>🇬🇧 English</b></summary>

<br>

> A small helper to move G-code between a USB flash drive and Klipper, and to
> back up the Klipper configuration to USB. Just plug in the drive — udev does
> the rest.

## ✨ Features

- **📥 Import** — insert a USB with `*.gcode` → files are copied into the print folder.
- **📤 Export** — insert an empty USB → all `*.gcode` are moved from the printer onto it.
- **💾 Backup** — insert a USB containing a `backup` folder → `config` and `database`
  are backed up into a timestamped subfolder (old backups are never overwritten).
- **🛡️ Print protection** — while printing, other files transfer normally, but the
  file currently being printed is **never** overwritten or moved.
- **💬 Notifications** — progress is shown on the display (`M117`) and console (`RESPOND MSG=`).
- **🔎 Auto-detect** — the `printer_data` path is found automatically (pi, biqu, mks…).

## 🚀 Install from GitHub (KIAUH style)

One command (downloads the repo and launches the menu):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/drumclock/KUSBH/main/bootstrap.sh)
```

Or the classic way:

```bash
cd ~
git clone https://github.com/drumclock/KUSBH.git
./KUSBH/install.sh
```

## 🧭 Menu (`install.sh`)

```text
1) Install
2) Uninstall
3) Update  (git pull)
4) Backup folders
5) Status
q) Quit
```

## 💾 How to back up

Create a `backup` folder on the USB drive and plug it in. Backups are stored as:

```text
backup/2025-09-04_19-33-01/
```

If a `backup` folder is present, **only** the backup runs (G-code import/export is skipped).
You choose which folders are backed up **during install** (or anytime via the menu →
*Backup folders*). The installer lists the folders that actually exist in `printer_data`;
the choice is saved to `/etc/kusbh.conf` (`BACKUP_ITEMS`). Default is `config` + `database`.

## 💬 Status messages

After inserting the USB you will see progress, e.g.:

```text
KUSBH: USB detekovan
KUSBH: import 3 souboru
KUSBH: export 2 (tisk chranen)
KUSBH: hotovo, muzes vyjmout USB
```

> **Note:** `RESPOND MSG=` requires the `[respond]` section in your Klipper config.
> If you don't have it, set `USE_RESPOND=0`. The display message clears after 10 s.

## ⚙️ Configuration

Everything is set at the top of `mountcopy`. You do **not** need to set the
`printer_data` path — it is auto-detected.

| Variable        | Default                   | Description                                              |
|-----------------|---------------------------|----------------------------------------------------------|
| `MOONRAKER_URL` | `http://localhost:7125`   | Moonraker address (print detection + messages).          |
| `NOTIFY`        | `1`                       | Enable `M117`/`RESPOND` messages. `0` = off.             |
| `USE_RESPOND`   | `1`                       | Also print to console (needs `[respond]`). `0` = `M117` only. |
| `CLEAR_AFTER`   | `10`                      | Seconds before clearing the display. `0` = keep.         |

## 🔧 Manual install

```bash
sudo cp 99-mountcopy.rules /etc/udev/rules.d/
sudo cp mountcopy /usr/bin
sudo chmod +x /usr/bin/mountcopy
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## 🗑️ Manual uninstall

```bash
sudo rm /etc/udev/rules.d/99-mountcopy.rules
sudo rm /usr/bin/mountcopy
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## ⚠️ Warning

The script detects a running print (via Moonraker) and protects the printed file.
However, if **Moonraker is unreachable** the protection cannot apply — then the old
advice holds: **avoid using the USB drive while printing**, as the printed file
could be overwritten or deleted.

</details>
