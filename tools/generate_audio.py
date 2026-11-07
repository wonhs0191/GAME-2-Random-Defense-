#!/usr/bin/env python3
"""효과음과 BGM 합성기. 외부 음원 없이 표준 라이브러리로 만든다.

사용: python3 tools/generate_audio.py [곡 이름 ...]
결과: assets/audio/sfx/*.wav (모노), assets/audio/bgm/*.wav (스테레오), 22050Hz 16bit

BGM은 곡 끝에서 넘친 소리를 곡 앞에 되감아 넣어 이음매 없이 반복된다.
"""
import array
import math
import multiprocessing
import os
import random
import sys
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
    roll = []
    for i, freq in enumerate([523, 587, 659, 784, 880, 1047]):
        tone(roll, i * 0.045, 0.05, freq, "square", 0.22)
    tone(roll, 0.27, 0.22, 1568, "sine", 0.3)
    save("sfx/gacha", roll)
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



# ---------------------------------------------------------------- BGM 합성

NOTE_NAMES = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
              "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11, "B#": 12}
CHORDS = {"m": (0, 3, 7), "": (0, 4, 7), "m7": (0, 3, 7, 10), "7": (0, 4, 7, 10), "maj7": (0, 4, 7, 11),
          "m9": (0, 3, 7, 10, 14), "sus4": (0, 5, 7, 10), "add9": (0, 4, 7, 14), "dim": (0, 3, 6, 9)}
TABLE_SIZE = 2048

# 파트별 음량. 낮은 음이 선율을 덮지 않도록 대역별 에너지를 재서 맞췄다
BASS_LEVEL = 0.6
KICK_LEVEL = 0.7
PAD_LEVEL = 1.4
PLUCK_LEVEL = 1.5
LEAD_LEVEL = 1.7
_tables = {}
_noise = None


def note(name):
    """'A4' 같은 음 이름을 MIDI 번호로 바꾼다. None은 쉼표다."""
    if name is None:
        return None
    return NOTE_NAMES[name[:-1]] + (int(name[-1]) + 1) * 12


def chord_notes(symbol, octave=3):
    """'Am7' 같은 코드 이름을 MIDI 번호 목록으로 바꾼다."""
    length = 2 if len(symbol) > 1 and symbol[1] in "#b" else 1
    root = NOTE_NAMES[symbol[:length]] + (octave + 1) * 12
    return [root + step for step in CHORDS[symbol[length:]]]


def wavetable(kind, freq):
    """에일리어싱이 생기지 않도록 나이퀴스트 아래 배음만으로 파형표를 만든다."""
    limit = max(1, int(RATE / 2 / freq))
    limit = 2 ** int(math.log2(limit)) if limit > 1 else 1
    key = (kind, limit)
    if key not in _tables:
        table = array.array("d", [0.0]) * (TABLE_SIZE + 1)
        for k in range(1, limit + 1):
            if kind == "square" and k % 2 == 0:
                continue
            amp = {"saw": 1.0 / k, "square": 1.0 / k, "soft": 1.0 / (k * k)}[kind]
            for i in range(TABLE_SIZE):
                table[i] += amp * math.sin(math.tau * k * i / TABLE_SIZE)
        peak = max(abs(v) for v in table) or 1.0
        for i in range(TABLE_SIZE + 1):
            table[i] /= peak
        table[TABLE_SIZE] = table[0]
        _tables[key] = table
    return _tables[key]


def render_osc(kind, freq, count, detune=0.0, start_phase=0.0, vibrato=0.0, vibrato_rate=5.0):
    table = wavetable(kind, freq)
    step = freq * (1.0 + detune) * TABLE_SIZE / RATE
    position = (start_phase % 1.0) * TABLE_SIZE
    out = array.array("d", [0.0]) * count
    if vibrato == 0.0:
        for i in range(count):
            index = int(position)
            fraction = position - index
            out[i] = table[index] + (table[index + 1] - table[index]) * fraction
            position += step
            if position >= TABLE_SIZE:
                position -= TABLE_SIZE
        return out
    omega = math.tau * vibrato_rate / RATE
    for i in range(count):
        index = int(position)
        fraction = position - index
        out[i] = table[index] + (table[index + 1] - table[index]) * fraction
        position += step * (1.0 + vibrato * math.sin(omega * i))
        if position >= TABLE_SIZE:
            position -= TABLE_SIZE
    return out


