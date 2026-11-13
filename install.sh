#!/usr/bin/env bash
# minimal-rice-kde: Plasma 6 in the colours of minimal-rice-gnome's GNOME look — graphite and near-black, white
# text, light grey selection, dark glass (blur behind windows, menus and the top bar), Klassy window buttons
# as coloured circles, one top bar per screen with the apps in it, no dock.
#
#   ./install.sh                 everything (packages, icons, settings, panels)
#   ./install.sh --no-packages   skip pacman and the AUR
#   ./install.sh --no-panels     keep your panels; only colours, windows, shortcuts
#   ./install.sh --yes           no questions
#
# Run it as your user from a Plasma (Wayland) session. What it replaces goes to ~/minimal-rice-kde-backup-<date>.
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run it without sudo."; exit 1; }
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
packages=true panels=true yes=false
for a in "$@"; do
    case "$a" in
        --no-packages) packages=false ;;
        --no-panels) panels=false ;;
        --yes|-y) yes=true ;;
        -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $a"; exit 1 ;;
    esac
done
say() { printf '\n\033[1;37m== %s\033[0m\n' "$*"; }
ask() { $yes && return 0; read -rp "$1 [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || echo "Note: not a Plasma session; panels are set the next time you run this from Plasma."
L="$HOME/.local/share"; C="$HOME/.config"
BACKUP="$HOME/minimal-rice-kde-backup-$(date +%F-%H%M)"; mkdir -p "$BACKUP"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
keep() { for f in "$@"; do [ -e "$f" ] && { mkdir -p "$BACKUP$(dirname "${f#$HOME}")"; cp -a "$f" "$BACKUP${f#$HOME}"; }; done; return 0; }

# ---- 1. packages ----
if $packages; then
    say "Packages"
    mapfile -t repo < <(grep -v '^\s*#' "$HERE/packages.txt" | grep .)
    mapfile -t aur < <(grep -v '^\s*#' "$HERE/packages-aur.txt" | grep .)
    echo "pacman: ${repo[*]}"; echo "AUR:    ${aur[*]}"
    if ask "Install them?"; then
        sudo pacman -S --needed "${repo[@]}"
        helper=$(command -v paru || command -v yay || true)
        [ -n "$helper" ] || { echo "No AUR helper (paru/yay): install ${aur[*]} by hand"; exit 1; }
        "$helper" -S --needed "${aur[@]}"
    fi
fi

# ---- 2. icons, cursor, GTK theme (same as the GNOME look) ----
say "Reversal icons (black), Bibata Modern Ice cursor, adw-gtk3"
mkdir -p "$L/icons" "$L/themes" "$L/icons/hicolor/scalable/apps"
if [ ! -d "$L/icons/Reversal-black-dark" ]; then
    git clone -q --depth 1 https://github.com/yeyushengfan258/Reversal-icon-theme "$T/reversal"
    "$T/reversal/install.sh" -t black
fi
[ -d "$L/icons/Bibata-Modern-Ice" ] || { curl -sfL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz -o "$T/bibata.tar.xz" && tar -xf "$T/bibata.tar.xz" -C "$L/icons"; }
[ -d "$L/themes/adw-gtk3-dark" ] || { curl -sfL https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6.5.tar.xz -o "$T/adw.tar.xz" && tar -xf "$T/adw.tar.xz" -C "$L/themes"; }
for v in 3.0 4.0; do mkdir -p "$C/gtk-$v"; keep "$C/gtk-$v/gtk.css"; cp "$HERE/config/gtk/gtk.css" "$C/gtk-$v/gtk.css"; done
cp "$HERE/panels/cachyos-symbolic.svg" "$L/icons/hicolor/scalable/apps/" 2>/dev/null || true

# ---- 3. colours, Plasma style, Konsole ----
say "Colours (Lorien Black), Breeze style, Konsole"
mkdir -p "$L/color-schemes" "$L/konsole"
cp "$HERE/config/color-schemes/LorienBlack.colors" "$L/color-schemes/"
keep "$L/konsole/Lorien.profile"; cp "$HERE"/config/konsole/* "$L/konsole/"
keep "$C/kdeglobals" "$C/konsolerc"
kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true; plasma-apply-colorscheme LorienBlack
plasma-apply-desktoptheme default >/dev/null
/usr/lib/plasma-changeicons Reversal-black-dark 2>/dev/null || kwriteconfig6 --file kdeglobals --group Icons --key Theme Reversal-black-dark
plasma-apply-cursortheme --size 24 Bibata-Modern-Ice >/dev/null || true
qdbus6 org.kde.kded6 /GtkConfig org.kde.GtkConfig.setGtkTheme adw-gtk3-dark >/dev/null 2>&1 || true
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Lorien.profile

# ---- 4. windows: Klassy, rounded corners, Better Blur, 90-97 % opacity ----
say "Windows: Klassy buttons, rounded corners, Better Blur, opacity rule"
keep "$C/kwinrc" "$C/kwinrulesrc" "$C/klassy/klassyrc"
mkdir -p "$C/klassy"; cp "$HERE/config/klassy/klassyrc" "$C/klassy/klassyrc"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kwinrc" "$HERE/config/kwinrc.ini"
python3 -I "$HERE/scripts/merge-ini.py" --rule "$C/kwinrulesrc" "$HERE/config/kwinrule-opacity.ini"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# ---- 5. shortcuts (as in GNOME: Super+B desktop, Super+A overview, Super+E files, Super+F maximize...) ----
say "Shortcuts"
keep "$C/kglobalshortcutsrc"; cp "$HERE/config/kglobalshortcutsrc" "$C/kglobalshortcutsrc"

# ---- 6. panels, favourites, avatar ----
if $panels && [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
    say "Panels (your current ones are replaced), favourites, avatar"
    if ask "Replace the panels?"; then
        keep "$C/plasma-org.kde.plasma.desktop-appletsrc" "$C/plasmashellrc"
        rm -rf "$L/plasma/plasmoids/org.lorien.cpu"; mkdir -p "$L/plasma/plasmoids"
        cp -a "$HERE/panels/plasmoids/org.lorien.cpu" "$L/plasma/plasmoids/"
        python3 -I "$HERE/panels/panels.py" > "$T/panels.js"
        python3 "$HERE/scripts/plasma-eval.py" "$T/panels.js"
        python3 -I "$HERE/scripts/favorites.py"
        systemctl --user restart plasma-plasmashell.service
    fi
fi
cp "$HERE/config/avatar.png" "$HOME/.face.icon"
busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User \
    SetIconFile s "$HOME/.face.icon" >/dev/null 2>&1 || true

say "Done"
echo "Log out and back in: Klassy and the shortcuts are read when KWin starts. Your old settings: $BACKUP"
