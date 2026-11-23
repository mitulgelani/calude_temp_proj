#!/usr/bin/env python3
"""
One-time project setup. Run from the project root:   python tool/setup.py

1. Generates the standard Flutter Android scaffolding around Pluck's own files
   (`flutter create` never overwrites files that already exist).
2. Wires in Chaquopy (free, MIT) so yt-dlp + instaloader run inside the app.

Needs: Flutter, JDK 17+, and Python 3.12 on PATH (Chaquopy builds with the same Python version it ships).
Override the Chaquopy version with:  CHAQUOPY_VERSION=17.0.0 python tool/setup.py
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAQUOPY = os.environ.get("CHAQUOPY_VERSION", "17.2.0")
PYTHON = os.environ.get("PLUCK_PYTHON", "3.12")
PIP = ["yt-dlp", "instaloader", "certifi"]
ABIS = ["arm64-v8a", "x86_64"]  # Python 3.12+ ships 64-bit only (every phone since ~2017)


def run(cmd):
    print("→", " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True, shell=(os.name == "nt"))


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)


def find(*names):
    for n in names:
        p = os.path.join(ROOT, "android", *n.split("/"))
        if os.path.exists(p):
            return p
    sys.exit("Could not find any of: " + ", ".join(names))


def patch_settings():
    p = find("settings.gradle.kts", "settings.gradle")
    s = read(p)
    if "com.chaquo.python" in s:
        return
    kts = p.endswith(".kts")
    line = ('    id("com.chaquo.python") version "%s" apply false\n' if kts else "    id 'com.chaquo.python' version '%s' apply false\n") % CHAQUOPY
    m = re.search(r"\nplugins\s*\{\n", s)
    if not m:
        sys.exit("settings.gradle has no plugins {} block — add the Chaquopy plugin manually (see README).")
    s = s[: m.end()] + line + s[m.end():]
    write(p, s)
    print("✓ Chaquopy plugin added to", os.path.basename(p))


def patch_app():
    p = find("app/build.gradle.kts", "app/build.gradle")
    s = read(p)
    if "chaquopy" in s:
        return
    kts = p.endswith(".kts")

    # plugin — must come after the Android application plugin
    m = re.search(r"[^\n]*com\.android\.application[^\n]*\n", s)
    if not m:
        m = re.search(r"plugins\s*\{\n", s)
    s = s[: m.end()] + ('    id("com.chaquo.python")\n' if kts else "    id 'com.chaquo.python'\n") + s[m.end():]

    # minSdk 24 (Chaquopy requirement)
    s, n = re.subn(r"minSdk\s*=\s*[^\n]+", "minSdk = 24", s) if kts else re.subn(r"minSdk(Version)?\s+[^\n]+", "minSdkVersion 24", s)
    if n == 0:
        s = re.sub(r"(defaultConfig\s*\{\n)", r"\1        minSdk%s 24\n" % (" =" if kts else "Version"), s, count=1)

    # ABIs that Python ships for
    abis = ", ".join('"%s"' % a for a in ABIS)
    ndk = ("        ndk {\n            abiFilters += listOf(%s)\n        }\n" % abis) if kts else \
          ("        ndk {\n            abiFilters %s\n        }\n" % abis)
    s = re.sub(r"(defaultConfig\s*\{\n)", lambda mm: mm.group(1) + ndk, s, count=1)

    pip = "\n".join(('            install("%s")' if kts else "            install \"%s\"") % x for x in PIP)
    block = (
        "\nchaquopy {\n    defaultConfig {\n        version = \"%s\"\n        pip {\n%s\n        }\n    }\n}\n" % (PYTHON, pip)
        if kts else
        "\nchaquopy {\n    defaultConfig {\n        version \"%s\"\n        pip {\n%s\n        }\n    }\n}\n" % (PYTHON, pip)
    )
    s = s.rstrip() + "\n" + block
    write(p, s)
    print("✓ Chaquopy configured in", os.path.basename(p), "(Python %s, %s)" % (PYTHON, ", ".join(PIP)))


def main():
    if not shutil.which("flutter"):
        sys.exit("Flutter isn’t on PATH. Install it from flutter.dev first.")
    run(["flutter", "create", "--org", "com.pluck", "--project-name", "pluck", "--platforms", "android", "."])
    # flutter create adds a counter-app test that doesn't match Pluck
    t = os.path.join(ROOT, "test", "widget_test.dart")
    if os.path.exists(t) and "Counter" in read(t):
        os.remove(t)
    patch_settings()
    patch_app()
    run(["flutter", "pub", "get"])
    print("\nDone. Next:\n  flutter run                      (phone connected)\n  flutter build apk --release --target-platform android-arm64,android-x64")


if __name__ == "__main__":
    main()