def lowpass(buffer, cutoff_start, cutoff_end=None):
    """한 극 저역 필터를 두 번 걸어 부드럽게 깎는다. 차단 주파수는 시간에 따라 움직일 수 있다."""
    cutoff_end = cutoff_start if cutoff_end is None else cutoff_end
    count = len(buffer)
    low1 = low2 = 0.0
    for i in range(count):
        cutoff = cutoff_start + (cutoff_end - cutoff_start) * i / count
        a = 1.0 - math.exp(-math.tau * cutoff / RATE)
        low1 += a * (buffer[i] - low1)
        low2 += a * (low1 - low2)
        buffer[i] = low2
    return buffer


def envelope(buffer, attack, release, decay_rate=0.0):
    count = len(buffer)
    attack_samples = max(1, int(attack * RATE))
    release_samples = max(1, int(release * RATE))
    for i in range(count):
        gain = min(i / attack_samples, 1.0) * min((count - i) / release_samples, 1.0)
        if decay_rate:
            gain *= math.exp(-decay_rate * i / RATE)
        buffer[i] *= gain
    return buffer


def get_noise():
    global _noise
    if _noise is None:
        source = random.Random(99)
        _noise = array.array("d", (source.uniform(-1.0, 1.0) for _ in range(RATE)))
    return _noise


class Track:
    """스테레오 믹스. 스템별로 모아 사이드체인과 공간 효과를 건다."""

    def __init__(self, bpm, bars):
        self.beat = 60.0 / bpm
        self.length = int(self.beat * 4 * bars * RATE)
        self.stems = {name: (array.array("d", [0.0]) * self.length, array.array("d", [0.0]) * self.length)
                      for name in ("pad", "main", "drum")}
        self.send = array.array("d", [0.0]) * self.length
        self.kicks = []

    def place(self, buffer, beat, stem="main", volume=1.0, pan=0.0, send=0.0):
        left_gain = volume * math.cos((pan + 1.0) * math.pi / 4.0)
        right_gain = volume * math.sin((pan + 1.0) * math.pi / 4.0)
        left, right = self.stems[stem]
        length = self.length
        start = int(beat * self.beat * RATE) % length
        for i in range(len(buffer)):
            index = (start + i) % length
            sample = buffer[i]
            left[index] += sample * left_gain
            right[index] += sample * right_gain
            self.send[index] += sample * send * volume

    # 악기 ------------------------------------------------------------
    def pad(self, beat, beats, notes, volume=0.10, cutoff=(500.0, 1100.0), send=0.5):
        count = int(beats * self.beat * RATE)
        for index, number in enumerate(notes):
            freq = midi(number)
            pan = (index / max(1, len(notes) - 1) - 0.5) * 1.2
            mixed = render_osc("saw", freq, count, -0.004, 0.13 * index)
            other = render_osc("saw", freq, count, 0.005, 0.57 + 0.11 * index)
            for i in range(count):
                mixed[i] = (mixed[i] + other[i]) * 0.5
            lowpass(mixed, cutoff[0], cutoff[1])
            envelope(mixed, min(0.6, beats * self.beat * 0.3), min(0.9, beats * self.beat * 0.4))
            self.place(mixed, beat, "pad", volume * PAD_LEVEL, pan, send)

    def bass(self, beat, beats, number, volume=0.34, cutoff=700.0, kind="saw"):
        count = int(beats * self.beat * RATE)
        freq = midi(number)
        body = render_osc("soft", freq, count)
        edge = render_osc(kind, freq, count)
        for i in range(count):
            body[i] = body[i] * 0.75 + edge[i] * 0.35
        lowpass(body, cutoff * 2.0, cutoff * 0.6)
        envelope(body, 0.004, 0.03)
        self.place(body, beat, "main", volume * BASS_LEVEL)

    def pluck(self, beat, number, volume=0.13, pan=0.0, cutoff=2600.0, send=0.35, decay=9.0, kind="square"):
        count = int(0.42 * RATE)
        buffer = render_osc(kind, midi(number), count)
        lowpass(buffer, cutoff, cutoff * 0.35)
        envelope(buffer, 0.002, 0.04, decay)
        self.place(buffer, beat, "main", volume * PLUCK_LEVEL, pan, send)

    def bell(self, beat, number, volume=0.16, pan=0.0, send=0.75, length=2.4):
        """FM 합성 종소리. 별이 반짝이는 느낌과 가챠 모티프에 쓴다."""
        count = int(length * RATE)
        freq = midi(number)
        buffer = array.array("d", [0.0]) * count
        carrier = math.tau * freq / RATE
        modulator = math.tau * freq * 3.5 / RATE
        for i in range(count):
            depth = 2.2 * math.exp(-7.0 * i / RATE)
            buffer[i] = math.sin(carrier * i + depth * math.sin(modulator * i)) * math.exp(-3.2 * i / RATE)
        envelope(buffer, 0.002, 0.05)
        self.place(buffer, beat, "main", volume, pan, send)

    def lead(self, beat, beats, number, volume=0.15, kind="square", cutoff=2800.0, send=0.4, pan=0.0):
        count = int(beats * self.beat * RATE * 0.96)
        buffer = render_osc(kind, midi(number), count, vibrato=0.0045 if beats >= 1.0 else 0.0)
        second = render_osc("saw", midi(number), count, 0.004, 0.3)
        for i in range(count):
            buffer[i] = buffer[i] * 0.7 + second[i] * 0.3
        lowpass(buffer, cutoff * 1.3, cutoff * 0.8)
        envelope(buffer, 0.012, 0.05)
        self.place(buffer, beat, "main", volume * LEAD_LEVEL, pan, send)

    def melody(self, start_beat, phrase, octave_shift=0, **options):
        """phrase는 (음 이름, 박) 목록이다."""
        position = start_beat
        for name, beats in phrase:
            if name is not None:
                self.lead(position, beats, note(name) + octave_shift * 12, **options)
            position += beats
        return position

    def gacha_motif(self, beat, chord, volume=0.14, step=0.5):
        """가챠 모티프: 코드 음을 빠르게 굴려 올라가다가 높은 음에서 멎는다. 모든 곡에 들어간다."""
        notes = chord_notes(chord, 5)
        rising = (notes + [n + 12 for n in notes])[:6]
        for index, number in enumerate(rising):
            self.bell(beat + index * step, number, volume * (0.7 + index * 0.08), pan=-0.5 + index * 0.2, length=1.6)

    def kick(self, beat, volume=0.62):
        count = int(0.2 * RATE)
        buffer = array.array("d", [0.0]) * count
        phase = 0.0
        for i in range(count):
            t = i / RATE
            phase += math.tau * (42.0 + 120.0 * math.exp(-t * 34.0)) / RATE
            buffer[i] = math.sin(phase) * math.exp(-t * 13.0)
        self.place(buffer, beat, "drum", volume * KICK_LEVEL)
        self.kicks.append(beat)

    def snare(self, beat, volume=0.26):
        count = int(0.17 * RATE)
        noise_source = get_noise()
        offset = int(beat * 997) % (RATE - count)
        buffer = array.array("d", [0.0]) * count
        for i in range(count):
            t = i / RATE
            buffer[i] = noise_source[offset + i] * math.exp(-t * 20.0) * 0.8
            buffer[i] += math.sin(math.tau * 190.0 * t) * math.exp(-t * 28.0) * 0.5
        lowpass(buffer, 5200.0)
        self.place(buffer, beat, "drum", volume, 0.0, 0.2)

    def hat(self, beat, volume=0.05, pan=0.2, length=0.03):
        count = int(length * RATE)
        noise_source = get_noise()
        offset = int(beat * 1009) % (RATE - count)
        buffer = array.array("d", [0.0]) * count
        previous = 0.0
        for i in range(count):
            sample = noise_source[offset + i]
            buffer[i] = (sample - previous) * math.exp(-i / RATE * 120.0)
            previous = sample
        self.place(buffer, beat, "drum", volume, pan)

    def riser(self, beat, beats, volume=0.09):
        count = int(beats * self.beat * RATE)
        noise_source = get_noise()
        buffer = array.array("d", (noise_source[i % RATE] for i in range(count)))
        lowpass(buffer, 300.0, 6000.0)
        for i in range(count):
            buffer[i] *= (i / count) ** 2
        envelope(buffer, 0.01, 0.02)
        self.place(buffer, beat, "main", volume, 0.0, 0.6)

    def laser(self, beat, volume=0.05, pan=0.0):
        """멀리서 들리는 함포 소리."""
        count = int(0.2 * RATE)
        buffer = array.array("d", [0.0]) * count
        phase = 0.0
        for i in range(count):
            t = i / RATE
            phase += math.tau * (1700.0 * math.exp(-t * 16.0) + 180.0) / RATE
            buffer[i] = math.sin(phase) * math.exp(-t * 11.0)
        self.place(buffer, beat, "main", volume, pan, 0.8)

    # 마무리 ----------------------------------------------------------
    def duck(self, stem_name, depth=0.6, speed=7.0):
        """킥이 나올 때 배경을 눌러 숨 쉬는 듯한 박동을 만든다."""
        length = self.length
        gain = array.array("d", [1.0]) * length
        beat_samples = self.beat * RATE
        for kick_beat in self.kicks:
            start = int(kick_beat * beat_samples) % length
            for i in range(int(0.3 * RATE)):
                index = (start + i) % length
                value = 1.0 - depth * math.exp(-i / RATE * speed)
                if value < gain[index]:
                    gain[index] = value
        for channel in self.stems[stem_name]:
            for i in range(length):
                channel[i] *= gain[i]

    def space(self, feedback=0.8, delay_beats=0.75, delay_level=0.32, wet=0.3):
        """핑퐁 딜레이와 슈뢰더 리버브. 두 바퀴 돌려 꼬리가 곡 앞으로 이어지게 한다."""
        length = self.length
        delay = max(1, int(delay_beats * self.beat * RATE))
        wet_left = array.array("d", [0.0]) * length
        wet_right = array.array("d", [0.0]) * length
        for channel_index, (out, combs, allpasses) in enumerate((
                (wet_left, (778, 808, 745, 711), (112, 278)),
                (wet_right, (790, 820, 757, 723), (118, 284)))):
            collected = array.array("d", [0.0]) * length
            for size in combs:
                memory = array.array("d", [0.0]) * size
                position = 0
                for round_index in range(2):
                    for i in range(length):
                        value = memory[position]
                        memory[position] = self.send[i] + value * feedback
                        position = (position + 1) % size
                        if round_index == 1:
                            collected[i] += value
            for size in allpasses:
                memory = array.array("d", [0.0]) * size
                position = 0
                for round_index in range(2):
                    for i in range(length):
                        buffered = memory[position]
                        incoming = collected[i]
                        output = buffered - incoming * 0.5
                        memory[position] = incoming + buffered * 0.5
                        position = (position + 1) % size
                        if round_index == 1:
                            collected[i] = output
            offset = delay if channel_index == 0 else delay * 2
            for i in range(length):
                out[i] = collected[i] * 0.16 * wet + self.send[(i - offset) % length] * delay_level
        return wet_left, wet_right

    def finish(self, name, feedback=0.8, delay_beats=0.75, delay_level=0.32, wet=0.3, duck_depth=0.0):
        if duck_depth and self.kicks:
            self.duck("pad", duck_depth)
        wet_left, wet_right = self.space(feedback, delay_beats, delay_level, wet)
        left = array.array("d", [0.0]) * self.length
        right = array.array("d", [0.0]) * self.length
        for stem_left, stem_right in self.stems.values():
            for i in range(self.length):
                left[i] += stem_left[i]
                right[i] += stem_right[i]
        for i in range(self.length):
            left[i] += wet_left[i]
            right[i] += wet_right[i]
        # 평균 음량을 맞춘 뒤 부드럽게 눌러 곡마다 크기가 비슷하게 한다
        power = sum(v * v for v in left) + sum(v * v for v in right)
        rms = math.sqrt(power / (2 * self.length)) or 1.0
        gain = 0.17 / rms
        path = os.path.join(ROOT, "bgm", name + ".wav")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        samples = array.array("h", [0]) * (self.length * 2)
        peak = 0.0
        clipped = 0
        for i in range(self.length):
            for channel, source in ((0, left), (1, right)):
                value = math.tanh(source[i] * gain * 1.1) * 0.9
                peak = max(peak, abs(value))
                clipped += abs(value) > 0.85
                samples[i * 2 + channel] = int(value * 32767)
        with wave.open(path, "wb") as out:
            out.setnchannels(2)
            out.setsampwidth(2)
            out.setframerate(RATE)
            out.writeframes(samples.tobytes())
        seconds = self.length / RATE
        print(f"bgm/{name} {seconds:.1f}s peak {peak:.2f} near_clip {100.0 * clipped / (self.length * 2):.2f}% size {os.path.getsize(path) / 1048576:.1f}MB")


