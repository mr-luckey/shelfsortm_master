"""V3: tight center crop + dark-cubby + light-wood bg removal."""
from __future__ import annotations

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

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


def main() -> None:
    TOYS.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)

    im = Image.open(SRC).convert("RGB")
    # bounds from v2 (validated by grid_debug)
    x0, y0, x1, y1 = 7, 195, 477, 885
    fw = int((x1 - x0) * 0.07)
    fh = int((y1 - y0) * 0.035)
    ix0, iy0 = x0 + fw, y0 + fh
    ix1, iy1 = x1 - fw, y1 - fh

    cols, rows = 4, 8
    cw = (ix1 - ix0) / cols
    ch = (iy1 - iy0) / rows
    meta: dict = {"toys": {}}

    # Empty cupboard: paint over toys with wood color by inpainting from frame
    empty = build_empty_cupboard(im, ix0, iy0, ix1, iy1, cols, rows)
    empty.save(UI / "cupboard_empty.png", optimize=True)

    # Room bg = full screenshot blurred (UI chrome soft)
    im.filter(ImageFilter.GaussianBlur(8)).save(UI / "room_background.png", optimize=True)

    for i, name in enumerate(TOY_NAMES):
        rr, cc = i // cols, i % cols
        # Full cubby with small inset for wood dividers
        left = int(ix0 + cc * cw + cw * 0.06)
        top = int(iy0 + rr * ch + ch * 0.08)
        right = int(ix0 + (cc + 1) * cw - cw * 0.06)
        bottom = int(iy0 + (rr + 1) * ch - ch * 0.06)
        cell = im.crop((left, top, right, bottom))

        # STRICT middle third — single toy
        w, h = cell.size
        mid = cell.crop(
            (
                int(w * 0.34),
                int(h * 0.02),
                int(w * 0.66),
                int(h * 0.92),
            )
        )
        cut = cutout(mid)
        cut = trim_and_square(cut)
        # Retina 256
        cut = cut.resize((256, 256), Image.Resampling.LANCZOS)
        cut.save(TOYS / f"{name}.png", optimize=True)
        # also webp
        cut.save(TOYS / f"{name}.webp", "WEBP", quality=90)
        ar = float((np.array(cut.split()[-1]) > 8).mean())
        meta["toys"][name] = {"alpha": round(ar, 3), "size": [256, 256]}
        print(f"{name:14s} alpha={ar:.2f}")

    # Gift from goal reward area
    gift = cutout(im.crop((395, 105, 465, 175)), ui_mode=True)
    gift = trim_and_square(gift).resize((192, 192), Image.Resampling.LANCZOS)
    gift.save(UI / "gift_box.png")
    gift.save(UI / "gift_box.webp", "WEBP", quality=90)

    (OUT / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print("done", OUT)


def cutout(img: Image.Image, ui_mode: bool = False) -> Image.Image:
    rgba = img.convert("RGBA")
    a = np.array(rgba).astype(np.int16)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    h, w = r.shape

    # Sample corner colors as bg seeds
    corners = [
        a[2, 2, :3],
        a[2, w - 3, :3],
        a[h - 3, 2, :3],
        a[h - 3, w - 3, :3],
        a[2, w // 2, :3],
        a[h - 3, w // 2, :3],
    ]

    # Distance to nearest corner color
    dist = np.full((h, w), 9999.0)
    for c in corners:
        d = np.sqrt(
            (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2
        ).astype(np.float32)
        dist = np.minimum(dist, d)

    # Also classify classic dark cubby + light wood
    dark_cubby = (r + g + b < 160) & (r >= g) & (r > b) & ((r - b) > 15)
    light_wood = (
        (r > 170)
        & (g > 110)
        & (b > 50)
        & ((r - b) > 45)
        & (np.abs(r - g) < 80)
    )
    if ui_mode:
        cream = (r > 210) & (g > 200) & (b > 180)
        blue = (b > r + 15) & (b > 90)
        soft = (dist < 38) | cream | blue
    else:
        soft = (dist < 42) | dark_cubby | light_wood

    # Protect saturated / bright toy pixels
    sat = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    bright = np.maximum(np.maximum(r, g), b)
    protect = (sat > 45) | ((bright > 190) & (sat > 25))
    # brown teddy: protect mid-luma brown that's NOT dark cubby and NOT light wood
    mid_brown = (
        (r > 120)
        & (r < 210)
        & (g > 70)
        & (g < 170)
        & ((r - b) > 40)
        & ~dark_cubby
        & ~light_wood
        & (dist > 28)
    )
    protect = protect | mid_brown
    soft = soft & ~protect

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for y in range(h):
        for x in (0, w - 1):
            if soft[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            if soft[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and soft[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    out = a.astype(np.uint8).copy()
    out[visited, 3] = 0
    # feather
    # erode protect edge slightly: pixels near visited with high dist stay
    near = soft & ~visited
    out[near, 3] = (out[near, 3].astype(np.float32) * 0.25).astype(np.uint8)

    return Image.fromarray(out, "RGBA")


def trim_and_square(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    img = img.crop(bbox)
    w, h = img.size
    side = int(max(w, h) * 1.12)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas


def build_empty_cupboard(
    im: Image.Image,
    ix0: int,
    iy0: int,
    ix1: int,
    iy1: int,
    cols: int,
    rows: int,
) -> Image.Image:
    """Return cupboard crop with cubbies filled by sampled wood (no toys)."""
    x0, y0, x1, y1 = 7, 195, 477, 885
    cup = im.crop((x0, y0, x1, y1)).convert("RGBA")
    arr = np.array(cup)
    # Relative inner
    rx0, ry0 = ix0 - x0, iy0 - y0
    rx1, ry1 = ix1 - x0, iy1 - y0
    cw = (rx1 - rx0) / cols
    ch = (ry1 - ry0) / rows

    # Sample wood color from frame
    wood_color = tuple(int(x) for x in arr[10, arr.shape[1] // 2, :3])
    dark_back = (90, 45, 20, 255)
    shelf_lip = (180, 120, 65, 255)

    from PIL import ImageDraw

    draw = ImageDraw.Draw(cup)
    for r in range(rows):
        for c in range(cols):
            left = int(rx0 + c * cw + 2)
            top = int(ry0 + r * ch + 2)
            right = int(rx0 + (c + 1) * cw - 2)
            bottom = int(ry0 + (r + 1) * ch - 2)
            # back panel
            draw.rectangle([left, top, right, bottom - 6], fill=dark_back)
            # shelf floor
            draw.rectangle([left, bottom - 8, right, bottom], fill=shelf_lip)
            # subtle inner highlight
            draw.rectangle(
                [left + 1, top + 1, right - 1, top + 4],
                fill=(120, 70, 35, 180),
            )
    # keep outer wood frame as-is from original (already there)
    return cup


if __name__ == "__main__":
    main()
