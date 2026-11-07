#!/usr/bin/env python3
"""효과음과 BGM 합성기. 외부 음원 없이 표준 라이브러리로 만든다.

사용: python3 tools/generate_audio.py
결과: assets/audio/sfx/*.wav, assets/audio/bgm/*.wav (22050Hz, 16bit, 모노)
"""
import array
import math
import os
import random
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def osc(kind, phase):
    phase %= 1.0
    if kind == "square":
        return 1.0 if phase < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if phase < 0.25 else -1.0
    if kind == "triangle":
        return 4.0 * abs(phase - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * phase - 1.0
    return math.sin(math.tau * phase)


def tone(buffer, start, duration, freq, kind="square", volume=0.3, end_freq=None, attack=0.005, decay=None):
    """buffer의 start초 위치에 음 하나를 더한다."""
    first = int(start * RATE)
    count = int(duration * RATE)
    if len(buffer) < first + count:
        buffer.extend([0.0] * (first + count - len(buffer)))
    decay = duration if decay is None else decay
    phase = 0.0
    for i in range(count):
        t = i / RATE
        progress = i / count
        current = freq if end_freq is None else freq + (end_freq - freq) * progress
        phase += current / RATE
        envelope = min(t / attack, 1.0) * max(1.0 - t / decay, 0.0)
        buffer[first + i] += osc(kind, phase) * volume * envelope


def noise(buffer, start, duration, volume=0.2, seed=1, step=1):
    """step이 클수록 낮고 거친 소리가 된다."""
    random_source = random.Random(seed)
    first = int(start * RATE)
    count = int(duration * RATE)
    if len(buffer) < first + count:
        buffer.extend([0.0] * (first + count - len(buffer)))
    value = 0.0
    for i in range(count):
        if i % step == 0:
            value = random_source.uniform(-1.0, 1.0)
        buffer[first + i] += value * volume * (1.0 - i / count)


def save(name, buffer, peak=0.85):
    path = os.path.join(ROOT, name + ".wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    loudest = max((abs(s) for s in buffer), default=1.0) or 1.0
    gain = min(peak / loudest, 1.0)
    samples = array.array("h", (int(max(-1.0, min(1.0, s * gain)) * 32767) for s in buffer))
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(samples.tobytes())
    print(name, f"{len(buffer) / RATE:.2f}s")


def arpeggio(notes, step, kind="square", volume=0.3):
    buffer = []
    for i, freq in enumerate(notes):
        tone(buffer, i * step, step * 2.0, freq, kind, volume)
    return buffer


def build_sfx():
    save("sfx/ui_click", _single(880, 0.05, "square", 0.25))
    save("sfx/gacha", _sweep(300, 900, 0.16))
    save("sfx/reveal_c", arpeggio([523, 659], 0.05))
    save("sfx/reveal_b", arpeggio([523, 659, 784], 0.06))
    save("sfx/reveal_a", arpeggio([523, 659, 784, 1047], 0.07, "pulse", 0.35))
    fanfare = arpeggio([523, 659, 784, 1047, 1319, 1568], 0.08, "pulse", 0.35)
    tone(fanfare, 0.45, 0.8, 2093, "triangle", 0.3)
    tone(fanfare, 0.45, 0.8, 1047, "square", 0.15)
    save("sfx/reveal_s", fanfare)
    save("sfx/merge", arpeggio([392, 523, 784], 0.05, "triangle", 0.4))
    save("sfx/upgrade_success", arpeggio([659, 880, 1319], 0.06, "pulse", 0.35))
    save("sfx/upgrade_fail", _sweep(320, 90, 0.35, "saw", 0.3))
    save("sfx/shot", _sweep(1200, 400, 0.06, "square", 0.12))
    explosion = []
    noise(explosion, 0.0, 0.14, 0.3, seed=3, step=3)
    tone(explosion, 0.0, 0.12, 180, "square", 0.2, end_freq=60)
    save("sfx/enemy_die", explosion)
    hit = []
    noise(hit, 0.0, 0.3, 0.4, seed=4, step=6)
    tone(hit, 0.0, 0.3, 140, "saw", 0.35, end_freq=50)
    save("sfx/life_lost", hit)
    siren = []
    for i in range(3):
        tone(siren, i * 0.3, 0.28, 440, "saw", 0.3, end_freq=880)
    save("sfx/boss_warning", siren)
    save("sfx/wave_start", arpeggio([392, 587], 0.08, "triangle", 0.4))
    blast = []
    noise(blast, 0.0, 0.5, 0.35, seed=5, step=4)
    tone(blast, 0.0, 0.5, 900, "saw", 0.3, end_freq=110)
    save("sfx/ultimate", blast)
    save("sfx/augment", arpeggio([440, 660, 880], 0.07, "sine", 0.4))
    save("sfx/zone_place", _sweep(220, 660, 0.14, "triangle", 0.4))
    defeat = []
    for i, freq in enumerate([392, 349, 311, 262]):
        tone(defeat, i * 0.22, 0.4, freq, "saw", 0.3)
    save("sfx/gameover", defeat)
    victory = arpeggio([523, 523, 659, 784], 0.12, "pulse", 0.35)
    tone(victory, 0.48, 0.9, 1047, "square", 0.25)
    tone(victory, 0.48, 0.9, 784, "triangle", 0.25)
    save("sfx/clear", victory)


def _single(freq, duration, kind, volume):
    buffer = []
    tone(buffer, 0.0, duration, freq, kind, volume)
    return buffer


def _sweep(start, end, duration, kind="square", volume=0.3):
    buffer = []
    tone(buffer, 0.0, duration, start, kind, volume, end_freq=end)
    return buffer


def midi(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def build_track(name, bpm, chords, scale, seed, lead_kind, drive):
    """chords는 근음 MIDI 번호 목록이다. 마지막 마디가 첫 마디로 이어지도록 만든다."""
    beat = 60.0 / bpm
    bar = beat * 4.0
    total = bar * len(chords)
    buffer = [0.0] * int(total * RATE)
    random_source = random.Random(seed)
    for index, root in enumerate(chords):
        start = index * bar
        for i in range(8):
            when = start + i * beat / 2.0
            note = root - 12 if i % 4 != 3 else root - 5
            tone(buffer, when, beat / 2.0, midi(note), "triangle", 0.34, decay=beat * 0.7)
            pattern = [0, 7, 12, 7, 3, 7, 12, 15]
            tone(buffer, when, beat / 2.0, midi(root + 12 + pattern[i]), "pulse", 0.07, decay=beat * 0.5)
            if drive:
                noise(buffer, when, 0.03, 0.08, seed=i + 7, step=1)
        if drive:
            for i in range(4):
                when = start + i * beat
                tone(buffer, when, 0.09, 150, "sine", 0.45, end_freq=50)
                if i % 2 == 1:
                    noise(buffer, when, 0.1, 0.16, seed=i + 20, step=2)
        position = 0.0
        while position < bar - 1e-6:
            length = random_source.choice([0.5, 0.5, 1.0, 1.5]) * beat
            length = min(length, bar - position)
            if random_source.random() > 0.2:
                note = root + 12 + random_source.choice(scale)
                tone(buffer, start + position, length, midi(note), lead_kind, 0.16, decay=length * 1.1)
            position += length
    save(name, buffer[:int(total * RATE)], peak=0.7)


def main():
    build_sfx()
    # A단조 계열: 타이틀은 느리고 비어 있게, 전투는 빠르고 밀도 있게
    build_track("bgm/title", 76, [57, 53, 60, 55, 57, 53, 55, 52], [0, 3, 5, 7, 10, 12], 11, "triangle", False)
    build_track("bgm/battle", 132, [57, 57, 53, 55, 57, 57, 60, 52], [0, 3, 5, 7, 10, 12, 15], 12, "square", True)
    build_track("bgm/boss", 150, [52, 52, 53, 53, 50, 50, 52, 51], [0, 1, 3, 6, 7, 10, 12], 13, "saw", True)


if __name__ == "__main__":
    main()
