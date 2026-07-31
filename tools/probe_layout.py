"""Probe screenshot layout to find true cupboard bounds."""
from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(
    r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
    r"\c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Jul_30__2026__"
    r"02_28_04_PM-b9251620-f868-4e91-8361-6e367be5da9f.png"
)

im = Image.open(SRC).convert("RGB")
arr = np.array(im)
h, w = arr.shape[:2]
print("size", w, h)

# Sample every 20 rows at center and left/right thirds
for y in range(0, h, 20):
    c = tuple(arr[y, w // 2])
    l = tuple(arr[y, w // 4])
    r = tuple(arr[y, 3 * w // 4])
    print(f"y={y:4d} L={l} C={c} R={r}")

# Save a downscaled annotated grid for visual debug
out = Path("assets/images/premium/ui/probe.png")
out.parent.mkdir(parents=True, exist_ok=True)
# draw horizontal lines every 40px
dbg = im.copy()
from PIL import ImageDraw, ImageFont

draw = ImageDraw.Draw(dbg)
for y in range(0, h, 40):
    draw.line([(0, y), (w, y)], fill=(255, 0, 0), width=1)
    draw.text((2, y), str(y), fill=(255, 255, 0))
for x in range(0, w, 40):
    draw.line([(x, 0), (x, h)], fill=(0, 255, 0), width=1)
dbg.save(out)
print("wrote", out)
