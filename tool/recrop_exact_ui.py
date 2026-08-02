"""Blank baked HUD digits and scrub booster badges more aggressively."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REF = Path(
    r"C:/Users/engin/.cursor/projects/d-Playstore-shelfsortm-master/assets/"
    r"c__Users_engin_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"74e53c8cdb72892f45b6cabc4b1f3afb_images_ChatGPT_Image_Aug_2__2026__"
    r"12_36_01_PM-6d7fef0c-9298-4e84-9260-50f5f4b1fc27.png"
)
OUT = Path(r"D:/Playstore/shelfsortm_master/assets/images/premium/ui")


def sample_avg(im: Image.Image, box: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    crop = im.crop(box)
    px = list(crop.getdata())
    n = len(px)
    r = sum(p[0] for p in px) // n
    g = sum(p[1] for p in px) // n
    b = sum(p[2] for p in px) // n
    a = sum(p[3] for p in px) // n if len(px[0]) == 4 else 255
    return (r, g, b, a)


def fill_rounded(im: Image.Image, box: tuple[int, int, int, int], color, radius: int = 6) -> None:
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=color)
    # Soft edges
    layer = layer.filter(ImageFilter.GaussianBlur(radius=0.8))
    im.alpha_composite(layer)


def extract_circle(ref: Image.Image, cx: float, cy: float, radius: float, size: int = 96) -> Image.Image:
    left = int(round(cx - radius))
    top = int(round(cy - radius))
    right = int(round(cx + radius))
    bottom = int(round(cy + radius))
    W, H = ref.size
    left, top = max(0, left), max(0, top)
    right, bottom = min(W, right), min(H, bottom)
    crop = ref.crop((left, top, right, bottom)).convert("RGBA").resize((size, size), Image.LANCZOS)
    px = crop.load()
    w, h = crop.size
    ccx, ccy = w / 2.0, h / 2.0
    rr = min(w, h) / 2.0 - 0.5

    # Face color from center disc (avoid badge)
    samples = []
    for y in range(h):
        for x in range(w):
            dx, dy = x + 0.5 - ccx, y + 0.5 - ccy
            d2 = dx * dx + dy * dy
            if d2 > (rr * 0.5) ** 2:
                continue
            r, g, b, a = px[x, y]
            if r > 150 and g < 120 and b < 120:
                continue
            samples.append((r, g, b))
    fr = sum(s[0] for s in samples) // max(1, len(samples))
    fg = sum(s[1] for s in samples) // max(1, len(samples))
    fb = sum(s[2] for s in samples) // max(1, len(samples))

    # Rim color near equator
    rim_samples = []
    for y in range(h):
        for x in range(w):
            dx, dy = x + 0.5 - ccx, y + 0.5 - ccy
            d2 = dx * dx + dy * dy
            if not ((rr * 0.82) ** 2 <= d2 <= (rr * 0.98) ** 2):
                continue
            if dx > 0 and dy < 0:
                continue  # skip badge quadrant
            r, g, b, a = px[x, y]
            rim_samples.append((r, g, b))
    if rim_samples:
        rr_ = sum(s[0] for s in rim_samples) // len(rim_samples)
        rg_ = sum(s[1] for s in rim_samples) // len(rim_samples)
        rb_ = sum(s[2] for s in rim_samples) // len(rim_samples)
    else:
        rr_, rg_, rb_ = 160, 110, 60

    for y in range(h):
        for x in range(w):
            dx, dy = x + 0.5 - ccx, y + 0.5 - ccy
            d2 = dx * dx + dy * dy
            if d2 > rr * rr:
                px[x, y] = (0, 0, 0, 0)
                continue
            r, g, b, a = px[x, y]
            # Always kill red badge + white ring in upper-right rim
            if dx > -rr * 0.05 and dy < rr * 0.15 and d2 > (rr * 0.55) ** 2:
                if (r > 140 and g < 130 and b < 130) or (r > 200 and g > 200 and b > 200) or (
                    r > 160 and abs(r - g) < 40 and b < 140 and g < 160
                ):
                    # Use rim color near edge, face color inward
                    if d2 > (rr * 0.82) ** 2:
                        px[x, y] = (rr_, rg_, rb_, 255)
                    else:
                        px[x, y] = (fr, fg, fb, 255)
    return crop


def main() -> None:
    ref = Image.open(REF).convert("RGBA")
    OUT.mkdir(parents=True, exist_ok=True)

    hud = ref.crop((4, 8, 595, 150)).convert("RGBA")

    # Coins pill fill — sample dark wood near digits
    coin_color = sample_avg(hud, (100, 50, 110, 58))
    fill_rounded(hud, (98, 54, 170, 90), coin_color, radius=8)

    # Timer digits under hourglass — dark face
    timer_color = sample_avg(hud, (280, 70, 310, 82))
    fill_rounded(hud, (255, 88, 336, 122), timer_color, radius=10)

    # Level number — wood shield face
    level_color = sample_avg(hud, (510, 58, 540, 68))
    fill_rounded(hud, (496, 70, 566, 122), level_color, radius=8)

    hud.save(OUT / "hud_bar_exact.png")
    print("hud", hud.size)

    goal = ref.crop((8, 156, 455, 250)).convert("RGBA")  # 447x94
    cream = sample_avg(goal, (30, 55, 70, 75))
    # Cover icons only (leave Clear all sets + reward)
    fill_rounded(goal, (108, 28, 310, 88), cream, radius=4)
    goal.save(OUT / "goal_board_exact.png")
    print("goal", goal.size)

    freeze = extract_circle(ref, 491.6, 204.9, 32.0, 96)
    hint = extract_circle(ref, 549.1, 205.4, 32.0, 96)
    freeze.save(OUT / "booster_freeze.png")
    hint.save(OUT / "booster_hint.png")
    print("boosters ok")

    hud.save("tmp_hud_preview.png")
    goal.save("tmp_goal_preview.png")
    freeze.save("tmp_freeze_preview.png")
    hint.save("tmp_hint_preview.png")


if __name__ == "__main__":
    main()
