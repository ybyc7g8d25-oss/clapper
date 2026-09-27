"""Генератор звуков (WAV 22050 Гц, 16 бит). Запуск: python3 tools/make_sfx.py (из папки godot/)."""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'sfx')
os.makedirs(OUT, exist_ok=True)


def save(name, data):
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(s * 32767)))) for s in data))


def buf(sec):
    return [0.0] * int(SR * sec)


def osc(kind, ph):
    ph %= 1
    if kind == 'sine': return math.sin(ph * 2 * math.pi)
    if kind == 'square': return 1.0 if ph < .5 else -1.0
    if kind == 'saw': return ph * 2 - 1
    if kind == 'tri': return 4 * abs(ph - .5) - 1


def tone(b, f, dur, kind='sine', vol=.3, at=0.0, attack=.005, slide=0.0):
    s0 = int(at * SR); n = int(dur * SR); ph = 0
    for i in range(n):
        if s0 + i >= len(b): break
        t = i / SR
        env = min(1, t / attack) * math.exp(-5 * t / dur)
        ph += (f + slide * t / dur) / SR
        b[s0 + i] += osc(kind, ph) * vol * env


def noise(b, dur, vol=.3, at=0.0, lp=.5, seed=1):
    rnd = random.Random(seed); s0 = int(at * SR); n = int(dur * SR); y = 0
    for i in range(n):
        if s0 + i >= len(b): break
        y += (rnd.uniform(-1, 1) - y) * lp
        b[s0 + i] += y * vol * (1 - i / n)


b = buf(.05); tone(b, 1500, .03, 'square', .12); save('click', b)
for i, f in enumerate([900, 1000, 430, 180]):
    b = buf(.04); tone(b, f, .025, 'square', .07); save(f'tick{i}', b)
b = buf(.03); tone(b, 2300, .015, 'square', .06); save('key', b)
b = buf(.5); tone(b, 230, .18, 'square', .18); tone(b, 160, .28, 'square', .18, .16); save('err', b)
b = buf(.3); tone(b, 990, .09, 'sine', .3); tone(b, 1320, .14, 'sine', .3, .09); save('msg', b)
b = buf(1.2); [tone(b, f, .9, 'sine', .18, i * .09) for i, f in enumerate([1318, 1760, 2093])]; save('shard', b)
b = buf(.25); noise(b, .2, .6, lp=.9, seed=3); save('glitch', b)
b = buf(.8); noise(b, .6, .9, lp=.15, seed=5); tone(b, 62, .7, 'saw', .5); tone(b, 1900, .5, 'square', .1); save('scare', b)
b = buf(.45); noise(b, .25, .8, lp=.08, seed=7); tone(b, 70, .3, 'sine', .5, .02); save('door', b)
b = buf(.2); noise(b, .09, .7, lp=.06, seed=9); tone(b, 48, .12, 'sine', .5); save('step', b)
b = buf(.5); tone(b, 55, .14, 'sine', .7); tone(b, 50, .16, 'sine', .55, .2); save('heart', b)
b = buf(1.2); [tone(b, f, .55, 'tri', .22, i * .13) for i, f in enumerate([523, 659, 784, 1046])]; save('chime', b)
b = buf(2.4); [tone(b, f, .8, 'tri', .2, i * .35) for i, f in enumerate([784, 659, 523, 392])]; save('sad', b)
b = buf(2.2); [tone(b, f, 1.2, 'sine', .18, i * .5) for i, f in enumerate([392, 523, 659])]; save('soft', b)
# гул по стадиям: бесшовные петли по 4 секунды (целое число периодов)
for st, (vol, cut) in enumerate([(.05, .02), (.12, .03), (.26, .05), (.45, .08)]):
    n = SR * 4; b = [0.0] * n; y = 0
    for i in range(n):
        t = i / SR
        v = osc('saw', 55 * t) * .6 + math.sin(2 * math.pi * 58.25 * t) * .5 + math.sin(2 * math.pi * 110.5 * t) * .25
        if st >= 2: v += math.sin(2 * math.pi * 36.75 * t) * .4
        y += (v - y) * cut
        b[i] = y * vol
    save(f'drone{st}', b)
b = buf(.35); noise(b, .12, .9, lp=.3, seed=11); tone(b, 90, .2, 'sine', .6); save('stamp', b)
b = buf(.3); noise(b, .25, .25, lp=.6, seed=13); save('paper', b)
b = buf(1.6)
for k in range(2):
    for i in range(12):
        tone(b, 880 if i % 2 else 660, .05, 'square', .12, k * .7 + i * .04)
save('ring', b)
b = buf(.12); noise(b, .05, .5, lp=.7, seed=17); tone(b, 1800, .03, 'square', .05); save('type', b)
print('sfx ok')
