"""Tiny adb UI driver for the emulator test: dump visible text, tap by text."""
import re, subprocess, sys, time

def sh(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

def dump():
    sh("adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1")
    xml = sh("adb shell cat /sdcard/ui.xml")
    nodes = re.findall(r'<node [^>]*>', xml)
    out = []
    for n in nodes:
        t = (re.search(r' text="([^"]*)"', n) or [None, ""])[1]
        d = (re.search(r' content-desc="([^"]*)"', n) or [None, ""])[1]
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        label = (t or d).replace("&#10;", " / ")
        if label and b:
            x1, y1, x2, y2 = map(int, b.groups())
            out.append((label, (x1 + x2) // 2, (y1 + y2) // 2))
    return out

def show(tag):
    items = dump()
    print(f"--- {tag}: {len(items)} labels")
    for l, x, y in items[:60]:
        print(f"   [{x},{y}] {l[:110]}")
    return items

def tap(text, tries=6):
    for _ in range(tries):
        for l, x, y in dump():
            if text.lower() in l.lower():
                sh(f"adb shell input tap {x} {y}")
                print(f"tapped '{l[:60]}' at {x},{y}")
                return True
        time.sleep(3)
    print(f"could not find '{text}'")
    return False

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "show": show(sys.argv[2] if len(sys.argv) > 2 else "screen")
    elif cmd == "tap": sys.exit(0 if tap(sys.argv[2]) else 1)
