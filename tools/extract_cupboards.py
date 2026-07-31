"""Extract individual cupboards from reference sheets; black/checker → transparent."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "images" / "premium" / "cupboards"
OUT.mkdir(parents=True, exist_ok=True)

ASSETS = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
)

IMG1 = ASSETS / (
    "c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    "74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    "04_05_23_PM-d1060724-8bb1-4674-bfbf-145f715f1995.png"
)
IMG2 = ASSETS / (
    "c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    "74e53c8cdb72892f45b6cabc4b1f3afb_images_cupboard-"
    "9cb3f83d-dcff-44bf-abc6-fa56a6fc80ff.png"
)
IMG3 = ASSETS / (
    "c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    "74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    "04_07_15_PM-cbca3b4d-46f2-4fb2-b660-3903acfd3541.png"
)


def to_transparent(img: Image.Image, mode: str = "black") -> Image.Image:
    """Remove solid black or checkerboard background."""
    rgba = img.convert("RGBA")
    a = np.array(rgba)
    r, g, b = a[:, :, 0].astype(int), a[:, :, 1].astype(int), a[:, :, 2].astype(int)

    if mode == "black":
        # near-black bg
        kill = (r < 28) & (g < 28) & (b < 28)
    else:
        # checkerboard: near-white OR mid-gray squares
        kill = ((r > 210) & (g > 210) & (b > 210)) | (
            (np.abs(r - 180) < 35) & (np.abs(g - 180) < 35) & (np.abs(b - 180) < 35)
            & (np.abs(r.astype(int) - g.astype(int)) < 15)
        )
        # also pure white-ish
        kill |= (r > 230) & (g > 230) & (b > 230)

    # protect wood (warm brown)
    wood = (r > 80) & (g > 40) & (b < 160) & ((r - b) > 25)
    kill = kill & ~wood

    out = a.copy()
    out[kill, 3] = 0
    img2 = Image.fromarray(out, "RGBA")
    bbox = img2.getbbox()
    if bbox:
        img2 = img2.crop(bbox)
    return img2


def save_cupboard(img: Image.Image, name: str, rows: int, cols: int) -> None:
    # Upscale a bit for retina if small
    w, h = img.size
    if max(w, h) < 600:
        scale = 600 / max(w, h)
        img = img.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
    path = OUT / f"{name}.png"
    img.save(path, optimize=True)
    img.save(OUT / f"{name}.webp", "WEBP", quality=92)
    print(f"saved {name} {img.size} ({rows}x{cols})")


def find_blobs(mask: np.ndarray) -> list[tuple[int, int, int, int]]:
    """Return bounding boxes of connected True components."""
    from collections import deque

    h, w = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    boxes = []
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or visited[y, x]:
                continue
            q = deque([(y, x)])
            visited[y, x] = True
            ys, xs = [y], [x]
            while q:
                cy, cx = q.popleft()
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = cy + dy, cx + dx
                    if (
                        0 <= ny < h
                        and 0 <= nx < w
                        and mask[ny, nx]
                        and not visited[ny, nx]
                    ):
                        visited[ny, nx] = True
                        q.append((ny, nx))
                        ys.append(ny)
                        xs.append(nx)
            y0, y1 = min(ys), max(ys)
            x0, x1 = min(xs), max(xs)
            area = (y1 - y0 + 1) * (x1 - x0 + 1)
            if area > 2000:
                boxes.append((x0, y0, x1 + 1, y1 + 1))
    boxes.sort(key=lambda b: (b[1], b[0]))
    return boxes


def wood_mask(arr: np.ndarray) -> np.ndarray:
    r, g, b = arr[:, :, 0].astype(int), arr[:, :, 1].astype(int), arr[:, :, 2].astype(int)
    return (r > 70) & (g > 35) & ((r - b) > 20) & (r > g - 10)


def extract_auto(path: Path, mode: str, names: list[tuple[str, int, int]]) -> None:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    mask = wood_mask(arr)
    # dilate a bit
    from PIL import ImageFilter

    mimg = Image.fromarray((mask * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(5)
    )
    mask = np.array(mimg) > 128
    boxes = find_blobs(mask)
    print(f"{path.name}: found {len(boxes)} blobs, expect {len(names)}")
    # Match by area descending to assign large/small
    boxes_by_area = sorted(
        boxes, key=lambda b: (b[2] - b[0]) * (b[3] - b[1]), reverse=True
    )
    # Assign names by expected relative size order in names list (already sized)
    # Sort names by rows*cols descending to match boxes_by_area
    named = sorted(names, key=lambda n: n[1] * n[2], reverse=True)
    for box, (name, rows, cols) in zip(boxes_by_area, named):
        pad = 4
        x0, y0, x1, y1 = box
        crop = im.crop(
            (
                max(0, x0 - pad),
                max(0, y0 - pad),
                min(im.width, x1 + pad),
                min(im.height, y1 + pad),
            )
        )
        cut = to_transparent(crop, mode=mode)
        # If still messy, rembg
        a = np.array(cut)
        if (a[:, :, 3] > 10).mean() > 0.95:
            cut = remove(crop.convert("RGBA"))
            cut = to_transparent(cut, mode=mode)
            bbox = cut.getbbox()
            if bbox:
                cut = cut.crop(bbox)
        save_cupboard(cut, name, rows, cols)


def extract_manual(
    path: Path,
    crops: list[tuple[str, int, int, tuple[float, float, float, float]]],
    mode: str,
) -> None:
    """crops: name, rows, cols, (left, top, right, bottom) as fractions 0-1."""
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    for name, rows, cols, (l, t, r, b) in crops:
        crop = im.crop((int(l * w), int(t * h), int(r * w), int(b * h)))
        cut = to_transparent(crop, mode=mode)
        bbox = cut.getbbox()
        if bbox:
            cut = cut.crop(bbox)
        # If alpha almost full, try rembg
        if (np.array(cut)[:, :, 3] > 10).mean() > 0.92:
            cut = remove(crop)
            bbox = cut.getbbox()
            if bbox:
                cut = cut.crop(bbox)
        save_cupboard(cut, name, rows, cols)


def main() -> None:
    # Image 1: black bg — small 1x2 top, large 5x3 bottom
    extract_manual(
        IMG1,
        [
            ("cupboard_1x2_a", 1, 2, (0.18, 0.02, 0.82, 0.28)),
            ("cupboard_5x3", 5, 3, (0.12, 0.30, 0.88, 0.98)),
        ],
        mode="black",
    )

    # Image 2: black bg — full 4x7
    extract_manual(
        IMG2,
        [
            ("cupboard_7x4", 7, 4, (0.05, 0.02, 0.95, 0.98)),
        ],
        mode="black",
    )

    # Image 3: checkerboard — 1x2, 2x3, 8x4
    # Probe size first
    im3 = Image.open(IMG3)
    print("img3 size", im3.size)
    extract_auto(
        IMG3,
        mode="checker",
        names=[
            ("cupboard_1x2", 1, 2),
            ("cupboard_2x3", 2, 3),
            ("cupboard_8x4", 8, 4),
        ],
    )

    print("done ->", OUT)


if __name__ == "__main__":
    main()
