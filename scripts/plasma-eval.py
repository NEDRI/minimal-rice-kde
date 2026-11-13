#!/usr/bin/env python3
"""Wysyła skrypt Plasmy (plik) do plasmashell przez D-Bus - bez limitu 128 KB na argument, który ma qdbus6.
Użycie: python3 plasma-eval.py skrypt.js"""
import sys
from gi.repository import Gio, GLib
script = open(sys.argv[1], encoding="utf-8").read()
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
res = bus.call_sync("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript",
                    GLib.Variant("(s)", (script,)), GLib.VariantType("(s)"), Gio.DBusCallFlags.NONE, 60000)
print(res.unpack()[0])
