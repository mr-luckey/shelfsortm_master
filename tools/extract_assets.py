"""Extract transparent toy + UI assets from the reference screenshot."""
from __future__ import annotations

import json
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
    # row 0
    "teddy",
    "duck",
    "frog",
    "rocket",
    # row 1
    "rabbit",
    "panda",
    "cat",
    "owl",
    # row 2
    "heart",
    "football",
    "star",
    "penguin",
    # row 3
    "cactus",
    "grapes",
    "apple",
    "rainbow_rings",
    # row 4
    "car",
    "chick",
    "pig",
    "whale",
    # row 5
    "unicorn",
    "dinosaur",
    "burger",
    "fries",
    # row 6
    "sunglasses",
    "ice_cream",
    "dice",
    "robot",
    # row 7
    "basketball",
    "flower",
    "octopus",
    "bee",
]


def is_wood(r: int, g: int, b: int) -> bool:
    return (
        r > 145
        and g > 95
        and b > 55
        and r >= g
        and g >= b - 10
        and (r - b) > 35
        and (r - g) < 90
    )


def longest_run(mask: np.ndarray, thresh: float) -> tuple[int, int]:
    m = mask > thresh
    best = (0, 0)
    start = None
    n = len(m)
    for i, on in enumerate(m):
        if on and start is None:
            start = i
        if (not on or i == n - 1) and start is not None:
            end = i if not on else i
            if end - start > best[1] - best[0]:
                best = (start, end)
            start = None
    return best


def detect_cupboard(arr: np.ndarray) -> tuple[int, int, int, int]:
    h, w = arr.shape[:2]
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    wood = (
        (r > 145)
        & (g > 95)
        & (b > 55)
        & (r >= g)
        & ((r.astype(int) - b.astype(int)) > 35)
    )
    y0, y1 = longest_run(wood.mean(axis=1), 0.22)
    band = wood[y0:y1, :]
    x0, x1 = longest_run(band.mean(axis=0), 0.18)
    # shrink inward past thick outer frame a bit for cell crop
    return x0, y0, x1, y1


