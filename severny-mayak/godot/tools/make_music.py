"""Эмбиент-музыка (синтез, без сэмплов): ре минор, медленно, «музыкальная шкатулка» — тема маяка.
Запуск из папки godot/: python3 tools/make_music.py   (нужны numpy и soundfile: pip install numpy soundfile)
Каждый трек — бесшовная петля OGG 32 кГц, стерео.

Треки:
  m_title  — титульный: тема маяка на шкатулке поверх тёплых пэдов
  m_night0 — ночь, стадия 0: тёпло и грустно, редкие колокольчики
  m_night1 — стадия 1: темнее, ниже, аккорд A (напряжение)
  m_night2 — стадия 2: кластеры, расстроенные пэды, далёкий металл, гул
  m_night3 — стадия 3: гул, обратные наплывы, сердцебиение, сломанная шкатулка
  m_day    — день: тиканье, низкие «струнные», тонкая высокая нота
  m_end    — финал правды: тема маяка в мажоре
"""
import os
import numpy as np
import soundfile as sf

SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'music')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def tt(n):
    return np.arange(n) / SR


class Track:
    def __init__(self, sec, tail=5.0):
        self.L = int(sec * SR)
        self.buf = np.zeros((2, self.L + int(tail * SR)))

    def add(self, sig, at, pan=0.0, vol=1.0):
        s = int(at * SR)
        e = min(s + sig.shape[-1], self.buf.shape[1])
        if e <= s:
            return
        l = np.sqrt(0.5 * (1 - pan)); r = np.sqrt(0.5 * (1 + pan))
        if sig.ndim == 1:
            self.buf[0, s:e] += sig[:e - s] * vol * l
            self.buf[1, s:e] += sig[:e - s] * vol * r
        else:
            self.buf[0, s:e] += sig[0, :e - s] * vol
            self.buf[1, s:e] += sig[1, :e - s] * vol

    def render(self, name, reverb=0.35, decay=3.0, rms=0.07):
        x = self.buf
        if reverb > 0:
            x = x * (1 - reverb * 0.5) + reverb * _reverb(x, decay)
        L = self.L
        out = x[:, :L].copy()
        tail = x[:, L:]
        n = min(tail.shape[1], L)
        out[:, :n] += tail[:, :n]          # хвост петли — в её начало: шов не слышен
        cur = np.sqrt(np.mean(out ** 2)) + 1e-9
        out *= rms / cur
        peak = np.max(np.abs(out))
        if peak > 0.95:
            out *= 0.95 / peak
        sf.write(os.path.join(OUT, name + '.ogg'), out.T.astype(np.float32), SR, format='OGG', subtype='VORBIS')
        print(name, f'{L / SR:.0f}s')


def _reverb(x, decay):
    n = int(decay * SR)
    t = tt(n)
    out = np.zeros_like(x)
    for ch in range(2):
        ir = rng.standard_normal(n) * np.exp(-6.9 * t / decay)
        ir[: int(0.02 * SR)] = 0           # предзадержка
        ir = _lowpass(ir, 5000)
        ir /= np.sqrt(np.sum(ir ** 2))
        size = 1
        while size < x.shape[1] + n:
            size *= 2
        y = np.fft.irfft(np.fft.rfft(x[ch], size) * np.fft.rfft(ir, size), size)
        out[ch] = y[: x.shape[1]]
    return out


def _lowpass(sig, cutoff, highpass=0):
    size = sig.shape[-1]
    spec = np.fft.rfft(sig)
    f = np.fft.rfftfreq(size, 1 / SR)
    g = 1 / np.sqrt(1 + (f / cutoff) ** 4)
    if highpass:
        g *= 1 - 1 / np.sqrt(1 + (f / highpass) ** 4)
    return np.fft.irfft(spec * g, size)


# ---------------------------------------------------------------- инструменты
def pad(midis, dur, bright=6, detune=0.12, attack=2.5, release=3.0, vib=0.0):
    """Тёплый пэд: сумма гармоник с 1/n, по 2 расстроенных голоса на канал, медленная атака."""
    n = int((dur + release) * SR)
    t = tt(n)
    env = np.minimum(1, t / attack) * np.clip(1 - (t - dur) / release, 0, 1)
    out = np.zeros((2, n))
    for m in midis:
        for ch in range(2):
            for k, d in enumerate((-detune, detune)):
                f = hz(m + d + (0.03 if ch else -0.03))
                ph = 2 * np.pi * f * t + (vib * np.sin(2 * np.pi * 0.2 * t) if vib else 0)
                ph += rng.uniform(0, 6.28)
                for h in range(1, bright + 1):
                    if f * h > SR / 2.2:
                        break
                    out[ch] += np.sin(ph * h) / h ** 1.3
    out *= env * (1 + 0.15 * np.sin(2 * np.pi * 0.11 * t))   # медленное «дыхание»
    return out / (len(midis) * 4)


