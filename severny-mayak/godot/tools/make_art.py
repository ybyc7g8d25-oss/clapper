"""Графика версии 3: всё в родном разрешении 480x270 (сохраняется 1:1), приглушённая палитра.
Запуск из папки godot/:  python3 tools/make_art.py
Часть рисунков (значки, рисунки Лёвы, фото, карта, флаги) берётся из генератора версии 2
(old/godot-v2/tools/make_art.py) и перекрашивается в новую палитру."""
import importlib.util
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pix  # noqa: E402
from pix import Canvas, C  # noqa: E402

OUT = os.path.join(HERE, '..', 'art')
os.makedirs(OUT, exist_ok=True)


def out(n):
    return os.path.join(OUT, n + '.png')


def save(cv, n, scale=1):
    cv.save(out(n), scale)


# ---------------------------------------------------------------- приглушённая палитра
MUTED = {
    'rust': '#8a4a3a', 'orange2': '#a8683f', 'sand': '#c9b58f', 'tan': '#b8976c', 'brown2': '#8c6248',
    'brown': '#5e3f35', 'dkbrown': '#3a2b28', 'dkred': '#7a3530', 'red': '#a8443c', 'orange': '#b87440',
    'yellow2': '#b89045', 'yellow': '#d8bd72', 'green': '#6f8a5c', 'dkgreen': '#4d6546', 'dkgreen2': '#34473a',
    'teal': '#263a3b', 'navy': '#34445a', 'blue': '#4f6886', 'cyan': '#8aa8b4', 'white': '#e2d8c3',
    'grey1': '#b3aaa0', 'grey2': '#8a8285', 'grey3': '#645d65', 'grey4': '#45404b', 'grey5': '#2c2a31',
    'black': '#141317', 'magenta': '#cf3f4f', 'plum': '#5a4057', 'pink2': '#8c5a6a', 'pink': '#c08378',
    'skin': '#c9a488', 'skin2': '#9e7a62',
    'grape': '#5a4b75', 'grapehi': '#8574a4', 'grapelo': '#3a3050', 'mint': '#6f9a7d', 'minthi': '#a3c2a2', 'mintlo': '#476a54',
    'sky': '#7f93a3', 'sky2': '#6f8395', 'paper': '#ddd2ba', 'robot': '#8ea9b8', 'robot2': '#6b8795', 'lilac': '#9a8fb0', 'lilac2': '#7a6f92',
    'win': '#c2b8ac', 'line': '#948c8e', 'ink': '#2b2624', 'trayblue': '#3f5068', 'trayhi': '#6c86a0',
}
ORIG = dict(pix.P)


def use_muted():
    pix.P.update(MUTED)


def use_orig():
    pix.P.update(ORIG)


def load_v2():
    path = os.path.join(HERE, '..', '..', 'old', 'godot-v2', 'tools', 'make_art.py')
    spec = importlib.util.spec_from_file_location('v2art', path)
    m = importlib.util.module_from_spec(spec)
    m.__name__ = 'v2art'
    spec.loader.exec_module(m)
    m.out = lambda n: out(n)
    return m


B4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def bayer(x, y):
    return (B4[y % 4][x % 4] + .5) / 16


# ================================================================ ДОМ (480x72)
ROOMS = {  # x-диапазоны комнат
    'kitchen': (0, 116), 'bed': (118, 236), 'hall': (238, 326), 'lev': (328, 480),
}
FLOOR = 66


