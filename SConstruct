#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# tweak this if you want to use different folders, or more folders, to store your source code in.
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")
sources += Glob("src/algorithm/*.c")

if env["target"] == "template_debug":
    env.Append(CCFLAGS=["-g", "-O0", "-DDEBUG_ENABLED"])

platform_map = {
    "windows.x86_32": "win32",
    "windows.x86_64": "win64",
    "macos.universal": "macos",
    "linux.x86_32": "linux32",
    "linux.x86_64": "linux64",
}

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "addons/godot-blurhash/{}/libblurhash.{}.framework/libblurhash.{}".format(
            platform_map[f'{env["platform"]}.{env["arch"]}'], env["target"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "addons/godot-blurhash/{}/libblurhash.{}.{}{}".format(platform_map[f'{env["platform"]}.{env["arch"]}'], env["target"], env["arch"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
