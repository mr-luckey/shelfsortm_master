from PIL import Image
import os

src_dir = r"C:\Users\engin\.cursor\projects\d-Playstore-shelfsortm-master\assets"
out_dir = r"D:\Playstore\shelfsortm_master\assets\images\premium\ui"
os.makedirs(out_dir, exist_ok=True)

jobs = {
    "hud_plank_raw.png": "hud_plank.png",
    "settings_gear_raw.png": "settings_gear.png",
    "hourglass_raw.png": "hourglass.png",
    "level_shield_raw.png": "level_shield.png",
    "goal_board_raw.png": "goal_board.png",
    "ribbon_goal_raw.png": "ribbon_goal.png",
    "ribbon_reward_raw.png": "ribbon_reward.png",
    "gift_reward_raw.png": "gift_reward.png",
}


def chroma_key(img: Image.Image, thresh=90, soft=40):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            greenness = g - max(r, b)
            if greenness > thresh and g > 120:
                px[x, y] = (r, g, b, 0)
            elif greenness > thresh - soft and g > 80:
                alpha = int(max(0, 255 * (1 - (greenness - (thresh - soft)) / soft)))
                px[x, y] = (r, g, b, min(a, alpha))
    return img


def crop_alpha(img: Image.Image, pad=4):
    bbox = img.getbbox()
    if not bbox:
        return img
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(img.width, r + pad)
    b = min(img.height, b + pad)
    return img.crop((l, t, r, b))


for src_name, out_name in jobs.items():
    path = os.path.join(src_dir, src_name)
    if not os.path.exists(path):
        print("MISSING", path)
        continue
    img = Image.open(path)
    cut = chroma_key(img)
    cut = crop_alpha(cut)
    out = os.path.join(out_dir, out_name)
    cut.save(out, "PNG")
    print(f"{out_name}: {cut.size} -> {os.path.getsize(out)} bytes")

print("done")