def house_base(day=False):
    cv = Canvas(480, 72, '#121115')
    # стены комнат (днём — серый пасмурный свет из окон)
    for name, (x0, x1) in ROOMS.items():
        cv.rect(x0, 6, x1 - x0, 60, '#2b2a2f' if day else '#1d1b21')
        cv.dither(x0, 6, x1 - x0, 60, '#343238' if day else '#221f26', .25)
    # потолок и пол
    cv.rect(0, 0, 480, 6, '#0d0c10')
    cv.rect(0, FLOOR, 480, 6, '#2a2621')
    cv.dither(0, FLOOR, 480, 6, '#342f28', .3)
    # перегородки с дверными проёмами (проём — нижние 34 px)
    for x in (116, 236, 326):
        cv.rect(x, 6, 2, 26, '#0d0c10')
    # окна с ночным небом
    def window(x, y, w=22, h=18, moon=False):
        if day:
            cv.rect(x, y, w, h, '#7f8a94')
            cv.dither(x, y, w, h, '#98a2aa', .35)
            cv.rect(x, y + h - 5, w, 5, '#4d5358')  # крыши напротив
            cv.frame(x - 1, y - 1, w + 2, h + 2, '#45414d')
            cv.rect(x + w // 2, y, 1, h, '#45414d')
            cv.rect(x - 2, y + h + 1, w + 4, 1, '#5a5560')
            for yy in range(y + h + 2, min(y + h + 30, 66)):   # полоса света на полу/стене
                for xx in range(x - 2, x + w + 2):
                    if bayer(xx, yy) < .18 * (1 - (yy - y - h) / 30):
                        cv.px(xx, yy, '#4a4850')
            return
        cv.rect(x, y, w, h, '#1e2533')
        cv.dither(x, y, w, h, '#26314a', .3)
        rnd = random.Random(x)
        for _ in range(4):
            cv.px(x + rnd.randint(1, w - 2), y + rnd.randint(1, h - 2), '#6c7a8c')
        if moon:
            cv.disc(x + w - 6, y + 5, 2.5, '#b3aaa0')
        cv.frame(x - 1, y - 1, w + 2, h + 2, '#35313b')
        cv.rect(x + w // 2, y, 1, h, '#35313b')
        cv.rect(x - 2, y + h + 1, w + 4, 1, '#45414d')
    window(40, 18)
    window(160, 18, moon=True)
    window(420, 16)
    # кухня: холодильник, стол, стулья, плита
    cv.rect(6, 24, 14, 42, '#3a3640'); cv.rect(6, 38, 14, 1, '#27242c'); cv.rect(18, 28, 1, 6, '#5a5560'); cv.rect(18, 42, 1, 8, '#5a5560')
    cv.rect(70, 50, 30, 3, '#4a3f36'); cv.rect(72, 53, 2, 13, '#3a312a'); cv.rect(96, 53, 2, 13, '#3a312a')
    cv.rect(64, 44, 2, 22, '#3a312a'); cv.rect(64, 52, 6, 2, '#3a312a')
    cv.rect(26, 50, 16, 16, '#35313b'); cv.rect(28, 48, 12, 2, '#45414d')
    cv.rect(80, 47, 4, 3, '#948c8e')  # чашка
    # спальня родителей: кровать, шкаф
    cv.rect(124, 16, 18, 50, '#2e2a33'); cv.rect(133, 16, 1, 50, '#1d1b21'); cv.px(131, 40, '#5a5560'); cv.px(135, 40, '#5a5560')
    cv.rect(186, 52, 46, 8, '#3d3845'); cv.rect(186, 46, 6, 20, '#2e2a33'); cv.rect(192, 50, 12, 4, '#6b6570')
    cv.rect(186, 60, 46, 6, '#2a2630')
    # коридор: вешалка, входная дверь
    cv.rect(242, 20, 18, 46, '#2d2620'); cv.frame(242, 20, 18, 46, '#3d342b'); cv.px(257, 44, '#948c8e')
    cv.rect(290, 22, 2, 30, '#3a312a'); cv.rect(284, 22, 14, 2, '#3a312a'); cv.rect(286, 26, 5, 14, '#34445a'); cv.rect(293, 26, 4, 18, '#5e3f35')
    cv.rect(300, 60, 10, 6, '#3a312a')  # обувь
    # комната Лёвы: кровать, стол, монитор (это мы), постер
    cv.rect(336, 52, 40, 8, '#3a4453'); cv.rect(336, 46, 5, 20, '#2e2a33'); cv.rect(341, 50, 10, 4, '#6b6570'); cv.rect(336, 60, 40, 6, '#2a2630')
    cv.rect(384, 26, 12, 16, '#2e2a33'); cv.frame(384, 26, 12, 16, '#45414d'); cv.rect(388, 30, 4, 8, '#948c8e')  # постер с маяком
    cv.rect(440, 48, 36, 3, '#4a3f36'); cv.rect(442, 51, 2, 15, '#3a312a'); cv.rect(472, 51, 2, 15, '#3a312a')
    cv.rect(452, 34, 16, 12, '#141317'); cv.frame(451, 33, 18, 14, '#45414d'); cv.rect(459, 46, 2, 2, '#45414d'); cv.rect(455, 47, 10, 1, '#45414d')
    cv.rect(430, 52, 6, 14, '#2e2a33'); cv.rect(428, 44, 2, 22, '#2e2a33')  # стул
    return cv


def monitor_glow(stage_color):
    cv = Canvas(480, 72)
    cx, cy = 460, 40
    for y in range(6, FLOOR):
        for x in range(380, 480):
            d = math.hypot((x - cx) * 0.8, (y - cy) * 1.4)
            if d < 50 and bayer(x, y) < (1 - d / 50) * .55:
                cv.px(x, y, stage_color)
    cv.rect(453, 35, 14, 10, stage_color)
    return cv


def room_light(name):
    x0, x1 = ROOMS[name]
    cv = Canvas(480, 72)
    cx = (x0 + x1) // 2
    cv.rect(cx - 4, 6, 8, 2, '#c49a45')  # лампа
    for y in range(8, FLOOR + 3):
        w = 8 + (y - 8) * 1.2
        for x in range(x0, x1):
            if abs(x - cx) < w and bayer(x, y) < .32 * (1 - (y - 8) / 80):
                cv.px(x, y, '#c49a45')
    return cv


def person(kind, frame):
    """Силуэт человека 12x26: mom — длинные волосы, халат; dad — выше, короткая стрижка."""
    cv = Canvas(12, 26)
    body = '#0b0a0d'
    rim = '#4d4852'
    h = 26 if kind == 'dad' else 24
    top = 26 - h
    if frame == 'lie':
        cv = Canvas(26, 12)
        cv.rect(2, 6, 20, 4, body); cv.disc(22, 6, 3, body); cv.rect(2, 6, 20, 1, rim)
        return cv
    if frame == 'sit':
        cv.disc(6, top + 5, 3, body)
        cv.rect(4, top + 8, 5, 8, body); cv.rect(4, top + 16, 7, 3, body); cv.rect(9, top + 16, 2, 8, body)
        cv.px(8, top + 4, rim)
        return cv
    if kind == 'cop':
        h = 26; top = 0
        cv.disc(6, top + 3.5, 3, body)
        cv.poly([(3, top + 7), (9, top + 7), (10, top + 20), (2, top + 20)], body)   # длинное пальто
        leg = [(4, 7), (3, 8), (5, 7)][frame if isinstance(frame, int) else 0]
        cv.rect(leg[0], top + 20, 2, 6, body); cv.rect(leg[1] + 3, top + 20, 2, 6, body)
        cv.rect(10, top + 11, 2, 5, '#6b5a3f')                                        # папка с делом
        cv.px(8, top + 2, rim); cv.px(9, top + 4, rim); cv.rect(9, top + 8, 1, 10, rim)
        return cv
    cv.disc(6, top + 3.5, 3, body)
    if kind == 'mom':
        cv.rect(3, top + 3, 2, 8, body); cv.rect(8, top + 3, 1, 6, body)   # волосы
        cv.poly([(3, top + 8), (9, top + 8), (10, top + 19), (2, top + 19)], body)  # халат
    else:
        cv.rect(3, top + 7, 7, 10, body)
    leg = [(4, 7), (3, 8), (5, 7)][frame if isinstance(frame, int) else 0]
    cv.rect(leg[0], top + 17 if kind == 'dad' else top + 19, 2, h - 17 if kind == 'dad' else h - 19, body)
    cv.rect(leg[1] + 3, top + 17 if kind == 'dad' else top + 19, 2, h - 17 if kind == 'dad' else h - 19, body)
    cv.px(8, top + 2, rim); cv.px(9, top + 4, rim); cv.rect(9, top + 9, 1, 6, rim)
    return cv


def make_house():
    save(house_base(), 'house')
    save(house_base(True), 'house_day')
    for r in ROOMS:
        save(room_light(r), 'light_' + r)
    save(monitor_glow('#6c86a0'), 'glow_mon')
    save(monitor_glow('#cf3f4f'), 'glow_mon_red')
    for k in ('mom', 'dad', 'cop'):
        for f in (0, 1, 2, 'sit', 'lie'):
            save(person(k, f), f'p_{k}_{f}')


# ================================================================ ОБОИ: фото «с папой на рыбалке» (480x186)
def wallpaper(with_boy=True, dark=False):
    W, H = 480, 246
    O = H - 186                     # на сколько стол стал выше: небо растёт вверх
    cv = Canvas(W, H)
    # закатное небо полосами
    sky = ['#3f3a4a', '#554a57', '#7a5f5d', '#9b7560', '#b88d64', '#c9a26f']
    for y in range(110 + O):
        k = y / (110 + O) * (len(sky) - 1)
        i = int(k)
        c = sky[i] if bayer(0, y) + (k - i) < 1 or i + 1 >= len(sky) else sky[i + 1]
        for x in range(W):
            cv.px(x, y, sky[i] if bayer(x, y) > (k - i) else sky[min(i + 1, len(sky) - 1)])
    cv.disc(330, 96 + O, 16, '#dcc07a'); cv.disc(330, 96 + O, 12, '#e8d59a')
    # дальний берег и деревья
    rnd = random.Random(3)
    for x in range(W):
        h = 96 + O + int(4 * math.sin(x / 40) + rnd.random() * 2)
        for y in range(h, 112 + O):
            cv.px(x, y, '#2e2a33')
        if rnd.random() < .12:
            th = rnd.randint(4, 12)
            for y in range(h - th, h):
                cv.px(x, y, '#27242c')
    # вода с отражением солнца
    for y in range(110 + O, H):
        for x in range(W):
            c = '#3a3a47' if bayer(x, y) < .5 + (y - 110 - O) / 200 else '#4a4552'
            cv.px(x, y, c)
    for y in range(112 + O, 150 + O, 3):
        w = 20 - (y - 112 - O) // 3
        cv.rect(330 - w, y, w * 2, 1, '#b89c64')
    # мостки
    cv.rect(0, 146 + O, 260, 6, '#3a2f28'); cv.rect(0, 146 + O, 260, 1, '#5e4a3c')
    for x in range(10, 260, 36):
        cv.rect(x, 152 + O, 4, 34, '#2b231e')
    # папа (сидит с удочкой)
    def fisher(x, big, boy=False):
        s = '#1b1820'
        cv0 = cv
        class Sh:  # сдвиг на O вниз
            def disc(self, x, y, *a): cv0.disc(x, y + O, *a)
            def rect(self, x, y, *a): cv0.rect(x, y + O, *a)
            def line(self, x0, y0, x1, y1, *a): cv0.line(x0, y0 + O, x1, y1 + O, *a)
        c2 = Sh()
        h = 30 if big else 20
        c2.disc(x, 146 - h, 4 if big else 3, s)
        c2.rect(x - 4 if big else x - 3, 146 - h + 4, 8 if big else 6, h - 10, s)
        c2.rect(x - 2, 140, 10 if big else 8, 4, s)
        c2.rect(x + 6 if big else x + 4, 144, 2, 10 if big else 8, s)
        rx = x + (40 if big else 30)
        c2.line(x + 2, 146 - h + 10, rx, 146 - h - (24 if big else 18), '#1b1820')
        c2.line(rx, 146 - h - (24 if big else 18), rx + 4, 160, '#6b6570')
        if boy:
            c2.rect(x - 3, 146 - h + 2, 6, 2, '#2e3a4f')  # кепка
    fisher(120, True)
    if with_boy:
        fisher(170, False, True)
    # рамка «фото»
    if dark:
        for y in range(H):
            for x in range(W):
                if bayer(x, y) < .25:
                    cv.px(x, y, '#121115')
    return cv


def make_wallpapers():
    save(wallpaper(True), 'wall')
    save(wallpaper(False), 'wall_alone')
    save(wallpaper(False, True), 'wall_dark')


# ================================================================ ПИКСЕЛЬ: портрет 32x32 (из v2, перекрашенный)
def make_portraits(v2):
    for s in range(4):
        save(v2.avatar(s), f'pix_{s}')
        save(v2.avatar(s, True), f'pix_{s}_talk')
    save(v2.scare_face(), 'scare', 2)


# ================================================================ ЗНАЧКИ 16x16 (из v2, перекрашенные)
def make_icons(v2):
    names = [('note', v2.ic_note), ('noteRed', lambda c: v2.ic_note(c, True)), ('folder', v2.ic_folder), ('pixel', v2.ic_pixel),
             ('pixelDark', lambda c: v2.ic_pixel(c, True)), ('web', v2.ic_web), ('mail', v2.ic_mail), ('tale', v2.ic_tale),
             ('diary', v2.ic_diary), ('cam', v2.ic_cam), ('chat', v2.ic_chat), ('bin', v2.ic_bin), ('tm', v2.ic_tm),
             ('warn', v2.ic_warn), ('stop', v2.ic_stop), ('info', v2.ic_info), ('star', v2.ic_star), ('eye', v2.ic_eye)]
    for n, f in names:
        cv = Canvas(16, 16)
        f(cv)
        save(cv, 'icon_' + n)
    # новые: фото, микрофон, щит, карта, лупа, доска
    cv = Canvas(16, 16); cv.rect(1, 3, 14, 11, 'white'); cv.frame(0, 2, 16, 13, 'ink'); cv.rect(2, 4, 12, 9, 'sky')
    cv.poly([(2, 12), (6, 7), (9, 10), (11, 8), (14, 12)], 'green'); cv.disc(11, 6, 1.5, 'yellow'); save(cv, 'icon_photo')
    cv = Canvas(16, 16); cv.rect(6, 1, 4, 8, 'grey1'); cv.frame(5, 0, 6, 10, 'grey3'); cv.line(3, 7, 3, 9, 'ink'); cv.line(12, 7, 12, 9, 'ink')
    cv.line(3, 10, 12, 10, 'ink'); cv.rect(7, 11, 2, 3, 'ink'); cv.rect(4, 14, 8, 1, 'ink'); save(cv, 'icon_mic')
    cv = Canvas(16, 16); pts = [(8, 0), (15, 3), (14, 10), (8, 15), (2, 10), (1, 3)]
    cv.poly(pts, 'mint'); cv.poly(pts, None, 'mintlo'); cv.line(5, 8, 7, 10, 'white'); cv.line(7, 10, 11, 5, 'white'); save(cv, 'icon_shield')
    cv = Canvas(16, 16); cv.rect(1, 2, 14, 12, 'sand'); cv.frame(0, 1, 16, 14, 'ink'); cv.line(5, 2, 5, 13, 'tan'); cv.line(10, 2, 10, 13, 'tan')
    cv.line(2, 11, 13, 4, 'red'); cv.disc(12, 4, 1.5, 'red'); save(cv, 'icon_map')
    cv = Canvas(16, 16); cv.disc(6, 6, 4, 'robot'); cv.ring(6, 6, 5, 'grey1', 2); cv.line(10, 10, 14, 14, 'tan', 2); save(cv, 'icon_lens')
    cv = Canvas(16, 16); cv.rect(0, 1, 16, 13, 'tan'); cv.frame(0, 1, 16, 13, 'brown'); cv.rect(2, 3, 5, 4, 'paper'); cv.rect(9, 4, 5, 3, 'paper')
    cv.rect(3, 9, 6, 3, 'paper'); cv.px(4, 3, 'red'); cv.px(11, 4, 'red'); cv.px(5, 9, 'red'); cv.line(4, 4, 11, 5, 'red'); save(cv, 'icon_board')
    cv = Canvas(16, 16); cv.rect(1, 11, 14, 3, 'brown2'); cv.rect(3, 14, 10, 1, 'brown')      # кораблик
    cv.rect(7, 2, 1, 9, 'ink'); cv.poly([(8, 2), (14, 10), (8, 10)], 'white'); cv.poly([(6, 4), (2, 10), (6, 10)], 'paper')
    save(cv, 'icon_boat')
    cv = Canvas(16, 16); cv.rect(1, 3, 14, 12, 'navy'); cv.frame(0, 2, 16, 14, 'grey1'); cv.rect(1, 12, 14, 3, 'tan')   # аквариум
    cv.rect(5, 6, 5, 3, 'orange'); cv.rect(10, 5, 2, 5, 'orange2'); cv.px(6, 7, 'ink'); cv.px(3, 4, 'cyan'); cv.px(12, 3, 'cyan')
    save(cv, 'icon_fish')
    cv = Canvas(16, 16); cv.rect(2, 1, 12, 14, 'grey5'); cv.frame(2, 1, 12, 14, 'grape')      # сон
    cv.disc(8, 7, 3, 'grapehi'); cv.disc(9, 6, 2.5, 'grey5'); cv.px(5, 12, 'grapehi'); cv.px(8, 12, 'grapehi'); cv.px(11, 12, 'grapehi')
    save(cv, 'icon_dream')
    cv = Canvas(16, 16); v2.ic_folder(cv)
    for y in range(16):
        for x in range(16):
            if (x + y) % 2 == 0 and cv.im.getpixel((x, y))[3] > 0:
                cv.im.putpixel((x, y), (0, 0, 0, 0))
    save(cv, 'icon_cache')
    cv = Canvas(16, 16); cv.rect(0, 0, 16, 16, 'grey5'); cv.frame(0, 0, 16, 16, 'grey3'); cv.rect(3, 7, 10, 2, 'red')
    cv.rect(3, 3, 2, 2, 'grey2'); cv.rect(7, 3, 2, 2, 'grey2'); save(cv, 'icon_flags')


# ================================================================ ДОКУМЕНТЫ-КАРТИНКИ (из v2, перекрашенные)
def make_docs(v2):
    save(v2.drawing_tower(), 'drawing_tower')
    save(v2.drawing_family(), 'drawing_family')
    # «жуткий» вариант: маму и папу кто-то зачеркнул тёмным мелком (появляется во 2-ю ночь)
    from PIL import Image, ImageDraw
    im = Image.open(out('drawing_family')).convert('RGBA')
    d = ImageDraw.Draw(im)
    rnd = random.Random(7)
    for x0, x1 in ((14, 56), (64, 106)):
        for _ in range(26):
            y = rnd.randint(16, 140)
            d.line([(x0 + rnd.randint(-2, 4), y), (x1 + rnd.randint(-4, 2), y + rnd.randint(-10, 10))], fill=(38, 33, 36, 255), width=1)
    im.save(out('drawing_family_x'))
    wb = v2.wall_base()
    for layer in (v2.lamp_layer('yellow', 'yellow'), v2.tower_layer(), v2.lamp_disc('yellow')):
        wb.paste(layer, 0, 0)
    v2.boy(wb, 150, 222)
    small = wb.im.resize((240, 125))
    c2 = Canvas(240, 125); c2.im = small; save(c2, 'drawing_me')
    save(v2.cam_room(), 'cam_room')
    save(v2.cam_mom(), 'cam_mom')
    save(v2.cam_dad(), 'cam_dad')
    save(v2.cam_dark(), 'cam_dark')
    save(v2.city_map(), 'map_full')
    for n, f in [('photo_river', v2.photo_river), ('photo_tower', v2.photo_tower), ('photo_treehouse', v2.photo_treehouse),
                 ('photo_screen', v2.photo_screen)]:
        cv = f()
        framed = Canvas(208, 138, 'white'); framed.paste(cv, 4, 4); framed.frame(0, 0, 208, 138, 'grey1')
        save(framed, n)
    save(v2.title_bg(), 'title_bg')
    save(v2.title_lamp(), 'title_lamp')
    save(v2.epilogue_wall(), 'wall_epilogue_src')


def make_flags(v2):
    """Флаги — в своих цветах, чуть приглушённые (как в Papers Please)."""
    use_orig()
    tmp = os.path.join(OUT, '_tmpflags')
    os.makedirs(tmp, exist_ok=True)
    v2.out = lambda n: os.path.join(tmp, n if n.endswith('.png') else n + '.png')
    v2.flags()
    from PIL import Image, ImageEnhance
    for f in os.listdir(tmp):
        im = Image.open(os.path.join(tmp, f)).convert('RGBA').resize((60, 40), Image.NEAREST)
        rgb = ImageEnhance.Color(im.convert('RGB')).enhance(0.62)
        rgb = ImageEnhance.Brightness(rgb).enhance(0.9)
        rgb.putalpha(im.getchannel('A'))
        rgb.save(os.path.join(OUT, f))
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)
    v2.out = lambda n: out(n)
    use_muted()


# ================================================================ UI
def make_ui():
    cv = Canvas(4, 6, '#c49a45'); cv.frame(0, 0, 4, 6, '#2b2624'); save(cv, 'ui_knob')
    cv = Canvas(7, 7, '#ddd2ba'); cv.frame(0, 0, 7, 7, '#2b2624'); save(cv, 'ui_check_off')
    cv = Canvas(7, 7, '#ddd2ba'); cv.frame(0, 0, 7, 7, '#2b2624'); cv.rect(2, 2, 3, 3, '#a8443c'); save(cv, 'ui_check_on')
    cv = Canvas(7, 7, '#a8443c'); cv.frame(0, 0, 7, 7, '#2b2624'); cv.line(2, 2, 4, 4, '#ddd2ba'); cv.line(4, 2, 2, 4, '#ddd2ba'); save(cv, 'ui_x')
    # курсор (9x12) и лупа-курсор
    cur = Canvas(8, 11)
    shape = ["X.......", "XX......", "XWX.....", "XWWX....", "XWWWX...", "XWWWWX..", "XWWWWWX.", "XWWWXXXX", "XWXWX...", "XX.XWX..", "....XX.."]
    for y, row in enumerate(shape):
        for x, ch in enumerate(row):
            if ch == 'X': cur.px(x, y, '#121115')
            elif ch == 'W': cur.px(x, y, '#ddd2ba')
    save(cur, 'cursor')
    lens = Canvas(11, 11); lens.ring(4, 4, 3, '#121115', 1); lens.ring(4, 4, 4, '#ddd2ba', 1); lens.line(7, 7, 10, 10, '#121115', 2)
    save(lens, 'cursor_lens')
    # осколок
    for i in range(2):
        s = Canvas(7, 7); r = 3 if i == 0 else 2
        s.line(3, 3 - r, 3, 3 + r, '#e3c983'); s.line(3 - r, 3, 3 + r, 3, '#e3c983'); s.px(3, 3, '#ffffff')
        save(s, f'shard_{i}')
    # печать «ВЕРНО» — рамка (текст рисуется в игре)
    st = Canvas(64, 20)
    st.frame(0, 0, 64, 20, '#a8443c'); st.frame(1, 1, 62, 18, '#a8443c'); st.frame(3, 3, 58, 14, '#a8443c')
    rnd = random.Random(2)
    for _ in range(40):
        st.px(rnd.randint(0, 63), rnd.randint(0, 19), None)
    save(st, 'stamp')
    # бумага (шум) для доски и газеты
    for n, base, dots, w, h in [('paper', '#ddd2ba', '#cfc2a6', 64, 64), ('cork', '#6b5642', '#5a4636', 64, 64)]:
        cv = Canvas(w, h, base)
        rnd = random.Random(len(n))
        for _ in range(w * h // 6):
            cv.px(rnd.randint(0, w - 1), rnd.randint(0, h - 1), dots)
        save(cv, 'tex_' + n)
    # кнопка «пин» для карточек доски
    p = Canvas(5, 5); p.disc(2, 2, 2, '#a8443c'); p.px(1, 1, '#d0695c'); save(p, 'pin')


def make_epilogue(v2):
    save(v2.epilogue_wall().im and v2.epilogue_wall(), 'epi_src')


if __name__ == '__main__':
    use_muted()
    v2 = load_v2()
    make_house()
    make_wallpapers()
    make_portraits(v2)
    make_icons(v2)
    make_docs(v2)
    make_ui()
    make_flags(v2)
    print('v3 art ok:', len([f for f in os.listdir(OUT) if f.endswith('.png')]), 'png')
