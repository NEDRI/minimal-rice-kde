#!/usr/bin/env python3
"""Panels: one top bar per screen, dark glass across the whole width (Panel Colorizer, colorizer-top.json):
CachyOS menu with favourites, pinned and running apps, app grid | clock | CPU, RAM, network, tray
(main screen only), power. No virtual desktop pager and no dock.

    python3 panels.py > /tmp/panels.js && python3 ../scripts/plasma-eval.py /tmp/panels.js
    systemctl --user restart plasma-plasmashell   # otherwise the bar on screen 0 is sometimes not drawn
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

SENSORS = [
    {"General": {"sensorId": "cpu/all/usage", "icon": "\U000f0ee0", "title": "CPU", "decimals": 0}},
    {"General": {"sensorId": "memory/physical/usedPercent", "icon": "\U000f035b", "title": "RAM", "decimals": 0}},
    {"General": {"sensorId": "network/all/download", "icon": "\U000f01da", "title": "Download", "unit": "formatted"}},
    {"General": {"sensorId": "network/all/upload", "icon": "\U000f0552", "title": "Upload", "unit": "formatted"}},
]
APP_DIRS = [os.path.expanduser("~/.local/share/applications"), "/var/lib/flatpak/exports/share/applications",
            os.path.expanduser("~/.local/share/flatpak/exports/share/applications"), "/usr/share/applications"]


def installed(desktop_id):
    return any(os.path.exists(os.path.join(d, desktop_id)) for d in APP_DIRS)


# pinned in the bar; the ones not installed on this computer are left out (no empty icons)
LAUNCHERS = ",".join("applications:" + d for d in (
    "firefox.desktop", "com.microsoft.VSCode.desktop", "org.kde.konsole.desktop", "vesktop.desktop",
    "com.mastermindzh.tidal-hifi.desktop", "com.anthropic.Claude.desktop", "org.kde.dolphin.desktop") if installed(d))


def distro_logo():
    """The menu icon: the distro's white logo (install.sh copies both into the icon theme)."""
    try:
        ids = open("/etc/os-release").read()
    except OSError:
        ids = ""
    return "endeavouros-symbolic" if "endeavouros" in ids else "cachyos-symbolic"


layout = {
    "top": [
        ["org.kde.plasma.kickoff", {"General": {"icon": distro_logo(), "favoritesPortedToKAstats": True}}],
        ["org.kde.plasma.icontasks", {"General": {"launchers": LAUNCHERS, "showOnlyCurrentDesktop": False,
                                                  "showOnlyCurrentActivity": False, "iconSpacing": 1}}],
        ["org.kde.plasma.kickerdash", {"General": {"icon": "view-app-grid-symbolic"}}],
        ["org.kde.plasma.panelspacer", {}],
        ["org.kde.plasma.digitalclock", {"Appearance": {"showDate": True, "dateDisplayFormat": "BesideTime",
                                                        "dateFormat": "shortDate", "use24hFormat": 2,
                                                        "showSeconds": 0}}],
        ["org.kde.plasma.panelspacer", {}],
        *[["org.lorien.cpu", s] for s in SENSORS],
        ["org.kde.plasma.systemtray", {"General": {"iconSpacing": 1}}],   # pominięty na drugim ekranie
        ["org.kde.plasma.lock_logout", {"General": {"show_lockScreen": True, "show_requestShutDown": True,
                                                    "show_requestReboot": True, "show_requestLogoutScreen": False,
                                                    "show_switchUser": False}}],
        ["luisbocanegra.panel.colorizer", {"General": {"hideWidget": True, "islandsEnabled": False,
                                                       "islandSeparatorWidget": "org.kde.plasma.panelspacer",
                                                       "globalSettings": open(os.path.join(HERE, "colorizer-top.json")).read()}}],
    ],
}

JS = """
var L = %s;
function configure(w, groups) {
    for (var g in groups) {
        w.currentConfigGroup = g.split("/");
        for (var k in groups[g]) w.writeConfig(k, groups[g][k]);
    }
    w.reloadConfig();
}
var old = panels();
for (var i = 0; i < old.length; i++) old[i].remove();
for (var s = 0; s < screenCount; s++) {
    var top = new Panel("org.kde.panel");
    top.screen = s; top.location = "top"; top.height = 32; top.floating = false; top.hiding = "none";
    L.top.forEach(function (it) {
        if (s > 0 && it[0] === "org.kde.plasma.systemtray") return;   // jeden zasobnik, na głównym ekranie
        configure(top.addWidget(it[0]), it[1]);
    });
    print("ekran " + s + ": pasek " + top.widgetIds.length + " widżetów\\n");
}
"""

sys.stdout.write(JS % json.dumps(layout, ensure_ascii=False))
