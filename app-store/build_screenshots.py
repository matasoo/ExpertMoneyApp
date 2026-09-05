"""
Build App Store screenshots for ExpertMoney.

Takes raw iPhone captures from raw/ (1206x2622, iPhone 16 Pro), strips the
status bar + Dynamic Island, and composes each one onto a branded 1290x2796
canvas with a headline.

Run:  python build_screenshots.py
Out:  out/01-dashboard.png ... out/05-add.png
"""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
OUT = os.path.join(HERE, "out")

# --- App Store canvas (6.7" — iPhone 15/16 Pro Max class) --------------------
W, H = 1290, 2796

# --- brand ------------------------------------------------------------------
BG = (20, 20, 22)
GREEN = (46, 204, 113)
WHITE = (255, 255, 255)
GLOW = (24, 66, 45)
GLOW_STRENGTH = 0.30

# --- raw capture geometry ---------------------------------------------------
STATUS_BAR_H = 175      # Dynamic Island spans y=42..158; 175 clears it entirely
SHOT_W = 1120           # on-canvas width of the phone screen
SHOT_TOP = 600          # where the screen starts; it bleeds off the bottom
RADIUS = 56

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\seguibl.ttf",    # Segoe UI Black
    r"C:\Windows\Fonts\segoeuib.ttf",   # Segoe UI Bold
    r"C:\Windows\Fonts\arialbd.ttf",
]

# source file, output name, headline line 1 (white), line 2 (emerald)
# NB: raw/ is numbered in reverse of the order the screens were captured —
# 1.png is the dashboard, 5.png is the add-transaction sheet.
PLAN = [
    ("1.png", "01-dashboard", "Know what's safe",   "to spend today"),
    ("4.png", "02-wallet",    "Every account.",     "One balance."),
    ("3.png", "03-goals",     "Set a goal.",        "Watch it fill."),
    ("2.png", "04-stats",     "See where the",      "money went"),
    ("5.png", "05-add",       "Log it in",          "five seconds"),
]


def font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def fit_font(lines, max_width, start=104, minimum=56):
    """Largest size at which every line fits inside max_width."""
    size = start
    while size > minimum:
        f = font(size)
        if all(f.getbbox(t)[2] - f.getbbox(t)[0] <= max_width for t in lines):
            return f
        size -= 2
    return font(minimum)


def background():
    card = Image.new("RGB", (W, H), BG)
    glow = Image.new("RGB", (W, H), BG)
    g = ImageDraw.Draw(glow)
    g.ellipse([-120, -420, W + 120, 560], fill=GLOW)
    card = Image.blend(card, glow.filter(ImageFilter.GaussianBlur(210)), GLOW_STRENGTH)
    return card


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1],
                                           radius=radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0))
    out.putalpha(mask)
    return out


def build(src_name, out_name, line1, line2):
    shot = Image.open(os.path.join(RAW, src_name)).convert("RGB")

    # 1. strip status bar + Dynamic Island
    shot = shot.crop((0, STATUS_BAR_H, shot.width, shot.height))

    # 2. scale to the on-canvas width
    scale = SHOT_W / shot.width
    shot = shot.resize((SHOT_W, int(shot.height * scale)), Image.LANCZOS)

    canvas = background()

    # 3. headline
    d = ImageDraw.Draw(canvas)
    f = fit_font([line1, line2], W - 170)
    line_h = int(f.size * 1.16)
    y = 190
    for text, colour in ((line1, WHITE), (line2, GREEN)):
        w = f.getbbox(text)[2] - f.getbbox(text)[0]
        d.text(((W - w) // 2, y), text, font=f, fill=colour)
        y += line_h

    # 4. drop shadow behind the screen
    x = (W - SHOT_W) // 2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x + 16, SHOT_TOP + 28, x + SHOT_W - 16, H], radius=RADIUS, fill=(0, 0, 0, 190)
    )
    canvas = Image.alpha_composite(
        canvas.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(38))
    )

    # 5. the screen itself, rounded, with a hairline edge
    canvas.paste(rounded(shot, RADIUS), (x, SHOT_TOP), rounded(shot, RADIUS))
    ImageDraw.Draw(canvas).rounded_rectangle(
        [x, SHOT_TOP, x + SHOT_W - 1, H - 1], radius=RADIUS,
        outline=(255, 255, 255, 28), width=2
    )

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"{out_name}.png")
    canvas.convert("RGB").save(path, optimize=True)
    return path


if __name__ == "__main__":
    for src, name, l1, l2 in PLAN:
        p = build(src, name, l1, l2)
        im = Image.open(p)
        print(f"{os.path.basename(p):22} {im.size[0]}x{im.size[1]}  "
              f"{os.path.getsize(p):>9,} bytes")
