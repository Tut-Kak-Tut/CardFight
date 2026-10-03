extends SceneTree
# Synthesizes all game audio into res://assets/audio/*.wav (22050 Hz, 16-bit, mono).
# Run: godot --headless --path . -s tools/gen_audio.gd

const SR := 22050
const OUT := "res://assets/audio/"
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 27027
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sfx := {
		"hit": _hit(), "block": _block(), "card_play": _card_play(), "ui_click": _ui_click(),
		"campfire": _campfire(), "enemy_attack": _enemy_attack(), "heal": _heal(), "gold": _gold(),
		"card_draw": _card_draw(), "upgrade": _upgrade(), "victory": _victory(), "defeat": _defeat(),
		"shard": _shard(), "poison": _poison(), "buff": _buff(),
	}
	for k in sfx:
		_save(k, sfx[k], 0.707)
	_save("ambient_menu", _music_menu(), 0.25)
	_save("ambient_combat", _music_combat(), 0.25)
	_save("boss", _music_boss(), 0.25)
	quit()


# ---------- primitives ----------
func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * SR))
	return b


func _osc(kind: String, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match kind:
		"sine": return sin(p * TAU)
		"square": return 1.0 if p < 0.5 else -1.0
		"saw": return p * 2.0 - 1.0
		"tri": return abs(p * 4.0 - 2.0) - 1.0
	return rng.randf_range(-1.0, 1.0)


# ADSR envelope; t and dur in seconds (release occurs inside dur).
func _adsr(t: float, dur: float, a: float, d: float, s: float, r: float) -> float:
	if t < 0.0 or t >= dur:
		return 0.0
	var rs := maxf(dur - r, 0.0)
	var lvl: float
	if t < a:
		lvl = t / maxf(a, 1e-5)
	elif t < a + d:
		lvl = 1.0 - (1.0 - s) * (t - a) / maxf(d, 1e-5)
	else:
		lvl = s
	if t > rs:
		lvl *= (dur - t) / maxf(r, 1e-5)
	return lvl


# Adds a tone into buf at start (sec). Pitch slides f0 -> f1 across duration.
func _tone(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, kind: String,
		vol: float, a := 0.005, d := 0.05, s := 0.6, r := 0.05, harm := 0.0) -> void:
	var i0 := int(start * SR)
	var n := int(dur * SR)
	var ph := 0.0
	for i in n:
		if i0 + i >= buf.size():
			break
		var t := float(i) / SR
		var f := lerpf(f0, f1, t / dur)
		ph += f / SR
		var v := _osc(kind, ph)
		if harm > 0.0:
			v += harm * _osc(kind, ph * 2.0)
		buf[i0 + i] += v * _adsr(t, dur, a, d, s, r) * vol


func _noise(buf: PackedFloat32Array, start: float, dur: float, vol: float, a := 0.002, d := 0.05,
		s := 0.3, r := 0.05, lp := 1.0) -> void:
	var i0 := int(start * SR)
	var n := int(dur * SR)
	var y := 0.0
	for i in n:
		if i0 + i >= buf.size():
			break
		y += lp * (rng.randf_range(-1.0, 1.0) - y)
		buf[i0 + i] += y * _adsr(float(i) / SR, dur, a, d, s, r) * vol


func _lowpass(buf: PackedFloat32Array, k: float) -> PackedFloat32Array:
	var y := 0.0
	var o := buf.duplicate()
	for i in o.size():
		y += k * (o[i] - y)
		o[i] = y
	return o


# Sweeping low-pass noise for whooshes: cutoff coefficient moves k0 -> k1.
func _whoosh(buf: PackedFloat32Array, start: float, dur: float, k0: float, k1: float, vol: float) -> void:
	var i0 := int(start * SR)
	var n := int(dur * SR)
	var y := 0.0
	for i in n:
		if i0 + i >= buf.size():
			break
		var t := float(i) / n
		y += lerpf(k0, k1, t) * (rng.randf_range(-1.0, 1.0) - y)
		buf[i0 + i] += y * sin(t * PI) * vol


func _m(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


# ---------- SFX ----------
func _hit() -> PackedFloat32Array:
	var b := _buf(0.3)
	_noise(b, 0, 0.18, 0.7, 0.001, 0.04, 0.2, 0.12, 0.5)
	_tone(b, 0, 0.3, 140, 45, "sine", 1.0, 0.001, 0.08, 0.4, 0.15)
	return b


func _enemy_attack() -> PackedFloat32Array:
	var b := _buf(0.45)
	_noise(b, 0, 0.3, 0.8, 0.001, 0.08, 0.3, 0.2, 0.25)
	_tone(b, 0, 0.45, 90, 30, "saw", 0.6, 0.002, 0.1, 0.4, 0.2)
	_tone(b, 0, 0.4, 70, 28, "sine", 1.0, 0.001, 0.1, 0.5, 0.2)
	return _lowpass(b, 0.35)


func _block() -> PackedFloat32Array:
	var b := _buf(0.6)
	for f in [820.0, 1230.0, 1960.0, 2770.0]:
		_tone(b, 0, 0.6, f, f, "sine", 0.35, 0.001, 0.25, 0.05, 0.3)
	_noise(b, 0, 0.04, 0.5, 0.0005, 0.02, 0.0, 0.02)
	return b


func _card_play() -> PackedFloat32Array:
	var b := _buf(0.25)
	_whoosh(b, 0, 0.25, 0.05, 0.6, 1.0)
	return b


func _card_draw() -> PackedFloat32Array:
	var b := _buf(0.12)
	_whoosh(b, 0, 0.12, 0.1, 0.4, 0.5)
	return b


func _ui_click() -> PackedFloat32Array:
	var b := _buf(0.06)
	_tone(b, 0, 0.06, 1400, 900, "sine", 0.5, 0.0005, 0.02, 0.0, 0.03)
	_noise(b, 0, 0.01, 0.15, 0.0005, 0.005, 0.0, 0.005)
	return b


func _campfire() -> PackedFloat32Array:
	var b := _buf(0.8)
	_noise(b, 0, 0.8, 0.12, 0.1, 0.2, 0.6, 0.2, 0.08)
	for i in 14:
		var t := rng.randf_range(0.0, 0.7)
		_noise(b, t, rng.randf_range(0.005, 0.02), rng.randf_range(0.3, 0.9), 0.0005, 0.005, 0.2, 0.008, 0.9)
	return b


func _arp(notes: Array, step: float, len: float, kind: String, vol: float, tail: float) -> PackedFloat32Array:
	var b := _buf(step * notes.size() + tail)
	for i in notes.size():
		_tone(b, i * step, len, _m(notes[i]), _m(notes[i]), kind, vol, 0.005, 0.08, 0.5, len * 0.5, 0.3)
	return b


func _heal() -> PackedFloat32Array:
	return _arp([72, 76, 79, 84], 0.09, 0.3, "sine", 0.5, 0.2)


func _gold() -> PackedFloat32Array:
	var b := _buf(0.4)
	_tone(b, 0, 0.3, _m(88), _m(88), "sine", 0.5, 0.001, 0.15, 0.1, 0.15)
	_tone(b, 0.08, 0.32, _m(95), _m(95), "sine", 0.5, 0.001, 0.15, 0.1, 0.2)
	return b


func _upgrade() -> PackedFloat32Array:
	var b := _arp([76, 79, 83, 88, 91], 0.07, 0.35, "sine", 0.4, 0.3)
	_tone(b, 0.2, 0.5, 3000, 5000, "sine", 0.12, 0.05, 0.1, 0.5, 0.3)
	return b


func _victory() -> PackedFloat32Array:
	var b := _buf(1.3)
	var ns := [60, 64, 67, 72, 76, 79]
	for i in ns.size():
		_tone(b, i * 0.12, 0.5 if i < 5 else 0.6, _m(ns[i]), _m(ns[i]), "tri", 0.4, 0.005, 0.1, 0.6, 0.3, 0.2)
	for n in [60, 64, 67, 72]:
		_tone(b, 0.72, 0.58, _m(n), _m(n), "tri", 0.22, 0.01, 0.1, 0.7, 0.4)
	return b


func _defeat() -> PackedFloat32Array:
	var b := _buf(1.6)
	var ns := [69, 65, 62, 57]
	for i in ns.size():
		var d := 0.7 if i < 3 else 0.4
		_tone(b, i * 0.3, d, _m(ns[i]), _m(ns[i] - 1), "saw", 0.3, 0.01, 0.15, 0.6, 0.3)
		_tone(b, i * 0.3, d, _m(ns[i] - 12), _m(ns[i] - 13), "sine", 0.4, 0.01, 0.15, 0.6, 0.3)
	return _lowpass(b, 0.3)


func _shard() -> PackedFloat32Array:
	var b := _buf(0.7)
	for f in [1568.0, 2349.0, 3136.0, 4186.0]:
		_tone(b, 0, 0.7, f, f * 1.003, "sine", 0.3, 0.001, 0.3, 0.1, 0.3)
	_tone(b, 0.05, 0.6, 2093.0, 2093.0, "sine", 0.25, 0.001, 0.3, 0.1, 0.3)
	return b


func _poison() -> PackedFloat32Array:
	var b := _buf(0.6)
	for i in 5:
		var t := i * 0.1 + rng.randf_range(0.0, 0.04)
		var f := rng.randf_range(200.0, 350.0)
		_tone(b, t, 0.12, f, f * 2.2, "sine", 0.6, 0.005, 0.04, 0.5, 0.05)
	return b


func _buff() -> PackedFloat32Array:
	var b := _buf(0.5)
	_whoosh(b, 0, 0.5, 0.03, 0.4, 0.5)
	_tone(b, 0, 0.5, 300, 900, "sine", 0.4, 0.02, 0.1, 0.6, 0.15)
	_tone(b, 0, 0.5, 450, 1350, "tri", 0.15, 0.02, 0.1, 0.6, 0.15)
	return b


# ---------- music (lengths are whole bars; every note ends before the loop end -> seamless) ----------
func _music_menu() -> PackedFloat32Array:
	var bar := 4.0
	var b := _buf(bar * 5)  # 20 s
	var chords := [[57, 60, 64], [53, 57, 60], [55, 60, 64], [52, 59, 64], [57, 60, 64]]
	var pad := _buf(bar * 5)
	for i in chords.size():
		for n in chords[i]:
			var f := _m(n)
			_tone(pad, i * bar + 0.05, bar - 0.1, f, f, "saw", 0.12, 1.2, 0.5, 0.7, 1.2)
			_tone(pad, i * bar + 0.05, bar - 0.1, f * 1.004, f * 1.004, "sine", 0.18, 1.2, 0.5, 0.7, 1.2)
		var bn: int = chords[i][0] - 24
		_tone(pad, i * bar + 0.05, bar - 0.1, _m(bn), _m(bn), "sine", 0.4, 1.0, 0.5, 0.8, 1.2)
	pad = _lowpass(pad, 0.12)
	for i in b.size():
		b[i] = pad[i]
	var melody := [[1.0, 76], [5.5, 72], [9.0, 71], [13.0, 69], [17.0, 67]]
	for m in melody:
		_tone(b, m[0], 2.2, _m(m[1]), _m(m[1]), "sine", 0.22, 0.05, 0.4, 0.3, 1.5)
		_tone(b, m[0] + 0.375, 2.0, _m(m[1]), _m(m[1]), "sine", 0.08, 0.05, 0.4, 0.3, 1.5)
	return b


func _music_combat() -> PackedFloat32Array:
	var beat := 0.6  # 100 BPM
	var b := _buf(beat * 32)  # 8 bars = 19.2 s
	var roots := [45, 45, 41, 43, 45, 45, 41, 40]
	for bi in 8:
		for k in 8:
			var t := (bi * 8 + k) * beat * 0.5
			var r: int = roots[bi] + (12 if k % 4 == 3 else 0)
			_tone(b, t, beat * 0.45, _m(r), _m(r), "saw", 0.28, 0.005, 0.1, 0.5, 0.1)
		for q in 4:
			var tq := (bi * 4 + q) * beat
			if q % 2 == 0:
				_tone(b, tq, 0.2, 110, 40, "sine", 0.8, 0.001, 0.06, 0.2, 0.1)
			else:
				_noise(b, tq, 0.15, 0.3, 0.001, 0.04, 0.2, 0.08, 0.5)
			_noise(b, tq + beat * 0.5, 0.05, 0.1, 0.001, 0.02, 0.1, 0.02, 0.9)
		if bi % 2 == 1:
			var n: int = roots[bi] + 24
			_tone(b, bi * 4 * beat + beat * 2.0, beat * 1.8, _m(n), _m(n + 3), "tri", 0.15, 0.02, 0.2, 0.5, 0.4)
	return _lowpass(b, 0.35)


func _music_boss() -> PackedFloat32Array:
	var beat := 0.5  # 120 BPM
	var b := _buf(beat * 40)  # 10 bars = 20 s
	var roots := [38, 38, 41, 38, 36, 36, 37, 38, 41, 37]
	for bi in 10:
		for k in 16:
			var t := (bi * 16 + k) * beat * 0.25
			var r: int = roots[bi] + (12 if k % 8 == 6 else (7 if k % 4 == 3 else 0))
			_tone(b, t, beat * 0.22, _m(r), _m(r), "saw", 0.22, 0.003, 0.05, 0.5, 0.05)
		for q in 4:
			var tq := (bi * 4 + q) * beat
			_tone(b, tq, 0.22, 120, 35, "sine", 0.9, 0.001, 0.07, 0.2, 0.1)
			if q % 2 == 1:
				_noise(b, tq, 0.18, 0.4, 0.001, 0.05, 0.2, 0.1, 0.6)
			_noise(b, tq + beat * 0.5, 0.04, 0.12, 0.001, 0.02, 0.1, 0.02, 0.9)
		var n: int = roots[bi] + 12
		for c in [0, 3, 6]:
			_tone(b, bi * 4 * beat, beat * 3.9, _m(n + c), _m(n + c), "square", 0.05, 0.4, 0.5, 0.6, 0.8)
		if bi % 2 == 1:
			_tone(b, bi * 4 * beat + beat * 2.0, beat * 1.9, _m(roots[bi] + 31), _m(roots[bi] + 30), "tri", 0.15, 0.02, 0.2, 0.5, 0.4)
	return _lowpass(b, 0.3)


# ---------- output ----------
# Normalizes peak to `peak` linear (0.707 = -3 dB; music 0.25 = -12 dB) and writes 16-bit WAV.
func _save(id: String, buf: PackedFloat32Array, peak: float) -> void:
	var mx := 0.0001
	for v in buf:
		mx = maxf(mx, absf(v))
	var g := peak / mx
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, clampi(int(round(buf[i] * g * 32767.0)), -32767, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	var err := w.save_to_wav(OUT + id + ".wav")
	print("%s: %.2fs err=%d" % [id, buf.size() / float(SR), err])
