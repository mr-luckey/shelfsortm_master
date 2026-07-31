"""Final rembg pass: wider center crop + alpha verify."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
    r"\c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    r"02_28_04_PM-b9251620-f868-4e91-8361-6e367be5da9f.png"
)
TOYS = ROOT / "assets" / "images" / "premium" / "toys"
UI = ROOT / "assets" / "images" / "premium" / "ui"

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
    a = np.array(img)
    alpha = a[:, :, 3]
    ys, xs = np.where(alpha > 20)
    if len(xs) == 0:
        return Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    img = img.crop((x0, y0, x1 + 1, y1 + 1))
    w, h = img.size
    side = int(max(w, h) * 1.08)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas


def pick_center_blob(img: Image.Image) -> Image.Image:
    """Keep the alpha blob closest to horizontal center."""
    a = np.array(img)
    alpha = a[:, :, 3] > 20
    h, w = alpha.shape
    # Label connected components (4-connected)
    labels = np.zeros_like(alpha, dtype=np.int32)
    label = 0
    from collections import deque

    for y in range(h):
        for x in range(w):
            if alpha[y, x] and labels[y, x] == 0:
                label += 1
                q = deque([(y, x)])
                labels[y, x] = label
                while q:
                    cy, cx = q.popleft()
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if (
                            0 <= ny < h
                            and 0 <= nx < w
                            and alpha[ny, nx]
                            and labels[ny, nx] == 0
                        ):
                            labels[ny, nx] = label
                            q.append((ny, nx))

    if label == 0:
        return img

    best_id, best_score = 1, 1e18
    for lid in range(1, label + 1):
        ys, xs = np.where(labels == lid)
        area = len(xs)
        if area < (h * w) * 0.02:
            continue
        cx = xs.mean()
        score = abs(cx - w / 2) - area * 0.01  # prefer centered + large
        if score < best_score:
            best_score = score
            best_id = lid

    mask = labels == best_id
    out = a.copy()
    out[~mask, 3] = 0
    return Image.fromarray(out, "RGBA")


def main() -> None:
    im = Image.open(SRC).convert("RGB")
    x0, y0, x1, y1 = 7, 195, 477, 885
    fw = int((x1 - x0) * 0.07)
    fh = int((y1 - y0) * 0.035)
    ix0, iy0 = x0 + fw, y0 + fh
    ix1, iy1 = x1 - fw, y1 - fh
    cols = 4
    cw = (ix1 - ix0) / cols
    ch = (iy1 - iy0) / 8

    for i, name in enumerate(TOY_NAMES):
        rr, cc = i // cols, i % cols
        left = int(ix0 + cc * cw + cw * 0.04)
        top = int(iy0 + rr * ch + ch * 0.05)
        right = int(ix0 + (cc + 1) * cw - cw * 0.04)
        bottom = int(iy0 + (rr + 1) * ch - ch * 0.04)
        cell = im.crop((left, top, right, bottom))
        w, h = cell.size

        # Middle toy with padding — about 28%–72%
        mid = cell.crop((int(w * 0.28), int(h * 0.0), int(w * 0.72), int(h * 0.98)))
        mid_up = mid.resize((mid.width * 3, mid.height * 3), Image.Resampling.LANCZOS)
        cut = remove(mid_up)
        cut = pick_center_blob(cut)
        cut = trim_square(cut).resize((256, 256), Image.Resampling.LANCZOS)

        # Force true transparency (replace near-black leftover bg)
        arr = np.array(cut)
        # already has alpha from rembg; just save
        Image.fromarray(arr, "RGBA").save(TOYS / f"{name}.png", optimize=True)
        Image.fromarray(arr, "RGBA").save(TOYS / f"{name}.webp", "WEBP", quality=92)
        ar = float((arr[:, :, 3] > 10).mean())
        print(f"{name:14s} alpha={ar:.2f} nonblack={float(((arr[:,:,0]+arr[:,:,1]+arr[:,:,2])>30).mean()):.2f}")

    # Gift — crop tighter around the box only
    gift_src = im.crop((405, 115, 455, 170)).resize((200, 220), Image.Resampling.LANCZOS)
    gift = trim_square(remove(gift_src)).resize((192, 192), Image.Resampling.LANCZOS)
    gift.save(UI / "gift_box.png")
    gift.save(UI / "gift_box.webp", "WEBP", quality=92)
    print("gift ok")

    # Cleanup intermediate cell dumps
    for p in TOYS.glob("_cell_*.png"):
        p.unlink()
    print("DONE")


if __name__ == "__main__":
    main()
