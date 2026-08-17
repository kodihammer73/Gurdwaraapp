"""
Generate saffron Gurdwara iOS app icons from translogo.png.

Creates a saffron (#E8A838) background and composites the transparent
logo on top, then generates all required iOS icon sizes.
"""
import os
from PIL import Image

# Paths
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(BASE, "web", "translogo.png")
OUTPUT_DIR = os.path.join(BASE, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

# Saffron brand color
SAFFRON = (232, 168, 56, 255)  # #E8A838

# Required iOS icon sizes: (filename, pixel_size)
ICON_SIZES = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-50x50@1x.png", 50),
    ("Icon-App-50x50@2x.png", 100),
    ("Icon-App-57x57@1x.png", 57),
    ("Icon-App-57x57@2x.png", 114),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-72x72@1x.png", 72),
    ("Icon-App-72x72@2x.png", 144),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

def generate_icon(source_img, size):
    """Create a saffron-background icon with the logo composited on top."""
    # Create saffron background
    bg = Image.new("RGBA", (size, size), SAFFRON)

    # Resize the logo to fit within the icon (with some padding)
    # iOS icons typically have the logo at ~80% of the icon size
    logo_size = int(size * 0.8)
    logo = source_img.copy()
    logo.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)


    # Center the logo on the background
    x = (size - logo.width) // 2
    y = (size - logo.height) // 2
    bg.paste(logo, (x, y), logo)

    # Convert to RGB (no alpha for iOS icons)
    return bg.convert("RGB")

def main():
    if not os.path.exists(SOURCE):
        print(f"ERROR: Source image not found: {SOURCE}")
        return

    source_img = Image.open(SOURCE)
    print(f"Source: {source_img.size} {source_img.mode}")

    if not os.path.exists(OUTPUT_DIR):
        print(f"ERROR: Output dir not found: {OUTPUT_DIR}")
        return

    for filename, size in ICON_SIZES:
        icon = generate_icon(source_img, size)
        out_path = os.path.join(OUTPUT_DIR, filename)
        icon.save(out_path, "PNG")
        print(f"  Generated {filename} ({size}x{size})")

    print("\nAll iOS icons generated successfully!")

if __name__ == "__main__":
    main()
