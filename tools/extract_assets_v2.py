"""Detect accurate cupboard grid and extract toys."""
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


def is_wood_px(r, g, b) -> bool:
    ri, gi, bi = int(r), int(g), int(b)
    return (
        ri > 160
        and gi > 100
        and bi > 40
        and (ri - bi) > 50
        and abs(ri - gi) < 100
        and gi > bi
    )


def main() -> None:
    TOYS.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)

    im = Image.open(SRC).convert("RGB")
    arr = np.array(im)
    h, w = arr.shape[:2]

    # Manual refined bounds from color probe:
    # cupboard wood dominant from ~y=195..885, x ~40..445
    y0, y1 = 195, 885
    # find x bounds where wood density is high on a mid row slice
    mid = arr[400:700, :]
    r, g, b = mid[:, :, 0], mid[:, :, 1], mid[:, :, 2]
    wood = (
        (r > 160)
        & (g > 100)
        & (b > 40)
        & ((r.astype(int) - b.astype(int)) > 50)
        & (g > b)
    )
    col = wood.mean(axis=0)
    xs = np.where(col > 0.35)[0]
    x0, x1 = int(xs[0]), int(xs[-1])
    print(f"cupboard ({x0},{y0})-({x1},{y1}) = {x1-x0}x{y1-y0}")

    # Outer frame is thick ~8% of width
    fw = int((x1 - x0) * 0.07)
    fh = int((y1 - y0) * 0.035)
    ix0, iy0 = x0 + fw, y0 + fh
    ix1, iy1 = x1 - fw, y1 - fh
    print(f"inner ({ix0},{iy0})-({ix1},{iy1})")

    # Draw debug grid
    dbg = im.copy()
    from PIL import ImageDraw

    draw = ImageDraw.Draw(dbg)
    draw.rectangle([x0, y0, x1, y1], outline=(0, 255, 0), width=2)
    draw.rectangle([ix0, iy0, ix1, iy1], outline=(255, 0, 0), width=2)
    cols, rows = 4, 8
    cw = (ix1 - ix0) / cols
    ch = (iy1 - iy0) / rows
    for c in range(cols + 1):
        x = int(ix0 + c * cw)
        draw.line([(x, iy0), (x, iy1)], fill=(0, 200, 255), width=1)
    for r in range(rows + 1):
        y = int(iy0 + r * ch)
        draw.line([(ix0, y), (ix1, y)], fill=(0, 200, 255), width=1)
    dbg.save(UI / "grid_debug.png")
    print("wrote grid_debug.png")

    # Room background: full image with cupboard area blurred/dimmed isn't needed —
    # save cropped room sides + full blurred scene
    room = im.filter(ImageFilter.GaussianBlur(4))
    room.save(UI / "room_background.png", optimize=True)

    # Full cupboard reference
    im.crop((x0, y0, x1, y1)).save(UI / "cupboard_full.png")

    meta = {"cupboard": [x0, y0, x1, y1], "inner": [ix0, iy0, ix1, iy1], "toys": {}}

    for i, name in enumerate(TOY_NAMES):
        rr, cc = i // cols, i % cols
        # inset to avoid dividers
        inset_x = cw * 0.10
        inset_y = ch * 0.10
        left = int(ix0 + cc * cw + inset_x)
        top = int(iy0 + rr * ch + inset_y)
        right = int(ix0 + (cc + 1) * cw - inset_x)
        bottom = int(iy0 + (rr + 1) * ch - inset_y)
        cell = im.crop((left, top, right, bottom))
        cell.save(TOYS / f"_cell_{name}.png")  # raw cell for QC

        # Take center toy (middle of 3)
        cw_px, ch_px = cell.size
        center = cell.crop(
            (
                int(cw_px * 0.30),
                int(ch_px * 0.05),
                int(cw_px * 0.70),
                int(ch_px * 0.95),
            )
        )
        cut = remove_bg(center)
        # pad to square and upscale
        cut = pad_square(cut)
        cut = cut.resize((cut.width * 3, cut.height * 3), Image.Resampling.LANCZOS)
        out_path = TOYS / f"{name}.png"
        cut.save(out_path, optimize=True)
        ar = alpha_ratio(cut)
        meta["toys"][name] = {"size": list(cut.size), "alpha": round(ar, 3)}
        print(f"{name:14s} {cut.size} alpha={ar:.2f}")

    # Extract gift from goal panel (~right side y=100-170)
    gift = im.crop((380, 100, 460, 175))
    gift_t = remove_bg(gift, wood_only=False)
    gift_t = pad_square(gift_t).resize((192, 192), Image.Resampling.LANCZOS)
    gift_t.save(UI / "gift_box.png")

    # Coin icon from HUD (~x=55-90, y=35-70) — approximate
    # Better: generate simple later; try crop near left currency
    coin = im.crop((55, 38, 95, 78))
    coin_t = remove_bg(coin, wood_only=False)
    coin_t = pad_square(coin_t).resize((96, 96), Image.Resampling.LANCZOS)
    coin_t.save(UI / "coin.png")

    gem = im.crop((320, 38, 360, 78))
    gem_t = remove_bg(gem, wood_only=False)
    gem_t = pad_square(gem_t).resize((96, 96), Image.Resampling.LANCZOS)
    gem_t.save(UI / "gem.png")

    (OUT / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print("done")


def remove_bg(cell: Image.Image, wood_only: bool = True) -> Image.Image:
    rgba = cell.convert("RGBA")
    a = np.array(rgba)
    r, g, b = a[:, :, 0].astype(int), a[:, :, 1].astype(int), a[:, :, 2].astype(int)

    if wood_only:
        soft = (
            (r > 145)
            & (g > 95)
            & (b > 45)
            & ((r - b) > 35)
            & (np.abs(r - g) < 90)
            & (g > b - 15)
        )
        # pale shelf
        soft |= (r > 200) & (g > 165) & (b > 120) & ((r - b) > 25)
    else:
        # for UI icons: remove near-background (cream/blue)
        soft = (r > 220) & (g > 220) & (b > 220)
        soft |= (r > 200) & (g > 180) & (b > 150) & ((r - b) < 60)  # cream
        soft |= (b > r + 20) & (b > g + 10) & (b > 80) & (r < 120)  # blue hud

    # Don't kill highly saturated pixels (toys)
    sat = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    # for brown teddy, sat can be low — so don't overprotect
    colorful = sat > 55
    soft = soft & ~colorful

    h, w = soft.shape
    visited = np.zeros_like(soft, dtype=bool)
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

    out = a.copy()
    out[visited, 3] = 0
    # feather near soft remaining
    near = soft & ~visited
    out[near, 3] = (out[near, 3].astype(np.float32) * 0.4).astype(np.uint8)

    img = Image.fromarray(out, "RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    return img


def pad_square(img: Image.Image, pad_frac: float = 0.08) -> Image.Image:
    w, h = img.size
    side = max(w, h)
    pad = int(side * pad_frac)
    side += pad * 2
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas


def alpha_ratio(img: Image.Image) -> float:
    a = np.array(img.split()[-1])
    return float((a > 10).mean())


if __name__ == "__main__":
    main()
