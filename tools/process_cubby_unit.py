"""Remove black BG from cubby image and crop tightly."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
    r"\c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    r"05_17_13_PM-15fa104e-6e28-45bf-b988-98661340b516.png"
)
OUT = ROOT / "assets" / "images" / "premium" / "cupboards" / "cubby_unit.png"


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    a = np.array(im)
    rgb = a[:, :, :3].astype(np.float32)
    lum = rgb.mean(axis=2)
    mx = rgb.max(axis=2)

    alpha = np.ones(lum.shape, dtype=np.float32)
    mask_bg = (lum < 18) & (mx < 28)
    soft = (lum < 40) & (mx < 55) & ~mask_bg
    alpha[mask_bg] = 0
    alpha[soft] = np.clip((lum[soft] - 12) / 28, 0, 1)
    a[:, :, 3] = (alpha * 255).astype(np.uint8)

    ys, xs = np.where(a[:, :, 3] > 12)
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    pad = 2
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(a.shape[1] - 1, x1 + pad)
    y1 = min(a.shape[0] - 1, y1 + pad)

    cropped = Image.fromarray(a).crop((x0, y0, x1 + 1, y1 + 1))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(OUT, optimize=True)
    webp = OUT.with_suffix(".webp")
    cropped.save(webp, "WEBP", quality=90, method=6)
    print("saved", OUT, cropped.size)
    print("png", OUT.stat().st_size, "webp", webp.stat().st_size)


if __name__ == "__main__":
    main()