def remove_wood_bg(cell: Image.Image) -> Image.Image:
    """Make wood-colored pixels transparent; keep colorful toys."""
    rgba = cell.convert("RGBA")
    arr = np.array(rgba)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    wood = (
        (r > 140)
        & (g > 90)
        & (b > 50)
        & (r.astype(int) - b.astype(int) > 30)
        & (np.abs(r.astype(int) - g.astype(int)) < 85)
        & ((r.astype(int) - g.astype(int)) > -5)
    )
    # also kill near-white shelf highlights that are still wood-ish
    pale_wood = (r > 200) & (g > 170) & (b > 130) & ((r.astype(int) - b.astype(int)) > 25)
    kill = wood | pale_wood

    # keep strongly saturated / non-wood colors
    sat = np.maximum(np.maximum(r, g), b).astype(int) - np.minimum(
        np.minimum(r, g), b
    ).astype(int)
    colorful = sat > 35
    # protect colorful pixels even if wood-ish heuristically
    kill = kill & ~colorful

    # flood from edges: anything connected to edge via kill-ish becomes transparent
    h, w = kill.shape
    edge = np.zeros_like(kill, dtype=bool)
    edge[0, :] = True
    edge[-1, :] = True
    edge[:, 0] = True
    edge[:, -1] = True
    # soft kill near edges for wood
    soft = kill | ((r > 180) & (g > 140) & (b > 100) & ((r.astype(int) - b.astype(int)) > 20))

    from collections import deque

    visited = np.zeros_like(soft, dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for y in range(h):
        for x in (0, w - 1):
            if soft[y, x]:
                q.append((y, x))
                visited[y, x] = True
    for x in range(w):
        for y in (0, h - 1):
            if soft[y, x] and not visited[y, x]:
                q.append((y, x))
                visited[y, x] = True
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and soft[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    alpha = a.copy()
    alpha[visited] = 0
    # soft edge: lower alpha for near-wood remaining edge pixels
    near = soft & ~visited
    alpha[near] = (alpha[near].astype(np.float32) * 0.35).astype(np.uint8)

    out = arr.copy()
    out[:, :, 3] = alpha
    img = Image.fromarray(out, "RGBA")
    # trim transparent
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    return img


def extract_center_item(cell: Image.Image) -> Image.Image:
    """Each cubby has 3 identical toys — crop the center one for a clean asset."""
    w, h = cell.size
    # center third horizontally, slightly upper vertically (toys sit on shelf)
    cx0 = int(w * 0.30)
    cx1 = int(w * 0.70)
    cy0 = int(h * 0.08)
    cy1 = int(h * 0.92)
    return cell.crop((cx0, cy0, cx1, cy1))


def main() -> None:
    TOYS.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)

    im = Image.open(SRC).convert("RGB")
    arr = np.array(im)
    x0, y0, x1, y1 = detect_cupboard(arr)
    print(f"cupboard bbox: ({x0},{y0})-({x1},{y1}) size={x1-x0}x{y1-y0}")

    # Save room background (blurred full frame without cupboard center)
    bg = im.copy()
    # darken/blur for depth
    bg_blur = bg.filter(ImageFilter.GaussianBlur(radius=6))
    bg_blur.save(UI / "room_background.png", optimize=True)
    print("saved room_background.png")

    # Empty cupboard crop (full cupboard region)
    cupboard = im.crop((x0, y0, x1, y1))
    cupboard.save(UI / "cupboard_full.png", optimize=True)

    # Inner grid (shrink past outer frame ~6%)
    fw = int((x1 - x0) * 0.055)
    fh = int((y1 - y0) * 0.045)
    ix0, iy0, ix1, iy1 = x0 + fw, y0 + fh, x1 - fw, y1 - fh
    print(f"inner grid: ({ix0},{iy0})-({ix1},{iy1})")

    cols, rows = 4, 8
    cell_w = (ix1 - ix0) / cols
    cell_h = (iy1 - iy0) / rows

    meta = {"cupboard": [x0, y0, x1, y1], "inner": [ix0, iy0, ix1, iy1], "toys": {}}

    for i, name in enumerate(TOY_NAMES):
        r, c = divmod(i, cols) if False else (i // cols, i % cols)
        # inset each cell to avoid wood dividers
        inset_x = cell_w * 0.08
        inset_y = cell_h * 0.08
        left = int(ix0 + c * cell_w + inset_x)
        top = int(iy0 + r * cell_h + inset_y)
        right = int(ix0 + (c + 1) * cell_w - inset_x)
        bottom = int(iy0 + (r + 1) * cell_h - inset_y)
        cell = im.crop((left, top, right, bottom))
        center = extract_center_item(cell)
        cut = remove_wood_bg(center)
        # upscale 2x for retina
        cut = cut.resize((cut.width * 2, cut.height * 2), Image.Resampling.LANCZOS)
        out_path = TOYS / f"{name}.png"
        cut.save(out_path, optimize=True)
        meta["toys"][name] = {
            "file": f"toys/{name}.png",
            "size": list(cut.size),
            "cell": [left, top, right, bottom],
        }
        print(f"  {name}: {cut.size} alpha_ratio={_alpha_ratio(cut):.2f}")

    # Goal panel region (above cupboard)
    goal_y1 = max(0, y0 - 4)
    goal_y0 = max(0, goal_y1 - 90)
    goal = im.crop((20, goal_y0, im.width - 20, goal_y1))
    goal.save(UI / "goal_panel_ref.png", optimize=True)

    # HUD strip
    hud = im.crop((8, 8, im.width - 8, min(90, goal_y0)))
    hud.save(UI / "hud_ref.png", optimize=True)

    # Toolbar strip
    tool_y0 = min(im.height - 10, y1 + 4)
    tool = im.crop((8, tool_y0, im.width - 8, im.height - 4))
    tool.save(UI / "toolbar_ref.png", optimize=True)

    (OUT / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print("done ->", OUT)


def _alpha_ratio(img: Image.Image) -> float:
    a = np.array(img.split()[-1])
    return float((a > 10).mean())


if __name__ == "__main__":
    main()