def midi(number):
    return 440.0 * 2.0 ** ((number - 69) / 12.0)


def beat_pattern(track, bars, kick=(), snare=(), hat=(), beats_per_bar=4, intro_bars=0):
    """intro_bars 동안은 킥과 스네어를 빼서 곡이 돌아올 때마다 다시 달아오르게 한다."""
    for bar in range(bars):
        start = bar * beats_per_bar
        if bar >= intro_bars:
            for position in kick:
                track.kick(start + position)
            for position in snare:
                track.snare(start + position)
        for index, position in enumerate(hat):
            track.hat(start + position, 0.05, 0.25 if index % 2 else -0.25)


def arpeggio_bar(track, start, chord, pattern, step, volume=0.11, octave=4, cutoff=2600.0):
    notes = chord_notes(chord, octave)
    for index, degree in enumerate(pattern):
        number = notes[degree % len(notes)] + 12 * (degree // len(notes))
        track.pluck(start + index * step, number, volume, pan=0.5 if index % 2 else -0.5, cutoff=cutoff)


# 곡 ------------------------------------------------------------------

def track_title():
    """타이틀: 무너진 우주를 혼자 떠다니는 느낌. 느린 패드와 별처럼 흩어지는 종소리."""
    track = Track(72, 16)
    chords = ["Dm9", "Bbmaj7", "Gm9", "Asus4", "Dm9", "Fmaj7", "Cadd9", "Asus4"]
    for index, chord in enumerate(chords):
        start = index * 8
        track.pad(start, 8.5, chord_notes(chord, 3), 0.11, (420.0, 900.0), 0.6)
        track.bass(start, 8, chord_notes(chord, 2)[0] - 12, 0.2, 240.0, "soft")
    source = random.Random(7)
    scale = [note(n) for n in ("D5", "F5", "G5", "A5", "C6", "D6", "E6", "F6", "A6")]
    for index in range(46):
        track.bell(source.randrange(0, 64 * 2) / 2.0, source.choice(scale), 0.05, source.uniform(-0.8, 0.8))
    track.gacha_motif(0, "Dm9", 0.1, 1.0)
    track.gacha_motif(32, "Dm9", 0.1, 1.0)
    phrase = [("A5", 4), ("F5", 2), ("G5", 2), ("D5", 6), (None, 2), ("E5", 4), ("A5", 4), ("G5", 4), ("E5", 4)]
    track.melody(16, phrase, volume=0.07, kind="soft", cutoff=1800.0, send=0.8)
    track.melody(48, phrase[:5], volume=0.07, kind="soft", cutoff=1800.0, send=0.8)
    track.finish("title", feedback=0.86, delay_beats=1.5, delay_level=0.28, wet=0.5)


def track_lobby():
    """로비: 작전 지시실. 맥박 같은 베이스 위로 희망이 조금 보인다."""
    track = Track(100, 16)
    chords = ["Cm", "Ab", "Eb", "Bb"] * 4
    beat_pattern(track, 16, kick=(0, 2.5), snare=(), hat=(0.5, 1.5, 2.5, 3.5))
    for index, chord in enumerate(chords):
        start = index * 4
        notes = chord_notes(chord, 2)
        track.pad(start, 4.2, chord_notes(chord, 3), 0.085, (500.0, 1000.0))
        for step in range(8):
            track.bass(start + step / 2.0, 0.42, notes[0] - (12 if step % 4 == 0 else 0), 0.26, 520.0)
        if index >= 4:
            arpeggio_bar(track, start, chord, [0, 1, 2, 3, 2, 1, 2, 3], 0.5, 0.075, 4, 2200.0)
    phrase = [("Eb5", 1), ("G5", 1), ("C6", 2), ("C6", 1), ("Bb5", 1), ("G5", 2),
              ("G5", 1), ("Bb5", 1), ("Eb6", 2), ("D6", 2), ("Bb5", 2)]
    track.melody(32, phrase, volume=0.1, kind="soft", cutoff=2400.0)
    track.melody(48, phrase, volume=0.1, kind="soft", cutoff=3000.0)
    track.gacha_motif(16, "Cm", 0.11)
    track.finish("lobby", duck_depth=0.45)


def battle_groove(track, bars, kick=(0, 1, 2, 3), snare=(1, 3), hat=(0.5, 1.5, 2.5, 3.5)):
    beat_pattern(track, bars, kick, snare, hat, intro_bars=2)


def track_nautolan():
    """Nautolan 선단: 전투의 시작. 곧게 달리는 신스웨이브."""
    track = Track(126, 24)
    verse = ["Am", "F", "C", "G", "Am", "F", "Dm", "E"]
    chords = verse * 3
    battle_groove(track, 24)
    for index, chord in enumerate(chords):
        start = index * 4
        root = chord_notes(chord, 2)[0]
        track.pad(start, 4.2, chord_notes(chord, 3), 0.075, (600.0, 1200.0), 0.4)
        for step in range(8):
            octave_up = 12 if step % 4 == 3 else 0
            track.bass(start + step / 2.0, 0.45, root - 12 + octave_up, 0.3, 620.0)
        arpeggio_bar(track, start, chord, [0, 2, 1, 2, 3, 2, 1, 2] * 2, 0.25, 0.07, 4)
    lead = [("E5", 1.5), ("D5", 0.5), ("C5", 1), ("A4", 1), ("C5", 1.5), ("D5", 0.5), ("A4", 2),
            ("G5", 1.5), ("E5", 0.5), ("C5", 1), ("E5", 1), ("D5", 3), ("B4", 1),
            ("E5", 1), ("A5", 1), ("G5", 0.5), ("E5", 0.5), ("D5", 1), ("C5", 1.5), ("D5", 0.5), ("F5", 2),
            ("A5", 1), ("G5", 0.5), ("F5", 0.5), ("E5", 1), ("D5", 1), ("E5", 2), ("G#5", 1), ("B5", 1)]
    track.melody(32, lead, volume=0.13)
    track.melody(64, lead, 1, volume=0.11, send=0.5)
    track.gacha_motif(30, "Am7", 0.12, 0.25)
    track.riser(28, 4)
    track.riser(60, 4)
    for bar in (7, 15, 23):
        track.laser(bar * 4 + 3.5, 0.05, -0.6)
        track.laser(bar * 4 + 3.75, 0.05, 0.6)
    track.finish("battle_nautolan", duck_depth=0.6)


def track_klaed():
    """Kla'ed 선단: 낯선 문명. 프리지안 음계와 3-3-2 리듬으로 긴장을 만든다."""
    track = Track(138, 24)
    chords = (["Em", "F", "Em", "Dm", "G", "F", "Em", "Em"] * 3)
    beat_pattern(track, 24, kick=(0, 1.5, 3), snare=(1, 3), hat=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5), intro_bars=2)
    for index, chord in enumerate(chords):
        start = index * 4
        root = chord_notes(chord, 2)[0]
        track.pad(start, 4.2, chord_notes(chord, 3), 0.07, (450.0, 900.0), 0.35)
        for position, length in ((0, 1.3), (1.5, 1.3), (3, 0.8)):
            track.bass(start + position, length, root - 12, 0.22, 560.0, "square")
        arpeggio_bar(track, start, chord, [0, 1, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 1, 0, 3], 0.25, 0.08, 4, 2800.0)
    lead = [("B4", 0.75), ("B4", 0.75), ("E5", 0.5), ("G5", 1), ("F5", 1), ("F5", 0.75), ("E5", 0.75), ("C5", 0.5), ("A4", 2),
            ("B4", 0.75), ("B4", 0.75), ("E5", 0.5), ("G5", 0.5), ("A5", 0.5), ("B5", 1), ("A5", 1), ("G5", 0.5), ("F5", 0.5), ("D5", 2),
            ("D5", 0.75), ("G5", 0.75), ("B5", 0.5), ("A5", 1), ("G5", 1), ("F5", 0.75), ("A5", 0.75), ("C6", 0.5), ("B5", 1), ("A5", 1),
            ("G5", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("E5", 3), (None, 1)]
    track.melody(32, lead, volume=0.12, kind="saw", cutoff=2200.0)
    track.melody(64, lead, 1, volume=0.1, kind="saw", cutoff=2600.0, send=0.5)
    track.gacha_motif(62, "Em", 0.11, 0.25)
    track.riser(28, 4)
    track.riser(60, 4)
    for bar in (3, 11, 19):
        track.laser(bar * 4 + 3, 0.05, 0.5)
    track.finish("battle_klaed", delay_beats=0.5, duck_depth=0.55)


def track_nairan():
    """Nairan 선단: 전쟁의 절정. 빠른 16분음 베이스 위로 화성단음계 선율이 날아오른다."""
    track = Track(146, 24)
    chords = (["C#m", "A", "B", "G#", "F#m", "A", "G#", "G#"] * 3)
    battle_groove(track, 24, hat=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5))
    for index, chord in enumerate(chords):
        start = index * 4
        root = chord_notes(chord, 2)[0]
        track.pad(start, 4.2, chord_notes(chord, 4), 0.07, (700.0, 1400.0), 0.35)
        for step in range(16):
            track.bass(start + step / 4.0, 0.23, root - 12 + (12 if step % 8 == 6 else 0), 0.27, 600.0)
        arpeggio_bar(track, start, chord, [0, 1, 2, 3, 4, 3, 2, 1], 0.5, 0.07, 4, 3000.0)
    lead = [("G#5", 1), ("C#6", 1), ("B#5", 0.5), ("C#6", 0.5), ("D#6", 1), ("E6", 1.5), ("D#6", 0.5), ("C#6", 2),
            ("D#6", 1), ("B5", 1), ("F#5", 0.5), ("G#5", 0.5), ("A5", 1), ("B#5", 3), ("G#5", 1),
            ("A5", 1), ("C#6", 1), ("F#6", 1), ("E6", 1), ("E6", 0.5), ("D#6", 0.5), ("C#6", 1), ("A5", 2),
            ("G#5", 0.5), ("A5", 0.5), ("B#5", 1), ("D#6", 1), ("F#6", 1), ("G#6", 3), (None, 1)]
    track.melody(32, lead, volume=0.13, cutoff=3200.0)
    track.melody(64, lead, volume=0.13, cutoff=3400.0, send=0.5)
    track.gacha_motif(30, "C#m7", 0.12, 0.25)
    track.riser(28, 4)
    track.riser(60, 4)
    for bar in (5, 13, 21):
        track.laser(bar * 4 + 2, 0.05, -0.5)
        track.laser(bar * 4 + 2.5, 0.05, 0.5)
    track.finish("battle_nairan", duck_depth=0.6)


