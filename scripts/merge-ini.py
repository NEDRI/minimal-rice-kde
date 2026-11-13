#!/usr/bin/env python3
"""Merges the groups of a small INI file into a KDE config file, key by key (the rest of the target stays).

    merge-ini.py TARGET SOURCE           e.g. ~/.config/kwinrc config/kwinrc.ini
    merge-ini.py --rule TARGET SOURCE    also lists the source's groups as KWin window rules
                                         (kwinrulesrc [General] Order=...)
"""
import configparser
import sys

args = sys.argv[1:]
rule = args[0] == "--rule"
if rule:
    args = args[1:]
target, source = args


def load(path):
    c = configparser.RawConfigParser(strict=False, interpolation=None, delimiters=("=",))
    c.optionxform = str
    c.read(path, encoding="utf-8")
    return c


t, s = load(target), load(source)
for group in s.sections():
    if not t.has_section(group):
        t.add_section(group)
    for key, value in s.items(group):
        t.set(group, key, value)
    if rule:
        if not t.has_section("General"):
            t.add_section("General")
        # KWin 6 lists rules in Order (older KWin: rules + count, which it converts on its own)
        order = [r for r in t.get("General", "Order", fallback=t.get("General", "rules", fallback="")).split(",") if r]
        if group not in order:
            order.append(group)
        t.set("General", "Order", ",".join(order))
with open(target, "w", encoding="utf-8") as f:
    t.write(f, space_around_delimiters=False)
print(f"{target}: {', '.join(s.sections())}")
