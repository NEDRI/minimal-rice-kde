#!/usr/bin/env python3
"""Wallpapers: copies wallpapers/pictures to ~/Pictures/Wallpapers and wallpapers/packages to
~/.local/share/wallpapers, then sets the image of every screen and of the lock screen from config/wallpapers.ini.

    python3 wallpapers.py            (from a Plasma session)
"""
import configparser
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(HERE, "wallpapers")
PICTURES = os.path.expanduser("~/Pictures/Wallpapers")
PACKAGES = os.path.expanduser("~/.local/share/wallpapers")


def target(rel):
    """Where a path from wallpapers.ini ends up after copying."""
    kind, _, rest = rel.partition("/")
    return os.path.join(PICTURES if kind == "pictures" else PACKAGES, rest)


shutil.copytree(os.path.join(SRC, "pictures"), PICTURES, dirs_exist_ok=True)
shutil.copytree(os.path.join(SRC, "packages"), PACKAGES, dirs_exist_ok=True)

cfg = configparser.RawConfigParser(); cfg.optionxform = str
cfg.read(os.path.join(HERE, "config", "wallpapers.ini"))
screens = {int(k): target(v) for k, v in cfg.items("Screens")}

js = "var W = %s;\n" % repr({str(k): v for k, v in screens.items()}).replace("'", '"') + """
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
    var d = ds[i], img = W[String(d.screen)] || W["0"];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", img);
    print("screen " + d.screen + ": " + img + "\\n");
}
"""
tmp = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "minimal-rice-kde-wallpapers.js")
open(tmp, "w").write(js)
subprocess.run([sys.executable, os.path.join(HERE, "scripts", "plasma-eval.py"), tmp], check=False)
os.remove(tmp)

lock = target(cfg.get("LockScreen", "Image"))
group = ["--group", "Greeter", "--group", "Wallpaper", "--group", "org.kde.image", "--group", "General"]
for key in ("Image", "PreviewImage"):
    subprocess.run(["kwriteconfig6", "--file", "kscreenlockerrc", *group, "--key", key, lock], check=False)
print("lock screen:", lock)
