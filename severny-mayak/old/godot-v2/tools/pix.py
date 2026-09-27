"""Мини-библиотека для рисования пиксель-арта кодом.
Рисуем в «логическом» разрешении, сохраняем с увеличением x2 (1 пиксель арта = 2x2 пикселя экрана 960x540)."""
import math
import random
from PIL import Image, ImageDraw

SCALE = 2

# Палитра: Endesga 32 + цвета оболочки Nimbus Kids
P = {
    'rust': '#be4a2f', 'orange2': '#d77643', 'sand': '#ead4aa', 'tan': '#e4a672', 'brown2': '#b86f50',
    'brown': '#733e39', 'dkbrown': '#3e2731', 'dkred': '#a22633', 'red': '#e43b44', 'orange': '#f77622',
    'yellow2': '#feae34', 'yellow': '#fee761', 'green': '#63c74d', 'dkgreen': '#3e8948', 'dkgreen2': '#265c42',
    'teal': '#193c3e', 'navy': '#124e89', 'blue': '#0099db', 'cyan': '#2ce8f5', 'white': '#ffffff',
    'grey1': '#c0cbdc', 'grey2': '#8b9bb4', 'grey3': '#5a6988', 'grey4': '#3a4466', 'grey5': '#262b44',
    'black': '#181425', 'magenta': '#ff0044', 'plum': '#68386c', 'pink2': '#b55088', 'pink': '#f6757a',
    'skin': '#e8b796', 'skin2': '#c28569',
    # оболочка
    'grape': '#5b3fb5', 'grapehi': '#8b6ff0', 'grapelo': '#35217a', 'mint': '#3fbf86', 'minthi': '#8ee6bb', 'mintlo': '#1f8a5a',
    'sky': '#bfe4ff', 'sky2': '#a6d6f7', 'paper': '#fbfaf2', 'robot': '#8fd0ff', 'robot2': '#5aa6dc', 'lilac': '#c8b8ff', 'lilac2': '#9a86e0',
    'win': '#eef2f7', 'line': '#b9c2d0', 'ink': '#1d1a2b', 'trayblue': '#2f6fb8', 'trayhi': '#5aa8e8',
}


def C(c):
    if c is None:
        return (0, 0, 0, 0)
    if isinstance(c, tuple):
        return c if len(c) == 4 else c + (255,)
    c = P.get(c, c)
    c = c.lstrip('#')
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


class Canvas:
    def __init__(self, w, h, bg=None):
        self.w, self.h = w, h
        self.im = Image.new('RGBA', (w, h), C(bg))
        self.d = ImageDraw.Draw(self.im)

    # --- базовое ---
    def px(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.putpixel((x, y), C(c))

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.im.getpixel((x, y))
        return (0, 0, 0, 0)

    def rect(self, x, y, w, h, c):
        if w <= 0 or h <= 0:
            return
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=C(c))

    def frame(self, x, y, w, h, c):
        self.d.rectangle([x, y, x + w - 1, y + h - 1], outline=C(c))

    def line(self, x0, y0, x1, y1, c, t=1):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.dot(x0, y0, c, t)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def dot(self, x, y, c, t=1):
        if t <= 1:
            self.px(x, y, c)
        else:
            o = (t - 1) // 2
            self.rect(x - o, y - o, t, t, c)

    def poly(self, pts, c, outline=None):
        self.d.polygon([(int(round(a)), int(round(b))) for a, b in pts], fill=C(c) if c else None,
                       outline=C(outline) if outline else None)

    def disc(self, cx, cy, r, c):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + r * 0.6:
                    self.px(x, y, c)

    def ring(self, cx, cy, r, c, t=1):
        for y in range(int(cy - r - t - 1), int(cy + r + t + 2)):
            for x in range(int(cx - r - t - 1), int(cx + r + t + 2)):
                d = math.hypot(x - cx, y - cy)
                if r - t + 0.5 < d <= r + 0.5:
                    self.px(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x - cx) / max(rx, .1)) ** 2 + ((y - cy) / max(ry, .1)) ** 2 <= 1.02:
                    self.px(x, y, c)

    # --- эффекты ---
    def outline(self, c, diag=False):
        """Обвести все непрозрачные пиксели контуром снаружи."""
        src = self.im.copy()
        W, H = self.w, self.h
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (-1, -1), (1, -1), (-1, 1)] if diag else [])
        for y in range(H):
            for x in range(W):
                if src.getpixel((x, y))[3] == 0:
                    for dx, dy in nb:
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < W and 0 <= yy < H and src.getpixel((xx, yy))[3] > 0:
                            self.im.putpixel((x, y), C(c))
                            break

    def dither(self, x, y, w, h, c, level=0.5, mask=None):
        """Упорядоченный дизеринг (Байер 4x4): level=0..1 — доля пикселей цвета c."""
        B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if (B[yy % 4][xx % 4] + .5) / 16 < level:
                    if mask is None or mask(xx, yy):
                        self.px(xx, yy, c)

    def crayon(self, mask, c, seed=1, density=.18, angle=1):
        """Штриховка «мелком»: диагональные штрихи другого оттенка внутри маски."""
        rnd = random.Random(seed)
        for y in range(self.h):
            for x in range(self.w):
                if mask(x, y) and ((x * angle + y) % 5 == 0) and rnd.random() < density * 3:
                    self.px(x, y, c)

    def paste(self, other, x, y):
        self.im.alpha_composite(other.im, (int(x), int(y)))

    def save(self, path, scale=SCALE):
        im = self.im
        if scale != 1:
            im = im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        im.save(path)


def wobble_line(cv, x0, y0, x1, y1, c, t=1, amp=1.0, seed=0):
    """Линия «от руки»: лёгкое дрожание, как у детского рисунка."""
    rnd = random.Random(seed)
    n = max(2, int(math.hypot(x1 - x0, y1 - y0) / 6))
    pts = []
    for i in range(n + 1):
        k = i / n
        j = 0 if i in (0, n) else rnd.uniform(-amp, amp)
        nx, ny = -(y1 - y0), (x1 - x0)
        L = math.hypot(nx, ny) or 1
        pts.append((x0 + (x1 - x0) * k + nx / L * j, y0 + (y1 - y0) * k + ny / L * j))
    for a, b in zip(pts, pts[1:]):
        cv.line(a[0], a[1], b[0], b[1], c, t)
