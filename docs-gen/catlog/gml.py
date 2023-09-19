from pathlib import Path
from . import lib
import re

def script_name_to_module_name(module):
    name = module.replace("scr_", "").replace("catspeak_", "")
    return name

def parse_module(fullpath):
    name = script_name_to_module_name(Path(fullpath).with_suffix("").name)
    overview = ""
    doc = lib.DocComment()
    with open(fullpath, "r", encoding="utf-8") as file:
        print(f"...parsing gml module '{name}'")
        for line in file.readlines():
            if match := re.search("^\s*//!(.*)", line):
                overview += match.group(1)
            elif match := re.search("^\s*///(.*)", line):
                doc.current().desc += match.group(1)
    return lib.Module(
        name = name,
        overview = overview
    )