def track_boss():
    """기함 접근: 사이렌 같은 선율과 묵직한 금관 화음."""
    track = Track(154, 16)
    chords = (["Dm", "Eb", "Dm", "C#dim", "Bb", "A", "Bb", "A"] * 2)
    beat_pattern(track, 16, kick=(0, 0.75, 1.5, 2, 2.75, 3.5), snare=(1, 3), hat=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5))
    for index, chord in enumerate(chords):
        start = index * 4
        root = chord_notes(chord, 2)[0]
        for position in (0, 1.5, 3):
            for spread, number in enumerate(chord_notes(chord, 3)):
                track.lead(start + position, 0.5, number, 0.08, "saw", 2600.0, 0.25, pan=-0.6 + spread * 0.6)
        for step in range(8):
            track.bass(start + step / 2.0, 0.45, root - 12, 0.2, 500.0, "square")
    lead = [("D5", 1), ("F5", 0.5), ("A5", 0.5), ("Bb5", 1), ("A5", 1), ("G5", 1), ("Eb5", 1), ("Bb4", 1), ("G5", 1),
            ("D5", 0.5), ("D5", 0.5), ("F5", 0.5), ("A5", 0.5), ("D6", 2), ("C#6", 1), ("A5", 1), ("E5", 1), ("G5", 1)]
    track.melody(0, lead, volume=0.11, kind="saw", cutoff=2400.0)
    track.melody(32, lead, 1, volume=0.1, kind="saw", cutoff=2800.0)
    track.riser(28, 4)
    track.riser(60, 4)
    track.finish("boss", delay_beats=0.5, delay_level=0.22, duck_depth=0.4)


