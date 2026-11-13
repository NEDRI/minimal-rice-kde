#!/usr/bin/env python3
"""Kickoff favourites. Plasma 6 keeps them in the activity manager's database, not in the menu's config,
so they are written there (with their order) while kactivitymanagerd is stopped. Desktop files that are
not installed are skipped.

    python3 favorites.py          (then: systemctl --user restart plasma-plasmashell)
"""
import configparser
import os
import sqlite3
import subprocess

FAVORITES = ["firefox", "com.microsoft.VSCode", "org.kde.konsole", "org.kde.dolphin", "vesktop",
             "com.anthropic.Claude", "steam", "net.lutris.Lutris", "com.heroicgameslauncher.hgl",
             "com.usebottles.bottles", "org.prismlauncher.PrismLauncher", "org.vinegarhq.Sober",
             "com.mastermindzh.tidal-hifi", "spotify", "MATLABWindow", "libreoffice-writer",
             "com.github.wwmm.easyeffects", "systemsettings"]
AGENT = "org.kde.plasma.favorites.applications"
DB = os.path.expanduser("~/.local/share/kactivitymanagerd/resources/database")
DIRS = [os.path.expanduser("~/.local/share/applications"), "/var/lib/flatpak/exports/share/applications",
        "/usr/share/applications"]

installed = [f for f in FAVORITES if any(os.path.exists(f"{d}/{f}.desktop") for d in DIRS)]
resources = [f"applications:{f}.desktop" for f in installed]

subprocess.run(["systemctl", "--user", "stop", "plasma-kactivitymanagerd.service"], check=False)
db = sqlite3.connect(DB)
for r in resources:
    if not db.execute("select 1 from ResourceLink where initiatingAgent=? and targettedResource=?", (AGENT, r)).fetchone():
        db.execute("insert into ResourceLink(usedActivity, initiatingAgent, targettedResource) values(':global',?,?)",
                   (AGENT, r))
db.commit()

rc = os.path.expanduser("~/.config/kactivitymanagerd-statsrc")
cfg = configparser.RawConfigParser(strict=False, interpolation=None); cfg.optionxform = str; cfg.read(rc)
group = f"ResultModel-OrderingFor-{AGENT}:global"
cfg.has_section(group) or cfg.add_section(group)
cfg.set(group, "ordering", ",".join(resources))
cfg.write(open(rc, "w"), space_around_delimiters=False)
subprocess.run(["systemctl", "--user", "start", "plasma-kactivitymanagerd.service"], check=False)
print(f"{len(resources)} favourites:", " ".join(installed))
