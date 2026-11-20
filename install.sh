#!/usr/bin/env bash
# minimal-rice-kde: Plasma 6 in the colours of minimal-rice-gnome's GNOME look — graphite and near-black, white
# text, light grey selection, dark glass (blur behind windows, menus and the top bar), Klassy window buttons
# as coloured circles, one top bar per screen with the apps in it, no dock.
#
#   ./install.sh                 everything (packages, icons, settings, wallpapers, panels)
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
cp "$HERE"/panels/*-symbolic.svg "$L/icons/hicolor/scalable/apps/"   # CachyOS and EndeavourOS logos

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
# a global theme of its own, also as Plasma's light AND dark theme: the "Dark Mode" switch in Quick Settings
# would otherwise put Breeze back (colours, icons, window buttons, cursor)
mkdir -p "$L/plasma/look-and-feel"
rm -rf "$L/plasma/look-and-feel/org.minimalrice.lorienblack.desktop"
cp -a "$HERE/config/look-and-feel/org.minimalrice.lorienblack.desktop" "$L/plasma/look-and-feel/"
for k in LookAndFeelPackage DefaultDarkLookAndFeel DefaultLightLookAndFeel; do
    kwriteconfig6 --file kdeglobals --group KDE --key "$k" org.minimalrice.lorienblack.desktop
done

# ---- 4. windows: Klassy, rounded corners, Better Blur, 90-97 % opacity ----
say "Windows: Klassy buttons, rounded corners, Better Blur, opacity rule"
keep "$C/kwinrc" "$C/kwinrulesrc" "$C/klassy/klassyrc"
mkdir -p "$C/klassy"; cp "$HERE/config/klassy/klassyrc" "$C/klassy/klassyrc"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kwinrc" "$HERE/config/kwinrc.ini"
# window opacity (97 % / 95 %) as a KWin script, not a window rule: a rule cannot tell games apart, so fullscreen
# games were see-through. The script keeps fullscreen and screen-filling windows opaque.
rm -rf "$L/kwin/scripts/lorien-opacity"; mkdir -p "$L/kwin/scripts"; cp -r "$HERE/kwin/lorien-opacity" "$L/kwin/scripts/"
kwriteconfig6 --file kwinrc --group Plugins --key lorien-opacityEnabled true
python3 -I - "$C/kwinrulesrc" <<'PY' || true   # drop the old rule from earlier installs
import re, sys
p = sys.argv[1]
try: s = open(p).read()
except FileNotFoundError: sys.exit()
s = re.sub(r"\[lorien-black-opacity\].*?(?=\n\[|\Z)", "", s, flags=re.S)
s = re.sub(r"^(Order=.*)$", lambda m: ",".join(x for x in m.group(1).split(",") if x != "lorien-black-opacity"), s, flags=re.M)
open(p, "w").write(s.strip() + "\n")
PY
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
# after a KWin update these plugins need a rebuild: `kwin-rebuild` does it, a login check sends a notification
install -Dm755 "$HERE/scripts/kwin-rebuild" "$HOME/.local/bin/kwin-rebuild"
install -Dm644 "$HERE/config/kwin-rebuild-check.service" "$C/systemd/user/kwin-rebuild-check.service"
systemctl --user daemon-reload && systemctl --user enable kwin-rebuild-check.service >/dev/null 2>&1 || true
"$HOME/.local/bin/kwin-rebuild" >/dev/null || true   # remembers the KWin version the plugins were built for

# ---- 5. shortcuts (as in GNOME: Super+B desktop, Super+A overview, Super+E files, Super+F maximize...) ----
say "Shortcuts"
keep "$C/kglobalshortcutsrc"; cp "$HERE/config/kglobalshortcutsrc" "$C/kglobalshortcutsrc"
# Super+Shift+S: pick a region, then the Spectacle window (its own region shortcut only saves in the background)
install -Dm644 "$HERE/config/net.local.spectacle-region-gui.desktop" "$L/applications/net.local.spectacle-region-gui.desktop"

# ---- 6. system settings: fonts, keyboard, mouse, no automatic screen lock, Firefox as the browser ----
say "Fonts (JetBrains Mono), keyboard (us,pl), mouse, screen lock, default browser"
keep "$C/kxkbrc" "$C/kcminputrc" "$C/kscreenlockerrc" "$C/mimeapps.list"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kdeglobals" "$HERE/config/kdeglobals-fonts.ini"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kxkbrc" "$HERE/config/kxkbrc.ini"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kcminputrc" "$HERE/config/kcminputrc.ini"
python3 -I "$HERE/scripts/merge-ini.py" "$C/kscreenlockerrc" "$HERE/config/kscreenlockerrc.ini"
if [ -e /usr/share/applications/firefox.desktop ]; then
    xdg-settings set default-web-browser firefox.desktop 2>/dev/null || true
    for t in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml application/pdf; do
        xdg-mime default firefox.desktop "$t" 2>/dev/null || true
    done
    kwriteconfig6 --file kdeglobals --group General --key BrowserApplication firefox.desktop
    # Konsole as the terminal everywhere: KDE, xdg-terminal-exec launchers, GTK apps, $TERMINAL
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication konsole
    kwriteconfig6 --file kdeglobals --group General --key TerminalService org.kde.konsole.desktop
    for f in xdg-terminals.list kde-xdg-terminals.list; do echo org.kde.konsole.desktop > "$C/$f"; done
    gsettings set org.gnome.desktop.default-applications.terminal exec konsole 2>/dev/null || true
    mkdir -p "$C/environment.d"; echo TERMINAL=konsole > "$C/environment.d/terminal.conf"
fi

# ---- 7. EasyEffects presets (headset + microphone), zsh with Starship ----
say "EasyEffects presets, zsh + Starship"
mkdir -p "$L/easyeffects" "$C/autostart"
cp -a "$HERE/config/easyeffects/input" "$HERE/config/easyeffects/output" "$L/easyeffects/"
command -v easyeffects >/dev/null && cp "$HERE/config/easyeffects/easyeffects-service.desktop" "$C/autostart/"
keep "$HOME/.zshrc" "$C/starship.toml"
cp "$HERE/config/shell/zshrc" "$HOME/.zshrc"; cp "$HERE/config/shell/starship.toml" "$C/starship.toml"
[ "$(getent passwd "$USER" | cut -d: -f7)" = /bin/zsh ] || [ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ] ||
    echo "zsh is not your login shell yet: chsh -s /bin/zsh"

# ---- 7b. Steam in the same colours (Adwaita for Steam via AdwSteamGtk + config/steam/custom.css) ----
if command -v flatpak >/dev/null && { command -v steam >/dev/null || [ -d "$L/Steam" ]; }; then
    say "Steam theme"
    APP=io.github.Foldex.AdwSteamGtk; AD="$HOME/.var/app/$APP/config"
    flatpak info "$APP" >/dev/null 2>&1 || { ask "Install AdwSteamGtk from Flathub (it applies the Steam theme)?" &&
        flatpak install -y --user flathub "$APP"; } || true
    if flatpak info "$APP" >/dev/null 2>&1; then
        keep "$AD/glib-2.0/settings/keyfile" "$AD/AdwSteamGtk/custom.css"
        install -Dm644 "$HERE/config/steam/adwsteamgtk.keyfile" "$AD/glib-2.0/settings/keyfile"
        install -Dm644 "$HERE/config/steam/custom.css" "$AD/AdwSteamGtk/custom.css"
        install -Dm755 "$HERE/scripts/steam-theme" "$HOME/.local/bin/steam-theme"
        "$HOME/.local/bin/steam-theme" --force || true
    fi
fi
# Steam: shaders on every CPU thread but one, games update at once instead of on Steam's schedule
if command -v steam >/dev/null || [ -d "$L/Steam" ]; then
    say "Steam: shader threads, immediate game updates"
    mkdir -p "$L/Steam"
    echo "unShaderBackgroundProcessingThreads $(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))" > "$L/Steam/steam_dev.cfg"
    install -Dm755 "$HERE/scripts/steam-update-now" "$HOME/.local/bin/steam-update-now"
    [ -f "$L/Steam/steamapps/libraryfolders.vdf" ] && { "$HOME/.local/bin/steam-update-now" || true; }
fi

# ---- 7c. login screen: SDDM with the Lorien Black theme (Breeze-based, blurred wallpaper + near-black glass card) ----
if pacman -Qq sddm >/dev/null 2>&1; then
    say "SDDM login theme"
    if ask "Install the Lorien Black SDDM theme (sudo)?"; then
        sudo rm -rf /usr/share/sddm/themes/lorien-black
        sudo cp -r "$HERE/sddm/lorien-black" /usr/share/sddm/themes/lorien-black
        sudo install -Dm644 "$HERE/sddm/10-kde.conf" /etc/sddm.conf.d/10-kde.conf
        echo "Then in System Settings > Login Screen (SDDM): Apply Plasma Settings (colours, font, cursor)."
        systemctl is-enabled sddm >/dev/null 2>&1 || echo "SDDM is installed but not the login manager: sudo systemctl enable sddm (after disabling the current one)"
    fi
fi

# ---- 7d. lock screen layout: big clock on the left, dark glass column with the login on the right ----
say "Lock screen layout"
rm -rf "$L/plasma/shells/org.minimalrice.lockscreen"; mkdir -p "$L/plasma/shells"
cp -r "$HERE/lockscreen/org.minimalrice.lockscreen" "$L/plasma/shells/"
# KWin starts the lock screen; the variable reaches only KWin and its children, not plasmashell
install -Dm644 "$HERE/config/systemd/kwin-lockscreen.conf" "$C/systemd/user/plasma-kwin_wayland.service.d/lockscreen.conf"
systemctl --user daemon-reload 2>/dev/null || true

# ---- 8. wallpapers (every screen and the lock screen) ----
if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
    say "Wallpapers"
    python3 -I "$HERE/scripts/wallpapers.py"
    install -Dm755 "$HERE/scripts/tapety" "$HOME/.local/bin/tapety" && "$HOME/.local/bin/tapety"
fi

# ---- 9. panels, favourites, avatar ----
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
# avatar: the distro's white logo on black (CachyOS or EndeavourOS)
logo="$HERE/panels/cachyos-symbolic.svg"; grep -q endeavouros /etc/os-release 2>/dev/null && logo="$HERE/panels/endeavouros-symbolic.svg"
magick -background none -density 600 "$logo" -fill white -colorize 100 -resize 150x150 "$T/logo.png" &&
    magick -size 256x256 xc:black "$T/logo.png" -gravity center -composite -colorspace Gray "$HOME/.face.icon" ||
    cp "$HERE/config/avatar.png" "$HOME/.face.icon"
busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User \
    SetIconFile s "$HOME/.face.icon" >/dev/null 2>&1 || true

say "Done"
echo "Log out and back in: Klassy and the shortcuts are read when KWin starts. Your old settings: $BACKUP"
