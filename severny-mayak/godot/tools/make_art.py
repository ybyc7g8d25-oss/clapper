"""Генератор всей графики игры. Запуск: python3 tools/make_art.py  (из папки godot/)
Всё рисуется кодом в единой палитре (tools/pix.py) и сохраняется в art/ с масштабом x2."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pix import Canvas, P, C, wobble_line  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), '..', 'art')
os.makedirs(OUT, exist_ok=True)


def out(name):
    return os.path.join(OUT, name)


# ============================================================ ОБОИ «я и пиксель»
W, H = 480, 250   # логическое разрешение рабочего стола (960x500 на экране)


def hills_y(x):
    return 178 + 10 * math.sin(x / 70) + 6 * math.sin(x / 23 + 1)


def river_mask(x, y):
    # река в правом нижнем углу
    edge = 250 - (x - 290) * 0.28 - 6 * math.sin(x / 30)
    return x > 290 and y > edge


def wall_base(night=False):
    cv = Canvas(W, H, 'paper')
    sky, sky2 = ('sky', 'sky2') if not night else ('grey5', 'grey4')
    # небо мелком: бумага + плотная штриховка
    for y in range(H):
        for x in range(W):
            if y < hills_y(x) + 2:
                cv.px(x, y, sky)
    cv.crayon(lambda x, y: y < hills_y(x), sky2, seed=3, density=.28)
    cv.crayon(lambda x, y: y < hills_y(x), 'paper', seed=9, density=.05, angle=2)
    # солнце
    sx, sy = 62, 50
    for i in range(8):
        a = i * math.pi / 4 + .2
        wobble_line(cv, sx + math.cos(a) * 30, sy + math.sin(a) * 30, sx + math.cos(a) * 44, sy + math.sin(a) * 44,
                    'yellow2', 2, 1.2, seed=i)
    cv.disc(sx, sy, 24, 'yellow')
    cv.crayon(lambda x, y: (x - sx) ** 2 + (y - sy) ** 2 < 22 ** 2, 'yellow2', seed=5, density=.2)
    cv.ring(sx, sy, 24, 'orange', 2)
    # облако
    for cx, cy, r in [(150, 44, 11), (164, 36, 13), (180, 42, 11), (168, 48, 10), (140, 50, 7)]:
        cv.disc(cx, cy, r, 'white')
    cld = Canvas(W, H)
    cld.im = cv.im.copy()
    # контур облака
    for cx, cy, r in [(150, 44, 11), (164, 36, 13), (180, 42, 11), (168, 48, 10), (140, 50, 7)]:
        for a in range(0, 360, 3):
            x = cx + math.cos(math.radians(a)) * (r + 1)
            y = cy + math.sin(math.radians(a)) * (r + 1)
            inside = any((x - c2) ** 2 + (y - d2) ** 2 < r2 ** 2 for c2, d2, r2 in
                         [(150, 44, 11), (164, 36, 13), (180, 42, 11), (168, 48, 10), (140, 50, 7)])
            if not inside:
                cv.px(x, y, 'grey1')
    # холмы
    for x in range(W):
        top = int(hills_y(x))
        for y in range(top, H):
            cv.px(x, y, 'green')
    cv.crayon(lambda x, y: y > hills_y(x) + 2, 'dkgreen', seed=7, density=.16)
    for x in range(W):
        top = int(hills_y(x))
        cv.px(x, top, 'dkgreen2')
        cv.px(x, top + 1, 'dkgreen')
    # цветы и травинки
    rnd = random.Random(4)
    for _ in range(26):
        x = rnd.randint(4, 300)
        y = int(hills_y(x)) + rnd.randint(8, 60)
        if y < H - 4:
            col = rnd.choice(['red', 'yellow', 'white', 'pink'])
            cv.px(x, y - 1, col); cv.px(x - 1, y, col); cv.px(x + 1, y, col); cv.px(x, y + 1, col)
            cv.px(x, y, 'yellow2' if col != 'yellow' else 'orange')
    for _ in range(40):
        x = rnd.randint(0, W - 1)
        y = int(hills_y(x)) + rnd.randint(4, 70)
        cv.px(x, y, 'dkgreen2'); cv.px(x + 1, y - 1, 'dkgreen2')
    # река
    for y in range(H):
        for x in range(W):
            if river_mask(x, y):
                cv.px(x, y, 'blue')
    cv.crayon(river_mask, 'navy', seed=11, density=.14)
    for y in range(H):
        for x in range(W):
            if river_mask(x, y) and not river_mask(x, y - 1):
                cv.px(x, y, 'navy'); cv.px(x, y + 1, 'navy')
    for wx, wy in [(330, 238), (372, 226), (420, 216), (452, 236), (400, 244)]:
        for i in range(8):
            cv.px(wx + i, wy + (0 if i in (0, 1, 6, 7) else -1) * (1 if i < 4 else 1), 'white')
    # стрелка от надписи к маяку
    wobble_line(cv, 318, 44, 350, 60, 'grapelo', 2, 1, seed=2)
    wobble_line(cv, 350, 60, 366, 82, 'grapelo', 2, 1, seed=3)
    cv.line(366, 82, 358, 80, 'grapelo', 2)
    cv.line(366, 82, 368, 74, 'grapelo', 2)
    # сердечко
    heart(cv, 244, 118)
    robot(cv, 205, 222)
    return cv


def tower_layer():
    cv = Canvas(W, H)
    lighthouse(cv, 392)
    return cv


def heart(cv, x, y):
    for yy in range(-6, 8):
        for xx in range(-8, 9):
            X, Y = xx / 7.5, -yy / 7.5
            if (X * X + Y * Y - 1) ** 3 - X * X * Y ** 3 <= 0:
                cv.px(x + xx, y + yy, 'pink')
    cv.crayon(lambda a, b: abs(a - x) < 7 and abs(b - y) < 6, 'pink2', seed=2, density=.1)
    for yy in range(-7, 9):
        for xx in range(-9, 10):
            X, Y = xx / 7.5, -yy / 7.5
            inside = (X * X + Y * Y - 1) ** 3 - X * X * Y ** 3 <= 0
            if not inside:
                for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                    X2, Y2 = (xx + dx) / 7.5, -(yy + dy) / 7.5
                    if (X2 * X2 + Y2 * Y2 - 1) ** 3 - X2 * X2 * Y2 ** 3 <= 0:
                        cv.px(x + xx, y + yy, 'red')
                        break


def lighthouse(cv, cx, base=208, top=112, lamp_color=None):
    """Маяк: белая башня с красными полосами, галерея, фонарная комната, красная крыша."""
    wb, wt = 21, 14
    def half(y):
        return wt + (wb - wt) * (y - top) / (base - top)
    for y in range(top, base + 1):
        hw = half(y)
        for x in range(int(cx - hw), int(cx + hw) + 1):
            stripe = ((y - top) // 22) % 2 == 1
            col = 'red' if stripe else 'paper'
            # объём: правая сторона темнее
            if x > cx + hw * .35:
                col = 'dkred' if stripe else 'grey1'
            cv.px(x, y, col)
    cv.crayon(lambda x, y: top < y < base and abs(x - cx) < half(y) - 1, 'sand', seed=21, density=.06)
    for y in range(top, base + 1):
        hw = half(y)
        cv.px(cx - hw - 1, y, 'ink'); cv.px(cx - hw - 2, y, 'ink')
        cv.px(cx + hw + 1, y, 'ink'); cv.px(cx + hw + 2, y, 'ink')
    cv.rect(cx - wb - 2, base, wb * 2 + 5, 2, 'ink')
    # дверь и окошки
    cv.rect(cx - 4, base - 16, 8, 16, 'brown'); cv.frame(cx - 5, base - 17, 10, 17, 'ink')
    cv.px(cx + 2, base - 8, 'yellow2')
    for wy in (150, 128):
        cv.rect(cx - 2, wy, 4, 6, 'navy'); cv.frame(cx - 3, wy - 1, 6, 8, 'ink')
    # галерея
    cv.rect(cx - 22, top - 4, 44, 4, 'grey3'); cv.rect(cx - 22, top - 4, 44, 1, 'grey2')
    cv.frame(cx - 23, top - 5, 46, 6, 'ink')
    for x in range(cx - 20, cx + 21, 5):
        cv.rect(x, top - 12, 1, 8, 'ink')
    cv.rect(cx - 21, top - 13, 42, 1, 'ink')
    # фонарная комната
    cv.rect(cx - 15, top - 30, 30, 26, 'grey4')
    cv.frame(cx - 16, top - 31, 32, 28, 'ink')
    for x in (cx - 6, cx + 5):
        cv.rect(x, top - 30, 1, 26, 'ink')
    if lamp_color:
        cv.disc(cx, top - 17, 7, lamp_color)
    # крыша
    cv.poly([(cx - 19, top - 31), (cx, top - 52), (cx + 19, top - 31)], 'red')
    for y in range(top - 51, top - 30):
        for x in range(cx, cx + 20):
            if cv.get(x, y)[:3] == C('red')[:3] and x > cx + 4:
                cv.px(x, y, 'dkred')
    cv.poly([(cx - 20, top - 30), (cx, top - 53), (cx + 20, top - 30)], None, 'ink')
    cv.poly([(cx - 21, top - 30), (cx, top - 54), (cx + 21, top - 30)], None, 'ink')
    cv.disc(cx, top - 55, 2, 'ink')


def lamp_disc(color):
    cv = Canvas(W, H)
    cv.disc(392, 95, 7, color)
    cv.disc(390, 93, 2, 'white')
    return cv


def lamp_layer(color, glow, beams=True):
    cv = Canvas(W, H)
    cx, cy = 392, 95
    if beams:
        for sgn in (-1, 1):
            pts = [(cx, cy - 2), (cx + sgn * 220, cy - 42), (cx + sgn * 220, cy + 20), (cx, cy + 2)]
            tmp = Canvas(W, H)
            tmp.poly(pts, glow)
            for y in range(H):
                for x in range(W):
                    if tmp.get(x, y)[3]:
                        k = 1 - abs(x - cx) / 230
                        B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
                        if (B[y % 4][x % 4] + .5) / 16 < .45 * k:
                            cv.px(x, y, glow)
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(cy - 40, cy + 41):
        for x in range(cx - 40, cx + 41):
            d = math.hypot(x - cx, y - cy)
            if d < 40 and (B[y % 4][x % 4] + .5) / 16 < (1 - d / 40) * .9:
                cv.px(x, y, glow)
    return cv


def boy(cv, cx, ground, pale=False):
    """Лёва: мальчик в синей футболке."""
    skin, hair, shirt, shirt2 = 'skin', 'brown', 'blue', 'navy'
    # ноги
    cv.line(cx - 6, ground - 26, cx - 8, ground - 2, 'grey4', 3)
    cv.line(cx + 6, ground - 26, cx + 8, ground - 2, 'grey4', 3)
    cv.rect(cx - 12, ground - 2, 6, 3, 'ink'); cv.rect(cx + 6, ground - 2, 6, 3, 'ink')
    # футболка
    body = [(cx - 12, ground - 62), (cx + 12, ground - 62), (cx + 16, ground - 26), (cx - 16, ground - 26)]
    cv.poly(body, shirt)
    cv.crayon(lambda x, y: ground - 60 < y < ground - 27 and abs(x - cx) < 13, shirt2, seed=31, density=.12)
    cv.poly(body, None, 'ink')
    cv.rect(cx - 3, ground - 50, 6, 5, 'yellow')    # звёздочка на футболке
    cv.px(cx, ground - 52, 'yellow'); cv.px(cx, ground - 44, 'yellow')
    # руки
    cv.line(cx - 12, ground - 58, cx - 26, ground - 36, skin, 3)
    cv.line(cx + 12, ground - 58, cx + 30, ground - 40, skin, 3)
    # голова
    hy = ground - 78
    cv.disc(cx, hy, 15, skin)
    cv.ring(cx, hy, 15, 'brown', 1)
    # волосы
    for y in range(hy - 16, hy - 3):
        for x in range(cx - 16, cx + 17):
            if (x - cx) ** 2 + (y - hy) ** 2 <= 16 ** 2 and y < hy - 6 + abs(x - cx) * .25 - (3 if abs(x - cx) < 6 else 0):
                cv.px(x, y, hair)
    cv.crayon(lambda x, y: (x - cx) ** 2 + (y - hy) ** 2 < 15 ** 2 and y < hy - 7, 'dkbrown', seed=3, density=.2)
    cv.rect(cx - 6, hy + 1, 2, 3, 'ink'); cv.rect(cx + 5, hy + 1, 2, 3, 'ink')
    cv.px(cx - 9, hy + 6, 'pink'); cv.px(cx - 8, hy + 6, 'pink'); cv.px(cx + 9, hy + 6, 'pink'); cv.px(cx + 10, hy + 6, 'pink')
    for i, dy in enumerate([0, 1, 2, 2, 2, 2, 1, 0]):
        cv.px(cx - 4 + i, hy + 7 + dy, 'ink')


def robot(cv, cx, ground):
    """Пиксель: робот-телевизор с антенной."""
    ink = 'ink'
    cv.line(cx - 6, ground - 26, cx - 6, ground - 2, ink, 3)
    cv.line(cx + 6, ground - 26, cx + 6, ground - 2, ink, 3)
    cv.rect(cx - 10, ground - 2, 7, 3, ink); cv.rect(cx + 4, ground - 2, 7, 3, ink)
    # тело
    cv.rect(cx - 12, ground - 60, 24, 34, 'lilac')
    cv.crayon(lambda x, y: abs(x - cx) < 11 and ground - 59 < y < ground - 27, 'lilac2', seed=8, density=.12)
    cv.frame(cx - 13, ground - 61, 26, 36, ink)
    cv.rect(cx - 6, ground - 52, 12, 8, 'grape'); cv.px(cx - 3, ground - 49, 'mint'); cv.px(cx + 2, ground - 49, 'yellow')
    # руки
    cv.line(cx - 13, ground - 54, cx - 22, ground - 40, ink, 3)
    cv.line(cx + 13, ground - 54, cx + 26, ground - 46, ink, 3)
    # голова
    hy = ground - 90
    cv.rect(cx - 18, hy, 36, 28, 'robot')
    cv.crayon(lambda x, y: abs(x - cx) < 17 and hy < y < hy + 27, 'robot2', seed=4, density=.1)
    cv.frame(cx - 19, hy - 1, 38, 30, ink); cv.frame(cx - 18, hy, 36, 28, ink)
    cv.px(cx - 18, hy, 'robot'); cv.px(cx + 17, hy, 'robot'); cv.px(cx - 18, hy + 27, 'robot'); cv.px(cx + 17, hy + 27, 'robot')
    cv.rect(cx - 10, hy + 9, 5, 6, ink); cv.rect(cx + 6, hy + 9, 5, 6, ink)
    cv.px(cx - 9, hy + 10, 'white'); cv.px(cx + 7, hy + 10, 'white')
    for i, dy in enumerate([0, 1, 2, 2, 2, 2, 2, 2, 1, 0]):
        cv.px(cx - 5 + i, hy + 19 + dy, ink)
    # антенна
    cv.line(cx, hy - 1, cx, hy - 10, ink, 2)
    cv.disc(cx, hy - 13, 3, 'red'); cv.ring(cx, hy - 13, 4, ink, 1); cv.px(cx - 1, hy - 14, 'pink')


def scratch():
    cv = Canvas(48, 20)
    rnd = random.Random(5)
    x, y = 2, 16
    for i in range(14):
        nx = min(46, 2 + i * 3.3 + rnd.uniform(-1, 1))
        ny = 3 if i % 2 == 0 else 17
        cv.line(x, y, nx, ny, 'black', 3)
        x, y = nx, ny
    return cv


def make_wallpapers():
    base = wall_base()
    base.save(out('wall_base.png'))
    b = Canvas(W, H); boy(b, 150, 222); b.save(out('wall_boy.png'))
    lamp_layer('yellow', 'yellow').save(out('wall_glow.png'))
    lamp_layer('red', 'magenta', beams=False).save(out('wall_glow_red.png'))
    tower_layer().save(out('wall_tower.png'))
    lamp_disc('yellow').save(out('wall_lamp.png'))
    lamp_disc('magenta').save(out('wall_lamp_red.png'))
    scratch().save(out('wall_scratch.png'))
    full = wall_base()
    for layer in (lamp_layer('yellow', 'yellow'), tower_layer(), lamp_disc('yellow')):
        full.paste(layer, 0, 0)
    boy(full, 150, 222)
    full.save(out('drawing_me_and_pixel.png'))


# ============================================================ ЗНАЧКИ 16x16
def icon(name, fn):
    cv = Canvas(16, 16)
    fn(cv)
    cv.save(out('icon_' + name + '.png'))


def ic_note(cv, red=False):
    ln, bg = ('dkred', 'white') if red else ('grey3', 'white')
    cv.rect(3, 1, 9, 14, bg); cv.poly([(9, 1), (12, 4), (9, 4)], 'grey1')
    cv.frame(2, 0, 11, 16, 'ink'); cv.px(12, 0, None); cv.px(11, 0, None)
    cv.line(10, 0, 12, 2, 'ink')
    for y in (5, 7, 9, 11):
        cv.line(4, y, 10 if y != 11 else 8, y, 'red' if red else 'grey2')
    if red:
        cv.rect(7, 12, 2, 1, 'red')


def ic_folder(cv):
    cv.rect(1, 3, 6, 2, 'yellow2'); cv.rect(1, 4, 14, 11, 'yellow2')
    cv.rect(1, 6, 14, 9, 'yellow'); cv.rect(1, 6, 14, 1, 'white')
    cv.frame(0, 3, 16, 13, 'brown'); cv.px(0, 3, None); cv.line(7, 3, 8, 4, 'brown')


def ic_pixel(cv, dark=False):
    face = 'grey5' if dark else 'robot'
    cv.px(8, 0, 'red'); cv.px(8, 1, 'ink'); cv.px(8, 2, 'ink')
    cv.rect(2, 3, 12, 11, face); cv.frame(1, 3, 14, 12, 'red' if dark else 'ink')
    eye = 'red' if dark else 'ink'
    cv.rect(4, 6, 2, 3, eye); cv.rect(10, 6, 2, 3, eye)
    if not dark:
        cv.line(5, 11, 10, 11, 'ink'); cv.px(4, 10, 'ink'); cv.px(11, 10, 'ink')
    cv.rect(5, 15, 6, 1, 'lilac2')


def ic_web(cv):
    cv.disc(7.5, 7.5, 7, 'blue'); cv.ring(7.5, 7.5, 7, 'navy', 1)
    for y in range(16):
        cv.px(7, y, 'cyan') if 1 <= y <= 14 else None
    cv.line(1, 7, 14, 7, 'cyan'); cv.ring(7.5, 7.5, 3.5, 'cyan', 1)
    cv.line(3, 3, 12, 12, 'white'); cv.line(12, 3, 3, 12, 'white')
    cv.ring(7.5, 7.5, 7, 'navy', 1)


def ic_mail(cv):
    cv.rect(1, 4, 14, 10, 'white'); cv.frame(0, 3, 16, 12, 'ink')
    cv.line(1, 4, 7, 9, 'ink'); cv.line(14, 4, 8, 9, 'ink')
    cv.rect(10, 0, 5, 3, 'grey2'); cv.px(14, 1, 'yellow2'); cv.px(9, 1, 'grey2')


def ic_tale(cv):
    cv.poly([(1, 3), (7, 2), (7, 14), (1, 14)], 'sand'); cv.poly([(8, 2), (14, 3), (14, 14), (8, 14)], 'white')
    cv.poly([(1, 3), (7, 2), (7, 14), (1, 14)], None, 'brown'); cv.poly([(8, 2), (14, 3), (14, 14), (8, 14)], None, 'brown')
    cv.rect(10, 7, 2, 5, 'red'); cv.rect(10, 5, 2, 2, 'yellow'); cv.px(9, 12, 'red'); cv.px(12, 12, 'red')
    for y in (5, 7, 9, 11):
        cv.line(3, y, 5, y, 'brown2')


def ic_diary(cv):
    cv.rect(2, 1, 10, 14, 'red'); cv.rect(2, 1, 2, 14, 'dkred'); cv.frame(1, 0, 12, 16, 'ink')
    cv.rect(8, 8, 7, 6, 'yellow2'); cv.frame(8, 8, 7, 6, 'brown')
    cv.frame(9, 5, 5, 4, 'brown'); cv.px(11, 10, 'brown'); cv.px(11, 11, 'brown')


def ic_cam(cv):
    cv.disc(7.5, 6.5, 6, 'grey1'); cv.ring(7.5, 6.5, 6, 'ink', 1)
    cv.disc(7.5, 6.5, 3, 'ink'); cv.px(6, 5, 'robot')
    cv.poly([(5, 12), (10, 12), (12, 15), (3, 15)], 'grey2'); cv.poly([(5, 12), (10, 12), (12, 15), (3, 15)], None, 'ink')
    cv.px(12, 2, 'red')


def ic_chat(cv):
    cv.rect(1, 2, 14, 9, 'green'); cv.frame(0, 1, 16, 11, 'dkgreen2')
    cv.poly([(3, 11), (7, 11), (3, 14)], 'green'); cv.line(3, 11, 3, 14, 'dkgreen2'); cv.line(3, 14, 7, 11, 'dkgreen2')
    for x in (4, 7, 10):
        cv.rect(x, 6, 2, 2, 'white')


def ic_bin(cv):
    cv.rect(3, 5, 10, 10, 'grey1'); cv.frame(2, 4, 12, 12, 'ink'); cv.rect(1, 3, 14, 2, 'grey2'); cv.frame(1, 3, 14, 2, 'ink')
    cv.rect(6, 1, 4, 2, 'grey2'); cv.frame(5, 1, 6, 3, 'ink')
    for x in (5, 8, 11):
        cv.line(x, 7, x, 13, 'grey3')


def ic_tm(cv):
    cv.rect(1, 1, 14, 10, 'black'); cv.frame(0, 0, 16, 12, 'grey3')
    pts = [(2, 8), (4, 6), (6, 7), (8, 3), (10, 6), (12, 4), (13, 5)]
    for a, b in zip(pts, pts[1:]):
        cv.line(a[0], a[1], b[0], b[1], 'green')
    cv.rect(6, 12, 4, 2, 'grey3'); cv.rect(3, 14, 10, 2, 'grey3')


def ic_warn(cv):
    cv.poly([(8, 0), (15, 14), (0, 14)], 'yellow2'); cv.poly([(8, 0), (15, 14), (0, 14)], None, 'brown')
    cv.rect(7, 4, 2, 6, 'ink'); cv.rect(7, 11, 2, 2, 'ink')


def ic_stop(cv):
    cv.disc(7.5, 7.5, 7, 'red'); cv.ring(7.5, 7.5, 7, 'dkred', 1)
    cv.line(5, 5, 10, 10, 'white', 2); cv.line(10, 5, 5, 10, 'white', 2)


def ic_info(cv):
    cv.disc(7.5, 7.5, 7, 'blue'); cv.ring(7.5, 7.5, 7, 'navy', 1)
    cv.rect(7, 3, 2, 2, 'white'); cv.rect(7, 6, 2, 6, 'white')


def ic_power(cv):
    cv.rect(1, 1, 14, 14, 'red'); cv.frame(0, 0, 16, 16, 'dkred')
    cv.ring(7.5, 8.5, 4, 'white', 1); cv.rect(6, 6, 4, 2, 'red'); cv.rect(7, 3, 2, 6, 'white')


def ic_gear(cv):
    for a in range(0, 360, 45):
        x = 7.5 + math.cos(math.radians(a)) * 6
        y = 7.5 + math.sin(math.radians(a)) * 6
        cv.rect(int(x) - 1, int(y) - 1, 3, 3, 'grey3')
    cv.disc(7.5, 7.5, 5, 'grey2'); cv.disc(7.5, 7.5, 2, 'white')


def ic_cloud(cv):
    for cx, cy, r in [(5, 9, 3.5), (9, 7, 4.5), (12, 10, 3)]:
        cv.disc(cx, cy, r, 'white')
    cv.rect(3, 10, 11, 3, 'white')
    cv.rect(6, 8, 1, 2, 'grape'); cv.rect(10, 8, 1, 2, 'grape')


def ic_spk(cv, mute=False):
    cv.rect(2, 6, 3, 4, 'white'); cv.poly([(5, 6), (9, 2), (9, 13), (5, 10)], 'white')
    if mute:
        cv.line(11, 5, 14, 10, 'white'); cv.line(14, 5, 11, 10, 'white')
    else:
        cv.px(11, 6, 'white'); cv.px(11, 9, 'white'); cv.px(12, 7, 'white'); cv.px(12, 8, 'white')
        cv.px(13, 4, 'white'); cv.px(14, 6, 'white'); cv.px(14, 9, 'white'); cv.px(13, 11, 'white')
        cv.px(14, 7, 'white'); cv.px(14, 8, 'white')


def ic_star(cv):
    pts = []
    for i in range(10):
        r = 7 if i % 2 == 0 else 3
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((7.5 + math.cos(a) * r, 8 + math.sin(a) * r))
    cv.poly(pts, 'yellow'); cv.poly(pts, None, 'yellow2')
    cv.px(6, 6, 'white')


def ic_hide(cv):
    cv.rect(1, 2, 14, 9, 'navy'); cv.frame(0, 1, 16, 11, 'white')
    cv.rect(2, 3, 5, 3, 'grape'); cv.rect(8, 6, 5, 3, 'grape')
    cv.rect(5, 12, 6, 1, 'white'); cv.rect(3, 13, 10, 2, 'white')


def ic_eye(cv):
    pts = [(0, 8), (4, 4), (11, 4), (15, 8), (11, 12), (4, 12)]
    cv.poly(pts, 'white'); cv.poly(pts, None, 'ink')
    cv.disc(7.5, 8, 3, 'ink'); cv.px(6, 7, 'white')


def make_icons():
    for n, f in [('note', ic_note), ('noteRed', lambda c: ic_note(c, True)), ('folder', ic_folder), ('pixel', ic_pixel),
                 ('pixelDark', lambda c: ic_pixel(c, True)), ('web', ic_web), ('mail', ic_mail), ('tale', ic_tale),
                 ('diary', ic_diary), ('cam', ic_cam), ('chat', ic_chat), ('bin', ic_bin), ('tm', ic_tm),
                 ('warn', ic_warn), ('stop', ic_stop), ('info', ic_info), ('power', ic_power), ('gear', ic_gear),
                 ('cloud', ic_cloud), ('spk', ic_spk), ('mute', lambda c: ic_spk(c, True)), ('star', ic_star),
                 ('hide', ic_hide), ('eye', ic_eye)]:
        icon(n, f)


# ============================================================ ПИКСЕЛЬ (аватар 32x32)
def avatar(stage, talk=False):
    cv = Canvas(32, 32)
    ink = 'ink'
    face = {0: 'robot', 1: 'robot', 2: 'grey1', 3: 'black'}[stage]
    face2 = {0: 'robot2', 1: 'robot2', 2: 'grey2', 3: 'grey5'}[stage]
    edge = 'red' if stage == 3 else ink
    cv.rect(15, 3, 2, 5, ink)
    cv.disc(15.5, 2.5, 2.2, 'red' if stage != 2 else 'grey2')
    cv.rect(3, 8, 26, 22, face)
    cv.rect(3, 26, 26, 4, face2); cv.rect(25, 8, 4, 22, face2)
    cv.frame(2, 7, 28, 24, edge); cv.frame(3, 8, 26, 22, edge)
    if stage == 0:
        for ex in (9, 20):   # глаза-дуги ^ ^
            cv.px(ex, 16, ink); cv.px(ex + 1, 15, ink); cv.px(ex + 2, 14, ink); cv.px(ex + 3, 15, ink); cv.px(ex + 4, 16, ink)
            cv.px(ex, 17, ink); cv.px(ex + 4, 17, ink)
    elif stage == 3:
        cv.rect(9, 14, 4, 4, 'magenta'); cv.rect(20, 14, 4, 4, 'magenta')
        cv.px(10, 15, 'white'); cv.px(21, 15, 'white')
    else:
        cv.rect(9, 13, 4, 5, ink); cv.rect(20, 13, 4, 5, ink)
        cv.px(10, 14, 'white'); cv.px(21, 14, 'white')
    # рот
    if talk:
        cv.rect(12, 22, 8, 4, 'magenta' if stage == 3 else ink)
        if stage != 3:
            cv.rect(13, 24, 6, 1, 'red')
    elif stage == 0:
        for i, dy in enumerate([0, 1, 2, 2, 2, 2, 2, 2, 1, 0]):
            cv.px(11 + i, 21 + dy, ink)
    elif stage == 1:
        cv.line(12, 23, 19, 23, ink); cv.px(11, 22, ink); cv.px(20, 22, ink)
    elif stage == 2:
        cv.line(11, 23, 20, 23, ink)
    if stage in (0, 1):
        cv.px(6, 20, 'pink'); cv.px(7, 20, 'pink'); cv.px(24, 20, 'pink'); cv.px(25, 20, 'pink')
    return cv


def scare_face():
    cv = Canvas(96, 96, 'black')
    cv.rect(10, 18, 76, 66, 'black')
    cv.frame(8, 16, 80, 70, 'dkred'); cv.frame(9, 17, 78, 68, 'red')
    cv.rect(44, 4, 6, 12, 'red'); cv.disc(47, 4, 5, 'magenta')
    cv.rect(24, 34, 14, 14, 'magenta'); cv.rect(58, 34, 14, 14, 'magenta')
    cv.rect(28, 38, 4, 4, 'white'); cv.rect(62, 38, 4, 4, 'white')
    cv.rect(24, 60, 48, 14, 'red')
    for x in range(26, 72, 6):
        cv.poly([(x, 60), (x + 5, 60), (x + 2, 67)], 'white')
        cv.poly([(x, 74), (x + 5, 74), (x + 2, 68)], 'white')
    rnd = random.Random(3)
    for _ in range(300):
        cv.px(rnd.randint(0, 95), rnd.randint(0, 95), rnd.choice(['dkred', 'grey5', 'black']))
    return cv


def make_avatars():
    for s in range(4):
        avatar(s).save(out(f'pix_{s}.png'))
        avatar(s, True).save(out(f'pix_{s}_talk.png'))
    scare_face().save(out('scare.png'), 4)


# ============================================================ РИСУНКИ ЛЁВЫ (240x168)
def drawing_tower():
    cv = Canvas(240, 168, 'grey5')
    cv.crayon(lambda x, y: True, 'navy', seed=2, density=.25)
    rnd = random.Random(7)
    for _ in range(18):
        x, y = rnd.randint(4, 236), rnd.randint(4, 90)
        cv.px(x, y, 'yellow'); cv.px(x - 1, y, 'yellow2'); cv.px(x + 1, y, 'yellow2'); cv.px(x, y - 1, 'yellow2'); cv.px(x, y + 1, 'yellow2')
    # лучи
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(0, 110):
        for x in range(240):
            for sgn in (-1, 1):
                dx = (x - 120) * sgn
                if dx > 0:
                    up, dn = 44 - dx * .25, 44 + dx * .1
                    if up < y < dn and (B[y % 4][x % 4] + .5) / 16 < .5 * (1 - dx / 130):
                        cv.px(x, y, 'yellow')
    # море
    for y in range(120, 168):
        for x in range(240):
            if y > 124 + 3 * math.sin(x / 12):
                cv.px(x, y, 'blue')
    cv.crayon(lambda x, y: y > 128, 'navy', seed=4, density=.2)
    for x in range(240):
        cv.px(x, int(124 + 3 * math.sin(x / 12)), 'cyan')
    t = Canvas(240, 168)
    lighthouse(t, 120, base=140, top=62, lamp_color='yellow')
    # Пиксель в окне фонарной комнаты
    cv.paste(t, 0, 0)
    cv.rect(113, 38, 14, 11, 'robot'); cv.frame(112, 37, 16, 13, 'ink'); cv.px(116, 42, 'ink'); cv.px(123, 42, 'ink')
    cv.line(117, 46, 122, 46, 'ink')
    return cv


def drawing_family():
    cv = Canvas(240, 168, 'paper')
    def person(cx, h, shirt, hair_fn, skirt=False):
        ground = 138
        top = ground - h
        cv.line(cx - 5, ground - 26, cx - 6, ground, 'grey4', 3); cv.line(cx + 5, ground - 26, cx + 6, ground, 'grey4', 3)
        body = [(cx - 10, top + 26), (cx + 10, top + 26), (cx + (16 if skirt else 12), ground - 24), (cx - (16 if skirt else 12), ground - 24)]
        cv.poly(body, shirt); cv.poly(body, None, 'ink')
        cv.line(cx - 10, top + 30, cx - 18, top + 52, 'skin', 3); cv.line(cx + 10, top + 30, cx + 18, top + 52, 'skin', 3)
        cv.disc(cx, top + 12, 11, 'skin'); cv.ring(cx, top + 12, 11, 'brown', 1)
        hair_fn(cx, top + 12)
        cv.px(cx - 4, top + 12, 'ink'); cv.px(cx + 4, top + 12, 'ink')
        cv.line(cx - 3, top + 17, cx + 3, top + 17, 'ink'); cv.px(cx - 4, top + 16, 'ink'); cv.px(cx + 4, top + 16, 'ink')
    def mom_hair(cx, cy):
        for y in range(cy - 12, cy + 12):
            for x in range(cx - 13, cx + 14):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if d <= 13 ** 2 and (y < cy - 4 or abs(x - cx) > 9):
                    cv.px(x, y, 'yellow2')
    def dad_hair(cx, cy):
        for x in range(cx - 10, cx + 11):
            cv.px(x, cy - 10 - (1 if abs(x - cx) < 6 else 0), 'dkbrown'); cv.px(x, cy - 9, 'dkbrown')
    def kid_hair(cx, cy):
        for y in range(cy - 12, cy - 3):
            for x in range(cx - 12, cx + 13):
                if (x - cx) ** 2 + (y - cy) ** 2 <= 12 ** 2:
                    cv.px(x, y, 'brown')
    person(34, 104, 'red', mom_hair, True)
    person(84, 118, 'green', dad_hair)
    person(150, 78, 'blue', kid_hair)
    # Пиксель рядом с «я», держатся за руки
    robot(cv, 196, 138)
    cv.line(168, 108, 176, 110, 'skin', 3)
    return cv


def epilogue_wall():
    cv = Canvas(W, H, 'paper')
    for y in range(H):
        for x in range(W):
            if y < hills_y(x) + 6:
                cv.px(x, y, 'sky')
    cv.crayon(lambda x, y: y < hills_y(x) + 4, 'white', seed=13, density=.2)
    sx, sy = 410, 56
    for i in range(8):
        a = i * math.pi / 4
        wobble_line(cv, sx + math.cos(a) * 30, sy + math.sin(a) * 30, sx + math.cos(a) * 44, sy + math.sin(a) * 44, 'yellow2', 2, 1, seed=i)
    cv.disc(sx, sy, 24, 'yellow'); cv.ring(sx, sy, 24, 'orange', 2)
    for x in range(W):
        top = int(hills_y(x) + 6)
        for y in range(top, H):
            cv.px(x, y, 'green')
        cv.px(x, top, 'dkgreen2')
    cv.crayon(lambda x, y: y > hills_y(x) + 8, 'dkgreen', seed=17, density=.14)
    # маленький выключенный маяк вдалеке
    t = Canvas(W, H)
    lighthouse(t, 60, base=186, top=128, lamp_color='grey3')
    cv.paste(t, 0, 0)
    # дом
    hx, hy = 230, 120
    cv.rect(hx - 50, hy, 100, 62, 'sand'); cv.crayon(lambda x, y: abs(x - hx) < 49 and hy < y < hy + 61, 'tan', seed=3, density=.12)
    cv.frame(hx - 51, hy - 1, 102, 64, 'brown')
    cv.poly([(hx - 60, hy + 2), (hx, hy - 44), (hx + 60, hy + 2)], 'red'); cv.poly([(hx - 60, hy + 2), (hx, hy - 44), (hx + 60, hy + 2)], None, 'dkred')
    cv.rect(hx - 8, hy + 26, 16, 36, 'brown'); cv.px(hx + 4, hy + 44, 'yellow')
    for wx in (hx - 38, hx + 20):
        cv.rect(wx, hy + 16, 18, 16, 'yellow'); cv.frame(wx - 1, hy + 15, 20, 18, 'brown'); cv.line(wx + 9, hy + 16, wx + 9, hy + 31, 'brown')
    cv.rect(hx + 26, hy - 34, 10, 20, 'brown')
    # семья, держатся за руки
    b = Canvas(W, H)
    boy(b, 240, 238)
    cv.paste(b, 0, 0)
    def adult(cx, h, shirt, hair):
        g = 238
        cv.line(cx - 6, g - 30, cx - 7, g, 'grey4', 3); cv.line(cx + 6, g - 30, cx + 7, g, 'grey4', 3)
        body = [(cx - 13, g - h + 30), (cx + 13, g - h + 30), (cx + 16, g - 28), (cx - 16, g - 28)]
        cv.poly(body, shirt); cv.poly(body, None, 'ink')
        cv.disc(cx, g - h + 14, 14, 'skin'); cv.ring(cx, g - h + 14, 14, 'brown', 1)
        hy2 = g - h + 14
        for x in range(cx - 14, cx + 15):
            for y in range(hy2 - 15, hy2 - 4):
                if (x - cx) ** 2 + (y - hy2) ** 2 <= 15 ** 2:
                    cv.px(x, y, hair)
        cv.rect(cx - 6, hy2, 2, 3, 'ink'); cv.rect(cx + 5, hy2, 2, 3, 'ink')
        for i, dy in enumerate([0, 1, 2, 2, 2, 1, 0]):
            cv.px(cx - 3 + i, hy2 + 6 + dy, 'ink')
    adult(190, 120, 'red', 'yellow2')
    adult(296, 132, 'green', 'dkbrown')
    cv.line(203, 150, 220, 168, 'skin', 3)
    cv.line(260, 168, 282, 152, 'skin', 3)
    heart(cv, 150, 70)
    return cv


# ============================================================ КАМЕРА (240x150)
def cam_room():
    cv = Canvas(240, 150, 'grey5')
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    # стена и пол
    cv.rect(0, 0, 240, 112, 'grey5')
    cv.dither(0, 0, 240, 112, 'grey4', .18)
    cv.rect(0, 112, 240, 38, 'black'); cv.dither(0, 112, 240, 38, 'grey5', .3)
    # окно с луной
    cv.rect(22, 18, 54, 58, 'navy'); cv.dither(22, 18, 54, 58, 'teal', .3)
    cv.disc(62, 32, 7, 'grey1'); cv.disc(65, 30, 6, 'navy')
    cv.frame(20, 16, 58, 62, 'grey3'); cv.rect(48, 18, 2, 58, 'grey3'); cv.rect(22, 46, 54, 2, 'grey3')
    cv.rect(16, 76, 66, 4, 'grey3')
    # шторы
    cv.rect(10, 12, 10, 70, 'plum'); cv.rect(78, 12, 10, 70, 'plum'); cv.dither(10, 12, 10, 70, 'grey4', .35); cv.dither(78, 12, 10, 70, 'grey4', .35)
    # постер с маяком
    cv.rect(190, 26, 30, 40, 'grey4'); cv.frame(189, 25, 32, 42, 'grey3')
    cv.rect(203, 36, 4, 22, 'grey1'); cv.rect(202, 32, 6, 4, 'grey2'); cv.px(205, 33, 'yellow2')
    # кровать
    cv.rect(112, 92, 112, 24, 'grey4'); cv.rect(112, 88, 112, 6, 'grey3')
    cv.rect(112, 74, 8, 42, 'grey3'); cv.rect(216, 80, 8, 36, 'grey3')
    cv.rect(122, 82, 26, 10, 'grey2')  # подушка
    cv.rect(150, 90, 66, 4, 'plum'); cv.dither(150, 94, 66, 20, 'plum', .4)
    # стол и стул (компьютер вне кадра — мы смотрим из него)
    cv.rect(0, 96, 70, 6, 'grey3'); cv.rect(4, 102, 4, 20, 'grey3'); cv.rect(60, 102, 4, 20, 'grey3')
    cv.rect(84, 70, 20, 34, 'grey4'); cv.rect(84, 102, 22, 6, 'grey3'); cv.rect(86, 108, 3, 18, 'grey4'); cv.rect(100, 108, 3, 18, 'grey4')
    # плюшевый робот на кровати
    cv.rect(196, 80, 12, 10, 'grey2'); cv.px(199, 84, 'black'); cv.px(204, 84, 'black'); cv.rect(198, 90, 8, 6, 'grey3')
    return cv


def cam_mom():
    cv = Canvas(240, 150)
    # силуэт женщины, сидящей на кровати спиной
    cv.ellipse(170, 58, 10, 12, 'black')
    cv.ellipse(170, 50, 12, 10, 'black')
    cv.poly([(156, 68), (184, 68), (192, 104), (148, 104)], 'black')
    cv.poly([(148, 100), (196, 100), (200, 110), (144, 110)], 'black')
    return cv


def cam_dark():
    cv = Canvas(240, 150)
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(150):
        for x in range(240):
            if (B[y % 4][x % 4] + .5) / 16 < .55:
                cv.px(x, y, 'black')
    # отсвет монитора на стене: красное лицо Пикселя
    cv.rect(130, 20, 50, 38, (120, 20, 30, 150))
    cv.rect(141, 32, 6, 6, 'magenta'); cv.rect(163, 32, 6, 6, 'magenta')
    return cv


def person_silhouette():
    """Силуэт человека, стоящего в дверях справа: голова, плечи, руки, тело. Левый край растворяется."""
    cv = Canvas(90, 250)
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    tmp = Canvas(90, 250)
    tmp.ellipse(56, 34, 15, 19, 'black')                       # голова
    tmp.rect(50, 50, 13, 12, 'black')                          # шея
    tmp.poly([(24, 64), (88, 64), (90, 250), (26, 250)], 'black')   # тело
    tmp.ellipse(30, 72, 12, 9, 'black'); tmp.ellipse(84, 72, 10, 9, 'black')  # плечи
    tmp.poly([(18, 70), (32, 70), (28, 176), (16, 176)], 'black')  # рука
    tmp.ellipse(22, 180, 7, 9, 'black')                        # кисть
    for y in range(250):
        for x in range(90):
            if tmp.get(x, y)[3]:
                edge = min(1.0, (x - 10) / 30)                 # к левому краю — дизеринг, как в полутьме
                if (B[y % 4][x % 4] + .5) / 16 < .35 + max(0, edge) * .65:
                    cv.px(x, y, 'black' if x > 40 else 'grey5')
    return cv


# ============================================================ UI
def ui():
    # заголовок окна: вертикальный «полосатый» градиент
    t = Canvas(4, 14)
    rows = ['grapehi', 'grapehi', 'grape', 'grape', 'grape', 'grape', 'grape', 'grape', 'grape', 'grapelo', 'grape', 'grapelo', 'grapelo', 'grapelo']
    for y, c in enumerate(rows):
        t.rect(0, y, 4, 1, c)
    t.save(out('ui_title.png'))
    ti = Canvas(4, 14)
    for y, c in enumerate(rows):
        ti.rect(0, y, 4, 1, {'grapehi': 'grey1', 'grape': 'grey2', 'grapelo': 'grey3'}[c])
    ti.save(out('ui_title_inactive.png'))
    # панель задач
    tb = Canvas(4, 20)
    for y in range(20):
        tb.rect(0, y, 4, 1, 'grapehi' if y < 2 else ('grape' if y < 12 else 'grapelo'))
    tb.rect(0, 0, 4, 1, 'lilac')
    tb.save(out('ui_taskbar.png'))
    tray = Canvas(4, 20)
    for y in range(20):
        tray.rect(0, y, 4, 1, 'trayhi' if y < 4 else 'trayblue')
    tray.save(out('ui_tray.png'))
    # кнопка «Меню»
    st = Canvas(44, 20)
    for y in range(20):
        c = 'minthi' if y < 4 else ('mint' if y < 13 else 'mintlo')
        w = 44 - max(0, (y - 12)) if y > 12 else 44 - max(0, 5 - y) if y < 5 else 44
        st.rect(0, y, w - 1, 1, c)
    st.save(out('ui_start.png'))
    # кнопки с фаской (9-slice 6x6)
    for name, hi, mid, lo in [('btn', 'white', 'win', 'grey2'), ('btn_hover', 'white', 'grey1', 'grey3'),
                              ('btn_press', 'grey2', 'grey1', 'white'), ('btn_primary', 'grapehi', 'grape', 'grapelo'),
                              ('btn_danger', 'pink', 'red', 'dkred')]:
        b = Canvas(6, 6, mid)
        b.rect(0, 0, 6, 1, hi); b.rect(0, 0, 1, 6, hi); b.rect(0, 5, 6, 1, lo); b.rect(5, 0, 1, 6, lo)
        b.frame(0, 0, 6, 6, 'ink') if name != 'btn_press' else None
        b.rect(1, 1, 4, 1, hi); b.rect(1, 4, 4, 1, lo)
        b.save(out(f'ui_{name}.png'))
    # закрыть / свернуть
    for name, col, glyph in [('x', 'red', 'x'), ('min', 'grapehi', '_')]:
        b = Canvas(10, 9, col)
        b.frame(0, 0, 10, 9, 'white')
        if glyph == 'x':
            b.line(3, 2, 6, 6, 'white'); b.line(6, 2, 3, 6, 'white'); b.line(4, 2, 7, 6, 'white'); b.line(7, 2, 4, 6, 'white')
        else:
            b.rect(3, 6, 4, 1, 'white')
        b.save(out(f'ui_{name}.png'))
    # курсор-стрелка
    cur = Canvas(9, 13)
    shape = ["X........", "XX.......", "XWX......", "XWWX.....", "XWWWX....", "XWWWWX...", "XWWWWWX..", "XWWWWWWX.",
             "XWWWWXXXX", "XWXWWX...", "XX.XWWX..", "X...XWX..", "....XX..."]
    for y, row in enumerate(shape):
        for x, ch in enumerate(row):
            if ch == 'X':
                cur.px(x, y, 'ink')
            elif ch == 'W':
                cur.px(x, y, 'white')
    cur.save(out('cursor.png'))
    # осколок-искорка (2 кадра)
    for i in range(2):
        s = Canvas(9, 9)
        r = 4 if i == 0 else 3
        s.line(4, 4 - r, 4, 4 + r, 'yellow'); s.line(4 - r, 4, 4 + r, 4, 'yellow')
        s.px(3, 3, 'yellow2'); s.px(5, 5, 'yellow2'); s.px(5, 3, 'yellow2'); s.px(3, 5, 'yellow2')
        s.px(4, 4, 'white')
        s.save(out(f'shard_{i}.png'))


# ============================================================ ТИТУЛЬНЫЙ ЭКРАН (480x270)
def title_bg():
    cv = Canvas(480, 270, 'black')
    B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(270):
        k = y / 270
        for x in range(480):
            if (B[y % 4][x % 4] + .5) / 16 < .15 + k * .5:
                cv.px(x, y, 'grey5')
    rnd = random.Random(12)
    for _ in range(90):
        x, y = rnd.randint(0, 479), rnd.randint(0, 150)
        cv.px(x, y, rnd.choice(['grey1', 'grey2', 'white', 'grey2']))
    for _ in range(8):
        x, y = rnd.randint(0, 479), rnd.randint(0, 120)
        for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            cv.px(x + dx, y + dy, 'grey1')
    # море
    for y in range(196, 270):
        for x in range(480):
            cv.px(x, y, 'teal' if (B[y % 4][x % 4] + .5) / 16 < .5 + (y - 196) / 150 else 'grey5')
    for i in range(40):
        x, y = rnd.randint(0, 470), rnd.randint(200, 265)
        cv.line(x, y, x + rnd.randint(3, 9), y, 'grey4')
    # скала и маяк
    cv.poly([(150, 214), (200, 188), (280, 186), (330, 214)], 'black')
    cv.poly([(150, 214), (200, 188), (280, 186), (330, 214)], None, 'grey5')
    t = Canvas(480, 270)
    lighthouse(t, 240, base=192, top=100, lamp_color=None)
    # притемнить маяк (ночь)
    for y in range(270):
        for x in range(480):
            p = t.get(x, y)
            if p[3]:
                t.im.putpixel((x, y), (int(p[0] * .45), int(p[1] * .45), int(p[2] * .6), 255))
    cv.paste(t, 0, 0)
    return cv


def title_lamp():
    cv = Canvas(16, 16)
    cv.disc(7.5, 7.5, 6, 'yellow'); cv.disc(6, 6, 2, 'white')
    return cv


if __name__ == '__main__':
    make_wallpapers()
    make_icons()
    make_avatars()
    drawing_tower().save(out('drawing_tower.png'))
    drawing_family().save(out('drawing_family.png'))
    epilogue_wall().save(out('wall_epilogue.png'))
    cam_room().save(out('cam_room.png'))
    cam_mom().save(out('cam_mom.png'))
    cam_dark().save(out('cam_dark.png'))
    person_silhouette().save(out('person.png'))
    ui()
    title_bg().save(out('title_bg.png'))
    title_lamp().save(out('title_lamp.png'))
    print('art ok:', len(os.listdir(OUT)), 'files')


# ============================================================ ФЛАГИ (30x20, сохраняются x4)
def flags():
    F = {}
    def tri(cols, vertical=True):
        def f(cv):
            n = len(cols)
            for i, c in enumerate(cols):
                if vertical:
                    cv.rect(i * 30 // n, 0, (i + 1) * 30 // n - i * 30 // n, 20, c)
                else:
                    cv.rect(0, i * 20 // n, 30, (i + 1) * 20 // n - i * 20 // n, c)
        return f
    def nordic(bg, cross, inner=None):
        def f(cv):
            cv.rect(0, 0, 30, 20, bg)
            cv.rect(8, 0, 4 if not inner else 5, 20, cross); cv.rect(0, 8, 30, 4 if not inner else 5, cross)
            if inner:
                cv.rect(9, 0, 3, 20, inner); cv.rect(0, 9, 30, 3, inner)
        return f
    F['ru'] = tri(['white', 'navy', 'red'], False)
    F['fr'] = tri(['navy', 'white', 'red'])
    F['de'] = tri(['black', 'dkred', 'yellow2'], False)
    F['it'] = tri(['dkgreen', 'white', 'red'])
    def jp(cv): cv.rect(0, 0, 30, 20, 'white'); cv.disc(14.5, 9.5, 5, 'dkred')
    F['jp'] = jp
    F['ua'] = tri(['blue', 'yellow'], False)
    F['pl'] = tri(['white', 'red'], False)
    F['se'] = nordic('blue', 'yellow')
    F['fi'] = nordic('white', 'navy')
    F['no'] = nordic('red', 'white', 'navy')
    F['dk'] = nordic('red', 'white')
    F['is'] = nordic('navy', 'white', 'red')
    def ch(cv): cv.rect(0, 0, 30, 20, 'red'); cv.rect(13, 4, 4, 12, 'white'); cv.rect(9, 8, 12, 4, 'white')
    F['ch'] = ch
    def gr(cv):
        for i in range(9):
            cv.rect(0, i * 20 // 9, 30, (i + 1) * 20 // 9 - i * 20 // 9, 'blue' if i % 2 == 0 else 'white')
        cv.rect(0, 0, 12, 11, 'blue'); cv.rect(5, 0, 2, 11, 'white'); cv.rect(0, 4, 12, 2, 'white')
    F['gr'] = gr
    def us(cv):
        for i in range(13):
            cv.rect(0, i * 20 // 13, 30, max(1, (i + 1) * 20 // 13 - i * 20 // 13), 'red' if i % 2 == 0 else 'white')
        cv.rect(0, 0, 13, 11, 'navy')
        for y in range(1, 11, 2):
            for x in range(1 + (y // 2) % 2, 13, 2):
                cv.px(x, y, 'white')
    F['us'] = us
    def gb(cv):
        cv.rect(0, 0, 30, 20, 'navy')
        cv.line(0, 0, 29, 19, 'white', 3); cv.line(29, 0, 0, 19, 'white', 3)
        cv.line(0, 0, 29, 19, 'red'); cv.line(29, 0, 0, 19, 'red')
        cv.rect(12, 0, 6, 20, 'white'); cv.rect(0, 7, 30, 6, 'white')
        cv.rect(13, 0, 4, 20, 'red'); cv.rect(0, 8, 30, 4, 'red')
    F['gb'] = gb
    def ca(cv):
        cv.rect(0, 0, 30, 20, 'white'); cv.rect(0, 0, 8, 20, 'red'); cv.rect(22, 0, 8, 20, 'red')
        leaf = ["...X...", "..XXX..", "X.XXX.X", "XXXXXXX", ".XXXXX.", "..XXX..", "...X...", "...X..."]
        for y, row in enumerate(leaf):
            for x, chh in enumerate(row):
                if chh == 'X':
                    cv.px(12 + x, 6 + y, 'red')
    F['ca'] = ca
    def br(cv):
        cv.rect(0, 0, 30, 20, 'dkgreen'); cv.poly([(15, 2), (28, 10), (15, 18), (2, 10)], 'yellow'); cv.disc(14.5, 9.5, 5, 'navy')
        cv.line(10, 9, 19, 11, 'white')
    F['br'] = br
    def cn(cv):
        cv.rect(0, 0, 30, 20, 'red')
        for x, y, r in [(5, 5, 2.5), (10, 2, 1), (12, 4, 1), (12, 7, 1), (10, 9, 1)]:
            cv.disc(x, y, r, 'yellow')
    F['cn'] = cn
    def tr(cv):
        cv.rect(0, 0, 30, 20, 'red'); cv.disc(11, 10, 6, 'white'); cv.disc(13, 10, 5, 'red')
        cv.disc(18, 10, 2, 'white')
    F['tr'] = tr
    def es(cv):
        cv.rect(0, 0, 30, 20, 'red'); cv.rect(0, 5, 30, 10, 'yellow'); cv.rect(7, 7, 4, 6, 'dkred'); cv.rect(8, 8, 2, 4, 'yellow2')
    F['es'] = es
    F['nl'] = tri(['red', 'white', 'navy'], False)
    F['be'] = tri(['black', 'yellow', 'red'])
    F['at'] = tri(['red', 'white', 'red'], False)
    F['ie'] = tri(['dkgreen', 'white', 'orange'])
    F['ee'] = tri(['blue', 'black', 'white'], False)
    F['lt'] = tri(['yellow2', 'dkgreen', 'red'], False)
    def cz(cv):
        cv.rect(0, 0, 30, 10, 'white'); cv.rect(0, 10, 30, 10, 'red'); cv.poly([(0, 0), (14, 10), (0, 20)], 'navy')
    F['cz'] = cz
    F['hu'] = tri(['red', 'white', 'dkgreen'], False)
    F['bg'] = tri(['white', 'dkgreen', 'red'], False)
    F['ro'] = tri(['navy', 'yellow', 'red'])
    def in_(cv):
        cv.rect(0, 0, 30, 7, 'orange'); cv.rect(0, 7, 30, 6, 'white'); cv.rect(0, 13, 30, 7, 'dkgreen')
        cv.ring(14.5, 9.5, 2.5, 'navy', 1)
    F['in'] = in_
    def ar(cv):
        cv.rect(0, 0, 30, 20, 'white'); cv.rect(0, 0, 30, 6, 'cyan'); cv.rect(0, 14, 30, 6, 'cyan')
        cv.disc(14.5, 9.5, 2, 'yellow2')
    F['ar'] = ar
    def kz(cv):
        cv.rect(0, 0, 30, 20, 'blue'); cv.disc(15, 8, 3.5, 'yellow')
        for a in range(0, 360, 30):
            cv.px(15 + math.cos(math.radians(a)) * 5.5, 8 + math.sin(math.radians(a)) * 5.5, 'yellow')
        cv.line(10, 14, 20, 14, 'yellow'); cv.line(12, 15, 18, 15, 'yellow')
        cv.rect(1, 1, 2, 18, 'yellow2')
    F['kz'] = kz
    def mayak(cv):
        cv.rect(0, 0, 30, 20, 'black')
        cv.rect(13, 7, 4, 11, 'grey4'); cv.rect(12, 4, 6, 3, 'grey5'); cv.px(15, 5, 'magenta'); cv.px(14, 5, 'magenta')
        cv.poly([(12, 4), (15, 1), (18, 4)], 'dkred')
        for i in range(8):
            cv.px(19 + i, 5 - i // 3, 'dkred'); cv.px(10 - i, 5 - i // 3, 'dkred')
    F['mayak'] = mayak
    for k, f in F.items():
        cv = Canvas(30, 20)
        f(cv)
        cv.frame(0, 0, 30, 20, (0, 0, 0, 60))
        cv.save(out(f'flag_{k}.png'), 4)


# ============================================================ КАРТА (240x180, режется на 3x3 в игре)
def city_map():
    cv = Canvas(240, 180, 'sand')
    cv.dither(0, 0, 240, 180, 'tan', .12)
    # река справа сверху вниз
    for y in range(180):
        x0 = int(176 + 18 * math.sin(y / 30))
        cv.rect(x0, y, 240 - x0, 1, 'blue')
        cv.px(x0, y, 'navy')
    cv.dither(150, 0, 90, 180, 'cyan', .06, mask=lambda x, y: x > 176 + 18 * math.sin(y / 30) + 2)
    # парк и гаражи
    cv.rect(96, 20, 44, 30, 'green'); cv.dither(96, 20, 44, 30, 'dkgreen', .3)
    for i in range(5):
        cv.rect(120 + i * 9, 116, 7, 6, 'grey2'); cv.frame(120 + i * 9, 116, 7, 6, 'grey3')
    # улицы
    for x in (20, 70, 118, 150):
        cv.rect(x, 0, 6, 180, 'white')
    for y in (36, 88, 140):
        cv.rect(0, y, 176, 6, 'white')
    cv.line(150, 30, 190, 12, 'white', 5)
    # дома-кварталы
    rnd = random.Random(3)
    for bx in (0, 26, 76, 124):
        for by in (0, 42, 94, 146):
            w = {0: 20, 26: 44, 76: 42, 124: 26}[bx]
            h = {0: 36, 42: 46, 94: 46, 146: 34}[by]
            if (bx, by) in [(76, 0), (76, 42)] or (bx == 124 and by == 94):
                continue
            cv.rect(bx + 3, by + 3, w - 6, h - 6, rnd.choice(['grey1', 'tan', 'sand']))
            cv.frame(bx + 3, by + 3, w - 6, h - 6, 'brown2')
    # дом Лёвы, школа, магазин
    def house(x, y, roof):
        cv.rect(x, y + 5, 12, 9, 'paper'); cv.frame(x, y + 5, 12, 9, 'ink')
        cv.poly([(x - 2, y + 6), (x + 6, y), (x + 14, y + 6)], roof); cv.poly([(x - 2, y + 6), (x + 6, y), (x + 14, y + 6)], None, 'ink')
        cv.rect(x + 5, y + 9, 3, 5, 'brown')
    house(32, 150, 'red')        # дом
    house(30, 50, 'blue')        # школа
    house(84, 100, 'green')      # магазин
    # водонапорная башня у реки
    cv.rect(196, 30, 8, 14, 'paper'); cv.frame(196, 30, 8, 14, 'ink')
    cv.rect(193, 22, 14, 8, 'grey3'); cv.frame(193, 22, 14, 8, 'ink'); cv.poly([(193, 22), (200, 16), (207, 22)], 'red')
    # маршрут
    route = [(38, 158), (38, 143), (73, 143), (73, 91), (121, 91), (153, 91), (153, 40), (176, 30), (196, 30)]
    for (a, b), (c2, d) in zip(route, route[1:]):
        steps = int(max(abs(c2 - a), abs(d - b)))
        for i in range(0, steps, 4):
            x = a + (c2 - a) * i / steps
            y = b + (d - b) * i / steps
            cv.rect(x - 1, y - 1, 2, 2, 'red')
    # метки
    for x, y, c in [(38, 158, 'red'), (200, 18, 'magenta')]:
        cv.disc(x, y - 8, 3, c); cv.px(x, y - 5, c); cv.px(x, y - 4, c)
    cv.px(200, 8, 'white')
    return cv


def cam_dad():
    cv = Canvas(240, 150, 'black')
    cv.dither(0, 0, 240, 150, 'grey5', .25)
    # лицо папы очень близко, освещено монитором снизу
    cv.ellipse(120, 88, 58, 72, 'grey4')
    cv.ellipse(120, 96, 50, 60, 'grey3')
    cv.dither(62, 16, 116, 64, 'black', .5, mask=lambda x, y: ((x - 120) / 58) ** 2 + ((y - 88) / 72) ** 2 <= 1)
    cv.rect(88, 72, 16, 5, 'black'); cv.rect(136, 72, 16, 5, 'black')
    cv.px(95, 74, 'grey1'); cv.px(143, 74, 'grey1')
    cv.rect(108, 118, 24, 3, 'black')
    cv.dither(62, 110, 116, 40, 'robot2', .15, mask=lambda x, y: ((x - 120) / 50) ** 2 + ((y - 96) / 60) ** 2 <= 1)
    return cv


def knob():
    cv = Canvas(6, 8, 'mint')
    cv.frame(0, 0, 6, 8, 'ink')
    cv.save(out('ui_knob.png'))


if __name__ == '__main__':
    flags()
    city_map().save(out('map_full.png'))
    cam_dad().save(out('cam_dad.png'))
    knob()
    print('extra art ok')


# ============================================================ ФОТО (200x130, «с телефона»)
def _photo_base(sky='sky'):
    cv = Canvas(200, 130, sky)
    return cv


def _stick(cv, x, ground, h, shirt, hair, skirt=False, arms_up=False):
    cv.line(x - 2, ground - h * .35, x - 3, ground, 'grey4', 2); cv.line(x + 2, ground - h * .35, x + 3, ground, 'grey4', 2)
    top = ground - h
    cv.poly([(x - 5, top + 12), (x + 5, top + 12), (x + (8 if skirt else 6), ground - h * .33), (x - (8 if skirt else 6), ground - h * .33)], shirt)
    cv.disc(x, top + 6, 5, 'skin')
    cv.rect(x - 5, top, 11, 3, hair)
    cv.px(x - 2, top + 6, 'ink'); cv.px(x + 2, top + 6, 'ink'); cv.px(x - 1, top + 9, 'ink'); cv.px(x, top + 9, 'ink'); cv.px(x + 1, top + 9, 'ink')
    if arms_up:
        cv.line(x - 5, top + 14, x - 10, top + 6, 'skin', 2); cv.line(x + 5, top + 14, x + 10, top + 6, 'skin', 2)
    else:
        cv.line(x - 5, top + 14, x - 8, top + 26, 'skin', 2); cv.line(x + 5, top + 14, x + 8, top + 26, 'skin', 2)


def photo_river():
    cv = _photo_base()
    cv.dither(0, 0, 200, 50, 'white', .15)
    cv.disc(170, 22, 10, 'yellow')
    cv.rect(0, 70, 200, 60, 'blue'); cv.dither(0, 70, 200, 60, 'navy', .2)
    for x in range(0, 200, 14):
        cv.line(x, 80 + (x % 28) // 4, x + 6, 80 + (x % 28) // 4, 'cyan')
    cv.poly([(0, 88), (120, 92), (200, 104), (200, 130), (0, 130)], 'sand'); cv.dither(0, 88, 200, 42, 'tan', .25)
    for i, (x, h, s, hr) in enumerate([(30, 44, 'grey2', 'grey1'), (46, 40, 'pink2', 'grey1'), (72, 46, 'red', 'yellow2'), (92, 50, 'green', 'dkbrown'), (112, 30, 'blue', 'brown')]):
        _stick(cv, x, 116, h, s, hr, skirt=i in (1, 2), arms_up=i == 4)
    cv.line(36, 76, 60, 58, 'brown', 1); cv.line(60, 58, 64, 90, 'grey2', 1)   # удочка деда
    cv.rect(14, 104, 14, 5, 'grey3'); cv.poly([(16, 101), (26, 101), (24, 104), (18, 104)], 'cyan')  # щука в ведре
    return cv


def photo_tower():
    cv = _photo_base('sky2')
    cv.dither(0, 0, 200, 60, 'white', .12)
    cv.rect(0, 104, 200, 26, 'green'); cv.dither(0, 104, 200, 26, 'dkgreen', .3)
    cv.rect(140, 96, 60, 34, 'blue')
    # кирпичная водонапорная башня
    cv.rect(78, 40, 36, 70, 'brown2')
    for y in range(42, 110, 4):
        cv.line(78, y, 113, y, 'brown')
        for x in range(80 + (y // 4 % 2) * 4, 113, 8):
            cv.px(x, y + 1, 'brown'); cv.px(x, y + 2, 'brown')
    cv.rect(72, 22, 48, 20, 'grey3'); cv.dither(72, 22, 48, 20, 'grey4', .3)
    cv.poly([(70, 22), (96, 10), (122, 22)], 'grey4')
    cv.rect(92, 92, 10, 18, 'grey5'); cv.line(92, 96, 101, 106, 'grey2'); cv.line(101, 96, 92, 106, 'grey2')  # заваренная дверь
    # пожарная лестница сбоку
    for x in (116, 121):
        cv.line(x, 24, x, 108, 'grey5')
    for y in range(26, 108, 5):
        cv.line(116, y, 121, y, 'grey5')
    cv.rect(90, 19, 12, 3, 'grey5')   # люк наверху
    cv.frame(0, 0, 200, 130, 'white')
    return cv


def photo_treehouse():
    cv = _photo_base()
    cv.rect(0, 100, 200, 30, 'green'); cv.dither(0, 100, 200, 30, 'dkgreen', .3)
    cv.rect(96, 40, 12, 64, 'brown')
    cv.disc(102, 30, 34, 'dkgreen'); cv.dither(68, 0, 70, 64, 'green', .3, mask=lambda x, y: (x - 102) ** 2 + (y - 30) ** 2 < 34 ** 2)
    cv.rect(78, 56, 48, 16, 'brown2')
    for x in range(78, 126, 6):
        cv.line(x, 56, x, 71, 'brown')
    cv.poly([(76, 56), (102, 42), (128, 56)], 'red')
    _stick(cv, 60, 118, 30, 'blue', 'brown', arms_up=True)
    _stick(cv, 140, 118, 32, 'orange', 'yellow2', arms_up=True)
    return cv


def photo_school():
    cv = _photo_base()
    cv.rect(0, 20, 200, 80, 'tan'); cv.dither(0, 20, 200, 80, 'brown2', .15)
    for x in range(10, 200, 30):
        cv.rect(x, 34, 18, 20, 'sky'); cv.frame(x, 34, 18, 20, 'paper')
        cv.rect(x, 64, 18, 20, 'sky'); cv.frame(x, 64, 18, 20, 'paper')
    cv.rect(0, 100, 200, 30, 'grey2')
    _stick(cv, 100, 124, 40, 'white', 'brown')
    for dx, c in [(-4, 'red'), (0, 'yellow'), (4, 'pink'), (-2, 'white'), (2, 'orange')]:
        cv.disc(108 + dx, 92 - abs(dx), 2, c)
    cv.line(106, 96, 104, 104, 'dkgreen')
    cv.rect(94, 104, 12, 8, 'navy')   # ранец
    return cv


def photo_screen():
    cv = Canvas(200, 130, 'black')
    cv.dither(0, 0, 200, 130, 'grey5', .25)
    cv.rect(60, 20, 80, 70, 'robot'); cv.frame(58, 18, 84, 74, 'ink'); cv.frame(59, 19, 82, 72, 'ink')
    cv.rect(78, 40, 10, 12, 'ink'); cv.rect(112, 40, 10, 12, 'ink')
    for i, dy in enumerate([0, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 0]):
        cv.px(92 + i, 66 + dy, 'ink')
    cv.rect(98, 6, 4, 12, 'ink'); cv.disc(100, 5, 4, 'red')
    cv.rect(20, 100, 160, 20, 'grey5'); cv.frame(20, 100, 160, 20, 'grey3')
    return cv


def make_photos():
    for n, f in [('photo_river', photo_river), ('photo_tower', photo_tower), ('photo_treehouse', photo_treehouse),
                 ('photo_school', photo_school), ('photo_screen', photo_screen)]:
        cv = f()
        framed = Canvas(208, 138, 'white')
        framed.paste(cv, 4, 4)
        framed.frame(0, 0, 208, 138, 'grey1')
        framed.save(out(n + '.png'))
    icon('photo', lambda c: (c.rect(1, 3, 14, 11, 'white'), c.frame(0, 2, 16, 13, 'ink'), c.rect(2, 4, 12, 9, 'sky'),
                             c.poly([(2, 12), (6, 7), (9, 10), (11, 8), (14, 12)], 'green'), c.disc(11, 6, 1.5, 'yellow')))
    icon('boat', lambda c: (c.rect(0, 11, 16, 5, 'blue'), c.poly([(2, 10), (14, 10), (12, 13), (4, 13)], 'brown'),
                            c.rect(7, 2, 1, 8, 'ink'), c.poly([(8, 2), (13, 8), (8, 8)], 'white'), c.px(3, 1, 'yellow'), c.px(4, 1, 'yellow')))
    icon('shield', lambda c: (c.poly([(8, 0), (15, 3), (14, 10), (8, 15), (2, 10), (1, 3)], 'mint'),
                              c.poly([(8, 0), (15, 3), (14, 10), (8, 15), (2, 10), (1, 3)], None, 'mintlo'), c.line(5, 8, 7, 10, 'white', 2), c.line(7, 10, 11, 5, 'white', 2)))


if __name__ == '__main__':
    make_photos()
    print('photos ok')