def bell(m, dur=4.0, bright=1.0, detune=0.0):
    """Колокольчик / шкатулка: неровные обертоны, экспоненциальное затухание."""
    n = int(dur * SR)
    t = tt(n)
    f = hz(m + detune)
    out = np.zeros(n)
    for ratio, amp, dec in ((1, 1, 1.0), (2.0, 0.35 * bright, 1.8), (3.01, 0.18 * bright, 2.6), (4.2, 0.08 * bright, 3.5)):
        out += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-dec * 3.2 * t / dur)
    out *= np.minimum(1, t / 0.004)
    return out * 0.5


def metal(m, dur=5.0):
    """Далёкий металлический звон: негармонические обертоны."""
    n = int(dur * SR); t = tt(n); f = hz(m)
    out = sum(a * np.sin(2 * np.pi * f * r * t + rng.uniform(0, 6)) * np.exp(-d * t)
              for r, a, d in ((1, 1, .9), (2.31, .6, 1.3), (3.93, .4, 1.8), (5.07, .3, 2.4), (7.12, .2, 3.0)))
    return out * np.minimum(1, t / 0.01) * 0.3


def swell_rev(m, dur=4.0):
    """Обратный наплыв: колокол, развёрнутый задом наперёд."""
    return bell(m, dur, 1.4)[::-1] * np.linspace(0, 1, int(dur * SR)) ** 2


def heart(dur=0.9):
    n = int(dur * SR); t = tt(n)
    one = np.sin(2 * np.pi * 52 * t) * np.exp(-t * 18)
    two = np.zeros(n); s = int(0.24 * SR)
    two[s:] = one[: n - s] * 0.7
    return (one + two) * 0.9


def tick(dur=0.12):
    n = int(dur * SR); t = tt(n)
    return (np.sin(2 * np.pi * 1800 * t) * 0.5 + rng.standard_normal(n) * 0.3) * np.exp(-t * 90) * 0.25


def hiss(sec, level=0.02, cutoff=3000):
    n = int(sec * SR)
    return np.stack([_lowpass(rng.standard_normal(n), cutoff) for _ in range(2)]) * level


def rumble(sec, level=0.1):
    n = int(sec * SR)
    return np.stack([_lowpass(rng.standard_normal(n), 120, highpass=30) for _ in range(2)]) * level


def cello(m, dur, vol=1.0):
    n = int((dur + 1.5) * SR); t = tt(n)
    f = hz(m)
    ph = 2 * np.pi * f * t + 0.4 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 1.5)
    out = sum(np.sin(ph * h) / h for h in range(1, 9))
    env = np.minimum(1, t / 1.2) * np.clip(1 - (t - dur) / 1.5, 0, 1)
    return out * env * 0.12 * vol


# ---------------------------------------------------------------- тема маяка
THEME = [(74, 1), (77, 1), (81, 2), (79, 1), (77, 1), (76, 2), (74, 1), (72, 1), (69, 2), (70, 2), (69, 2),
         (74, 1), (77, 1), (81, 2), (82, 1), (81, 1), (79, 2), (77, 1), (76, 1), (74, 4)]


def play_theme(tr, start, beat, shift=0, detune=0.0, vol=0.5, major=False, broken=False):
    at = start
    for m, b in THEME:
        if major and m in (77, 82):          # фа → фа-диез, си-бемоль → си: мажор
            m += 1
        if broken and rng.random() < 0.25:   # сломанная шкатулка: ноты выпадают и «плывут»
            at += b * beat
            continue
        d = detune + (rng.uniform(-0.4, 0.4) if broken else 0)
        tr.add(bell(m + shift, 3.5, 0.8, d), at, pan=rng.uniform(-0.3, 0.3), vol=vol)
        at += b * beat
    return at


# ---------------------------------------------------------------- треки
def m_title():
    tr = Track(64)
    chords = [[50, 53, 57], [46, 50, 53], [41, 48, 53, 57], [45, 49, 52]]
    for i in range(8):
        tr.add(pad(chords[i % 4], 8.0, bright=5), i * 8.0, vol=0.9)
    play_theme(tr, 4.0, 0.8, vol=0.55)
    play_theme(tr, 36.0, 0.8, shift=-12, vol=0.35)
    tr.add(hiss(64, 0.012), 0)
    tr.render('m_title', reverb=0.45, decay=3.5, rms=0.08)


