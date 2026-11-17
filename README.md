# minimal-rice-kde

KDE Plasma 6 in the colours of [minimal-rice-gnome](https://github.com/NEDRI/minimal-rice-gnome)'s GNOME look:
graphite and near-black with white text, light grey selection instead of blue, and **dark glass** —
the wallpaper blurred behind windows, menus and the top bar. Made on CachyOS for a laptop used as a
desktop with two screens, where GNOME did not work well.

```bash
git clone https://github.com/NEDRI/minimal-rice-kde.git
cd minimal-rice-kde
./install.sh
```

Then log out and back in. Options: `--no-packages`, `--no-panels`, `--yes`. Everything it replaces is
saved to `~/minimal-rice-kde-backup-<date>` first.

## What you get

**Colours** — `Lorien Black` scheme: windows `#0e0e0e`, views `#0b0b0b`, buttons `#161616`, white text,
selection `#dcdcdc` with dark text. Breeze Plasma style (follows the scheme), Reversal icons (black),
Bibata Modern Ice cursor, JetBrains Mono, GTK apps in `adw-gtk3-dark` with minimal-rice-gnome's near-black `gtk.css`.

**Dark glass** — [Better Blur](https://github.com/xarblu/kwin-effects-better-blur-dx) blurs the wallpaper
behind every window, menu and panel except Firefox, Ghostty, VLC, mpv and Steam; a KWin rule keeps windows
at 97 % (inactive 95 %), games (`steam_app_*`, `*.exe`, gamescope) and Konsole opaque. Konsole: `#0e0e0e`
at 95 % with its own blur.

**Windows** — [Klassy](https://github.com/paulmcauley/klassy) decoration: the app icon on the left, the title
centred, minimize / maximize / close as teal, blue and red circles on the right, the title bar in the window
colour. [Rounded corners](https://github.com/matinlotfali/KDE-Rounded-Corners) (12 px, dark outline).

**Top bar** (one on every screen, [Panel Colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer)
for the glass) — left: CachyOS menu with favourites, pinned and running apps, app grid; middle: date and
24 h clock; right: CPU, RAM, download and upload (the `org.lorien.cpu` widget from minimal-rice-gnome), the tray
(main screen only) and lock / shut down / restart. No dock and no virtual desktop pager.

**Shortcuts** as in the GNOME look: `Super+B` desktop, `Super+A` overview, `Super+E` Dolphin, `Super+F` maximize, `Super+Shift+S` a screenshot of a region (then the Spectacle window to annotate and save)
and the rest from `config/kglobalshortcutsrc`.

**Favourites** in the menu (`scripts/favorites.py`): browser, editor, terminal, files, Discord, Claude, the game
launchers (Steam, Lutris, Heroic, Bottles, Prism Launcher, Sober), music, MATLAB, LibreOffice, EasyEffects,
System Settings — only the ones installed. **Avatar**: the white CachyOS logo on black.

**Global theme** — `Lorien Black` (`config/look-and-feel/`) is set as Plasma's light and dark theme, so the
"Dark Mode" switch in Quick Settings no longer puts Breeze back over the colours, icons and window buttons.

**Wallpapers** — 28 pictures (`wallpapers/pictures`, go to `~/Pictures/Wallpapers`) and the "Nothing1" wallpaper
package; `config/wallpapers.ini` says which one is on which screen and on the lock screen (main screen
and login screen: `disco-ruud`, second screen and lock screen: `wallhaven-rqj55m`). `tapety` links every picture into Plasma's wallpaper list.

**System settings** — JetBrains Mono everywhere, keyboard `us,pl` (euro variant), flat mouse acceleration (and the
settings of a Razer Basilisk X and a Corsair Scimitar), no automatic screen lock (`Super+L` locks), Firefox as the
browser and PDF viewer, Konsole as the terminal, EasyEffects presets for a BlackShark V3 Pro headset and its microphone (with the LV2
plugins it needs), zsh with oh-my-zsh and a Starship prompt. The menu icon and the avatar take the distro's logo
(CachyOS or EndeavourOS); pinned apps that are not installed are left out of the bar.

**Steam** — [Adwaita for Steam](https://github.com/tkashkin/Adwaita-for-Steam) through
[AdwSteamGtk](https://github.com/Foldex/AdwSteamGtk) (Flathub): its "Oled" colours with `config/steam/custom.css`
on top — the same `#0e0e0e` / `#0b0b0b` greys, light grey accent with dark text, and the window buttons as the
teal, blue and red circles of Klassy. A Steam update puts the stock look back: `steam-theme` re-applies it. Vulkan shaders are processed on every CPU
thread but one (`steam_dev.cfg`), and every game is set to update at once ("Immediately download updates",
"Always allow background downloads") instead of being scheduled: `steam-update-now`, with Steam closed, also for
games installed later.

**Login screen** — `sddm/lorien-black`, an SDDM theme based on Breeze: the wallpaper blurred under a near-black
veil, the avatar, password and power buttons on a dark glass card, the clock in the system font. `install.sh` copies
it to `/usr/share/sddm/themes` and sets it in `/etc/sddm.conf.d/10-kde.conf` (Wayland greeter through KWin);
"Apply Plasma Settings" in the Login Screen settings brings the colours, font and cursor over. `theme.conf` has
`dim` (veil) and `cardOpacity`.

**Lock screen** — `lockscreen/org.minimalrice.lockscreen`, a Plasma shell package that holds only the lock screen:
a big thin clock with the weekday and date on the left, a dark glass column on the right with the avatar, password,
media controls and Sleep / Switch User. Everything else falls back to Plasma's own shell. KWin starts the lock
screen, so a drop-in for `plasma-kwin_wayland.service` sets `PLASMA_DEFAULT_SHELL` for it alone (plasmashell keeps
its shell); it takes effect after logging in again. Remove the drop-in to get Breeze's lock screen back.

**Not included** (they belong to one machine): drivers, kernel, scheduler, snapshots, disks, Steam launch options.

## After updates

Klassy, Better Blur and the rounded corners are KWin plugins built against one KWin version. After a KWin
update they stop loading until rebuilt. At login `kwin-rebuild-check.service` notices it and shows a
notification; then run

```bash
kwin-rebuild
```

(it rebuilds them with paru or yay, `--force` to rebuild anyway) and log in again.

After a Steam update run `steam-theme` (it does nothing when the theme is still there) and restart Steam.

## Files

| Path | What |
|---|---|
| `config/color-schemes/LorienBlack.colors` | the colour scheme |
| `config/klassy/klassyrc` | Klassy (based on its "Eaten Fruits" preset) |
| `config/kwinrc.ini` | decoration, rounded corners, Better Blur and which effects are on |
| `config/kwinrule-opacity.ini` | the window opacity rule |
| `config/konsole/` | Konsole profile and colours |
| `config/kglobalshortcutsrc` | shortcuts |
| `config/gtk/gtk.css` | near-black GTK colours |
| `panels/panels.py`, `panels/colorizer-top.json` | the top bar, generated as a Plasma script |
| `scripts/plasma-eval.py` | sends a Plasma script over D-Bus (qdbus6 has a 128 KB argument limit) |
| `config/steam/` | Steam theme: AdwSteamGtk options and the colour overrides |
| `scripts/merge-ini.py` | merges the INI fragments into KDE's config files |

License: GPL-3.0-or-later, like minimal-rice-gnome.
