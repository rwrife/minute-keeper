#!/usr/bin/env python3
import os
from pathlib import Path
from PIL import Image

repo_dir = str(Path(__file__).resolve().parent.parent)
src = os.path.join(repo_dir, "AppStore", "icon.png")

im = Image.open(src)
if im.mode != "RGB":
    im = im.convert("RGB")

# 1. AppStore/icon.png
appstore_icon = os.path.join(repo_dir, "AppStore", "icon.png")
im.save(appstore_icon, format="PNG")
print(f"Saved {appstore_icon}")

# 2. iOS Assets.xcassets/AppIcon.appiconset
ios_dir = os.path.join(repo_dir, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
ios_sizes = {
    "Icon-App-20x20@1x.png": (20, 20),
    "Icon-App-20x20@2x.png": (40, 40),
    "Icon-App-20x20@3x.png": (60, 60),
    "Icon-App-29x29@1x.png": (29, 29),
    "Icon-App-29x29@2x.png": (58, 58),
    "Icon-App-29x29@3x.png": (87, 87),
    "Icon-App-40x40@1x.png": (40, 40),
    "Icon-App-40x40@2x.png": (80, 80),
    "Icon-App-40x40@3x.png": (120, 120),
    "Icon-App-60x60@2x.png": (120, 120),
    "Icon-App-60x60@3x.png": (180, 180),
    "Icon-App-76x76@1x.png": (76, 76),
    "Icon-App-76x76@2x.png": (152, 152),
    "Icon-App-83.5x83.5@2x.png": (167, 167),
    "Icon-App-1024x1024@1x.png": (1024, 1024),
}
for name, size in ios_sizes.items():
    dest = os.path.join(ios_dir, name)
    resized = im.resize(size, Image.Resampling.LANCZOS)
    resized.save(dest, format="PNG")
    print(f"Saved {dest} ({size[0]}x{size[1]})")

# 3. Android res mipmap
android_res = os.path.join(repo_dir, "android", "app", "src", "main", "res")
android_sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}
for folder, size in android_sizes.items():
    dest = os.path.join(android_res, folder, "ic_launcher.png")
    resized = im.resize(size, Image.Resampling.LANCZOS)
    resized.save(dest, format="PNG")
    print(f"Saved {dest} ({size[0]}x{size[1]})")

# 4. Windows app_icon.ico
windows_ico = os.path.join(repo_dir, "windows", "runner", "resources", "app_icon.ico")
ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
im.save(windows_ico, format="ICO", sizes=ico_sizes)
print(f"Saved {windows_ico}")