def m_night0():
    tr = Track(64)
    chords = [[50, 57, 62, 65], [46, 53, 58, 62], [41, 53, 57, 60], [48, 55, 60, 64]]
    for i in range(8):
        tr.add(pad(chords[i % 4], 8.0, bright=5), i * 8.0)
    scale = [62, 65, 67, 69, 72, 74, 77]
    t = 2.0
    while t < 62:
        tr.add(bell(scale[rng.integers(len(scale))] + 12, 4.0, 0.6), t, pan=rng.uniform(-0.6, 0.6), vol=0.28)
        t += rng.uniform(3.0, 6.5)
    tr.add(hiss(64, 0.014), 0)
    tr.render('m_night0', reverb=0.4, rms=0.06)


def m_night1():
    tr = Track(64)
    chords = [[38, 50, 57, 62], [34, 46, 53, 58], [43, 50, 55, 58], [45, 49, 52, 57]]
    for i in range(8):
        tr.add(pad(chords[i % 4], 8.0, bright=4, detune=0.18), i * 8.0)
    t = 5.0
    while t < 60:
        tr.add(bell([62, 65, 69, 70][rng.integers(4)], 5.0, 0.5, -0.1), t, pan=rng.uniform(-0.7, 0.7), vol=0.22)
        t += rng.uniform(6.0, 10.0)
    tr.add(hiss(64, 0.016, 2000), 0)
    tr.render('m_night1', reverb=0.45, decay=4.0, rms=0.055)


def m_night2():
    tr = Track(64)
    chords = [[38, 50, 51, 57], [34, 46, 47, 53], [36, 48, 49, 55], [33, 45, 46, 52]]
    for i in range(8):
        tr.add(pad(chords[i % 4], 8.0, bright=4, detune=0.35, vib=0.8), i * 8.0)
    t = 6.0
    while t < 58:
        tr.add(metal(rng.integers(70, 84), 6.0), t, pan=rng.uniform(-0.9, 0.9), vol=0.35)
        t += rng.uniform(7.0, 12.0)
    tr.add(rumble(64, 0.12), 0)
    tr.add(hiss(64, 0.02, 1500), 0)
    tr.render('m_night2', reverb=0.55, decay=5.0, rms=0.055)


def m_night3():
    tr = Track(64)
    for i in range(4):   # гул ре + тритон соль-диез
        tr.add(pad([26, 38, 44], 16.0, bright=3, detune=0.5, vib=1.5, attack=4.0), i * 16.0, vol=1.2)
    t = 3.0
    while t < 58:
        m = [62, 63, 68, 74][rng.integers(4)]
        tr.add(swell_rev(m, 4.0), t, pan=rng.uniform(-0.8, 0.8), vol=0.4)
        t += rng.uniform(6.0, 11.0)
    for beat in np.arange(20.0, 44.0, 1.25):   # сердцебиение в середине петли
        tr.add(heart(), beat, vol=0.7)
    play_theme(tr, 46.0, 1.3, shift=-12, detune=-0.4, vol=0.3, broken=True)
    tr.add(rumble(64, 0.18), 0)
    tr.add(hiss(64, 0.025, 1200), 0)
    tr.render('m_night3', reverb=0.6, decay=5.5, rms=0.06)


def m_day():
    tr = Track(60)
    notes = [(38, 10), (36, 10), (34, 10), (33, 10), (38, 10), (37, 10)]
    at = 0.0
    for m, d in notes:
        tr.add(cello(m, d), at, pan=-0.2)
        tr.add(cello(m + 7, d, 0.5), at + 0.5, pan=0.3)
        at += d
    for s in np.arange(0.0, 60.0, 1.0):   # часы на стене
        tr.add(tick(), s, pan=0.5, vol=0.5 if int(s) % 2 else 0.35)
    tr.add(pad([81], 60.0, bright=1, attack=6.0, release=4.0), 0, vol=0.15)
    t = 7.0
    while t < 56:
        tr.add(bell([50, 53, 57][rng.integers(3)], 5.0, 0.3), t, pan=rng.uniform(-0.5, 0.5), vol=0.25)
        t += rng.uniform(8.0, 13.0)
    tr.add(hiss(60, 0.01), 0)
    tr.render('m_day', reverb=0.3, decay=2.5, rms=0.05)


def m_end():
    tr = Track(56)
    chords = [[50, 54, 57], [43, 47, 50, 55], [47, 50, 54], [45, 49, 52, 57], [50, 54, 57, 62], [43, 47, 50, 55], [45, 49, 52], [50, 54, 57, 62]]
    for i, c in enumerate(chords):
        tr.add(pad(c, 7.0, bright=5), i * 7.0)
    play_theme(tr, 3.0, 0.9, vol=0.5, major=True)
    tr.add(hiss(56, 0.01), 0)
    tr.render('m_end', reverb=0.5, decay=4.0, rms=0.07)


if __name__ == '__main__':
    for f in (m_title, m_night0, m_night1, m_night2, m_night3, m_day, m_end):
        f()
