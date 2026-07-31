"""Extract toys with rembg AI cutout."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
    r"\c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    r"02_28_04_PM-b9251620-f868-4e91-8361-6e367be5da9f.png"
)
OUT = ROOT / "assets" / "images" / "premium"
TOYS = OUT / "toys"
UI = OUT / "ui"

TOY_NAMES = [
    "teddy", "duck", "frog", "rocket",
    "rabbit", "panda", "cat", "owl",
    "heart", "football", "star", "penguin",
    "cactus", "grapes", "apple", "rainbow_rings",
    "car", "chick", "pig", "whale",
    "unicorn", "dinosaur", "burger", "fries",
    "sunglasses", "ice_cream", "dice", "robot",
    "basketball", "flower", "octopus", "bee",
]


def trim_square(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    img = img.crop(bbox)
    w, h = img.size
    side = int(max(w, h) * 1.1)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas


def main() -> None:
    TOYS.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)

    im = Image.open(SRC).convert("RGB")
    x0, y0, x1, y1 = 7, 195, 477, 885
    fw = int((x1 - x0) * 0.07)
    fh = int((y1 - y0) * 0.035)
    ix0, iy0 = x0 + fw, y0 + fh
    ix1, iy1 = x1 - fw, y1 - fh
    cols, rows = 4, 8
    cw = (ix1 - ix0) / cols
    ch = (iy1 - iy0) / rows

    # Room background: blur full scene
    im.filter(ImageFilter.GaussianBlur(10)).save(UI / "room_background.png", optimize=True)

    # Empty cupboard frame from original (full cupboard crop) — Flutter paints empty cubbies
    im.crop((x0, y0, x1, y1)).save(UI / "cupboard_ref.png", optimize=True)

    meta = {}
    for i, name in enumerate(TOY_NAMES):
        rr, cc = i // cols, i % cols
        left = int(ix0 + cc * cw + cw * 0.05)
        top = int(iy0 + rr * ch + ch * 0.06)
        right = int(ix0 + (cc + 1) * cw - cw * 0.05)
        bottom = int(iy0 + (rr + 1) * ch - ch * 0.05)
        cell = im.crop((left, top, right, bottom))
        w, h = cell.size
        # Center toy only — slightly wider than 1/3 to avoid cutting ears
        mid = cell.crop((int(w * 0.32), int(h * 0.0), int(w * 0.68), int(h * 0.95)))
        # Upscale before rembg for better edges
        mid_up = mid.resize((mid.width * 4, mid.height * 4), Image.Resampling.LANCZOS)
        cut = remove(mid_up)
        cut = trim_square(cut).resize((256, 256), Image.Resampling.LANCZOS)
        cut.save(TOYS / f"{name}.png", optimize=True)
        cut.save(TOYS / f"{name}.webp", "WEBP", quality=92)
        print(f"ok {name}")
        meta[name] = f"toys/{name}.png"

    # Gift
    gift_src = im.crop((400, 108, 460, 172)).resize((240, 256), Image.Resampling.LANCZOS)
    gift = trim_square(remove(gift_src)).resize((192, 192), Image.Resampling.LANCZOS)
    gift.save(UI / "gift_box.png")
    gift.save(UI / "gift_box.webp", "WEBP", quality=92)

    # Coin (approx HUD)
    coin_src = im.crop((52, 40, 92, 78)).resize((160, 152), Image.Resampling.LANCZOS)
    coin = trim_square(remove(coin_src)).resize((96, 96), Image.Resampling.LANCZOS)
    coin.save(UI / "coin.png")

    gem_src = im.crop((318, 40, 358, 78)).resize((160, 152), Image.Resampling.LANCZOS)
    gem = trim_square(remove(gem_src)).resize((96, 96), Image.Resampling.LANCZOS)
    gem.save(UI / "gem.png")

    (OUT / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print("ALL DONE")


if __name__ == "__main__":
    main()