def track_final_boss():
    """최종 기함: 가챠 모티프가 비극적인 주제가 되어 돌아온다."""
    track = Track(164, 24)
    chords = (["Fm", "Db", "Bbm", "C", "Fm", "Ab", "Eb", "C"] * 3)
    beat_pattern(track, 24, kick=(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5), snare=(1, 3), hat=(0.5, 1.5, 2.5, 3.5))
    for index, chord in enumerate(chords):
        start = index * 4
        root = chord_notes(chord, 2)[0]
        track.pad(start, 4.2, chord_notes(chord, 4) + [chord_notes(chord, 3)[0]], 0.08, (900.0, 1700.0), 0.45)
        for step in range(8):
            track.bass(start + step / 2.0, 0.42, root - 12, 0.28, 560.0)
        arpeggio_bar(track, start, chord, [0, 1, 2, 3, 2, 3, 2, 1], 0.5, 0.06, 5, 3200.0)
    lead = [("F5", 0.5), ("Ab5", 0.5), ("C6", 0.5), ("Eb6", 0.5), ("F6", 2), ("F6", 0.75), ("Eb6", 0.75), ("Db6", 0.5), ("Ab5", 2),
            ("Bb5", 0.75), ("Db6", 0.75), ("F6", 0.5), ("Eb6", 1), ("Db6", 1), ("C6", 1), ("E6", 1), ("G6", 2),
            ("Ab6", 1.5), ("G6", 0.5), ("F6", 2), ("Eb6", 1.5), ("F6", 0.5), ("C6", 2),
            ("Bb5", 0.75), ("Eb6", 0.75), ("G6", 0.5), ("F6", 1), ("Eb6", 1), ("E6", 4)]
    track.melody(0, lead, volume=0.12, cutoff=3200.0)
    track.melody(32, lead, volume=0.12, cutoff=3600.0, send=0.5)
    track.melody(64, lead, -1, volume=0.1, kind="saw", cutoff=2000.0)
    track.gacha_motif(62, "Fm", 0.13, 0.25)
    track.riser(60, 4)
    track.finish("final_boss", duck_depth=0.5)


TRACKS = {"title": track_title, "lobby": track_lobby, "battle_nautolan": track_nautolan, "battle_klaed": track_klaed,
          "battle_nairan": track_nairan, "boss": track_boss, "final_boss": track_final_boss}


def run_track(name):
    TRACKS[name]()


def main():
    names = sys.argv[1:] or list(TRACKS)
    if not sys.argv[1:]:
        build_sfx()
    with multiprocessing.Pool(min(len(names), 6)) as pool:
        pool.map(run_track, names)


if __name__ == "__main__":
    main()
