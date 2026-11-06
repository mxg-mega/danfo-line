class_name AudioManager
extends Node

## Central Audio Manager for Danfo Line.
## Plays sound effects with procedural synth fallbacks, allowing teammate audio files to be dropped in.

@export_group("Custom Audio Overrides (Drop teammate files here)")
@export var sfx_pickup: AudioStream
@export var sfx_vip_pickup: AudioStream
@export var sfx_crash: AudioStream
@export var sfx_horn: AudioStream
@export var sfx_pothole: AudioStream
@export var sfx_puddle: AudioStream

var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

# Cached procedural streams
var _proc_pickup: AudioStreamWAV
var _proc_vip_pickup: AudioStreamWAV
var _proc_crash: AudioStreamWAV
var _proc_horn: AudioStreamWAV
var _proc_pothole: AudioStreamWAV
var _proc_puddle: AudioStreamWAV

func _ready() -> void:
	# Create pool of audio players for polyphony
	for i in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		
	_generate_procedural_sounds()

func _generate_procedural_sounds() -> void:
	_proc_pickup = _synth_sine_arpeggio([880.0, 1320.0], 0.12)
	_proc_vip_pickup = _synth_sine_arpeggio([587.0, 880.0, 1174.0, 1480.0], 0.28)
	_proc_horn = _synth_dual_tone(440.0, 554.0, 0.25)
	_proc_crash = _synth_noise_burst(0.35, true)
	_proc_pothole = _synth_low_thud(120.0, 0.2)
	_proc_puddle = _synth_noise_burst(0.18, false)

func play_pickup() -> void:
	_play_stream(sfx_pickup if sfx_pickup else _proc_pickup, -2.0)

func play_vip_pickup() -> void:
	_play_stream(sfx_vip_pickup if sfx_vip_pickup else _proc_vip_pickup, 0.0)

func play_crash() -> void:
	_play_stream(sfx_crash if sfx_crash else _proc_crash, 2.0)

func play_horn() -> void:
	_play_stream(sfx_horn if sfx_horn else _proc_horn, 1.0)

func play_pothole() -> void:
	_play_stream(sfx_pothole if sfx_pothole else _proc_pothole, -1.0)

func play_puddle() -> void:
	_play_stream(sfx_puddle if sfx_puddle else _proc_puddle, -3.0)

func _play_stream(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# If all busy, steal first
	_players[0].stream = stream
	_players[0].volume_db = volume_db
	_players[0].play()

# Procedural Sound Generators (8-bit PCM at 22050 Hz)
func _synth_sine_arpeggio(frequencies: Array[float], total_duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * total_duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples)
	
	var note_duration: float = total_duration / float(frequencies.size())
	var note_samples: int = int(sample_rate * note_duration)
	
	for i in range(total_samples):
		var note_idx: int = mini(int(i / note_samples), frequencies.size() - 1)
		var freq: float = frequencies[note_idx]
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 - (float(i) / float(total_samples))
		var wave: float = sin(t * freq * TAU) * envelope
		var byte_val: int = clampi(int((wave * 0.75 + 1.0) * 127.5), 0, 255)
		bytes[i] = byte_val
		
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _synth_dual_tone(freq1: float, freq2: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0 if t < duration * 0.8 else (1.0 - (t - duration * 0.8) / (duration * 0.2))
		var wave: float = (sin(t * freq1 * TAU) * 0.5 + sin(t * freq2 * TAU) * 0.5) * env
		var byte_val: int = clampi(int((wave * 0.8 + 1.0) * 127.5), 0, 255)
		bytes[i] = byte_val
		
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _synth_noise_burst(duration: float, heavy_low_end: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples)
	
	var last_noise: float = 0.0
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		var env: float = (1.0 - progress) * (1.0 - progress)
		var white_noise: float = randf_range(-1.0, 1.0)
		var rumble: float = sin(progress * duration * 80.0 * TAU) if heavy_low_end else 0.0
		last_noise = lerpf(last_noise, white_noise, 0.4)
		var wave: float = (last_noise * 0.7 + rumble * 0.3) * env
		var byte_val: int = clampi(int((wave * 0.85 + 1.0) * 127.5), 0, 255)
		bytes[i] = byte_val
		
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _synth_low_thud(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / duration
		var env: float = (1.0 - progress) * (1.0 - progress)
		var wave: float = sin(t * freq * (1.0 - progress * 0.5) * TAU) * env
		var byte_val: int = clampi(int((wave * 0.85 + 1.0) * 127.5), 0, 255)
		bytes[i] = byte_val
		
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav
