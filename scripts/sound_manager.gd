extends Node

# Procedural audio generator & Mobile Haptic Vibration Manager (Optimized)

var haptic_enabled: bool = true

# 1. Fixed Audio Player Pool (8 Channels to eliminate runtime node instancing & GC lag)
const POOL_SIZE: int = 8
var player_pool: Array[AudioStreamPlayer] = []
var next_player_idx: int = 0

# 2. Pre-baked Audio Streams (Generated ONCE at startup to eliminate runtime CPU byte loops)
var cached_streams: Dictionary = {}

# 3. Audio & Haptic Throttling Cooldowns (Prevents audio clipping noise & freezes during mass mob deaths)
var last_sound_times: Dictionary = {}
var last_haptic_time: float = 0.0
const HIT_COOLDOWN: float = 0.045       # Max ~22 hits per second
const KILL_COOLDOWN: float = 0.040      # Max 25 kills per second
const COIN_COOLDOWN: float = 0.035      # Max ~28 coin pickups per second
const HAPTIC_COOLDOWN: float = 0.065    # Max ~15 vibrations per second

# 4. Combo Pitch Modulation for Rapid Kills
var kill_combo_count: int = 0
var last_kill_time: float = 0.0

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
	# Pre-instantiate fixed audio players
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		player_pool.append(p)
		
	# Pre-bake procedural audio wave streams
	_prebake_audio_streams()

func _prebake_audio_streams():
	# Generate procedural WAV streams once in memory
	cached_streams["beam"] = _generate_synth_stream(600.0, 1200.0, 0.09, 0.15, "square")
	cached_streams["hit"] = _generate_synth_stream(220.0, 75.0, 0.06, 0.18, "noise")
	cached_streams["kill_bull"] = _generate_synth_stream(880.0, 1760.0, 0.08, 0.22, "sine")
	cached_streams["kill_bear"] = _generate_synth_stream(180.0, 60.0, 0.08, 0.20, "sawtooth")
	cached_streams["coin"] = _generate_synth_stream(1046.5, 2093.0, 0.05, 0.12, "sine")
	cached_streams["boss_alert"] = _generate_synth_stream(140.0, 280.0, 0.35, 0.30, "sawtooth")
	cached_streams["shockwave"] = _generate_synth_stream(280.0, 45.0, 0.25, 0.25, "sawtooth")
	
	# Arpeggio notes for Level Up
	var note_freqs = [523.25, 659.25, 783.99, 1046.5]
	for i in range(note_freqs.size()):
		var f = note_freqs[i]
		cached_streams["levelup_%d" % i] = _generate_synth_stream(f, f * 1.04, 0.08, 0.18, "square")

# --- Haptic Feedback Methods with Throttling ---

func trigger_haptic(ms: int = 25):
	if not haptic_enabled:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_haptic_time < HAPTIC_COOLDOWN:
		return
	last_haptic_time = now
	
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(ms)

func haptic_tap():
	trigger_haptic(20)

func haptic_impact():
	last_haptic_time = 0.0 # Force impact priority
	trigger_haptic(55)

func haptic_heavy():
	last_haptic_time = 0.0
	trigger_haptic(120)

func haptic_pulse():
	last_haptic_time = 0.0
	trigger_haptic(30)
	get_tree().create_timer(0.08).timeout.connect(func():
		trigger_haptic(45)
	)

# --- Optimized Audio SFX Dispatchers ---

func play_shoot_beam():
	_play_stream_throttled("beam", 0.08, 1.0)

func play_hit():
	# Throttled hit sound to eliminate mass-mob freeze and noise blast
	if _play_stream_throttled("hit", HIT_COOLDOWN, randf_range(0.95, 1.08)):
		haptic_tap()

func play_enemy_death(is_bull: bool = true):
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_kill_time < 0.35:
		kill_combo_count = min(kill_combo_count + 1, 10)
	else:
		kill_combo_count = 0
	last_kill_time = now
	
	# Pitch shifts up with rapid kills ("ding! ding! ding!"), turning noise into satisfying combo notes!
	var combo_pitch = clamp(1.0 + float(kill_combo_count) * 0.05, 1.0, 1.5)
	var sound_key = "kill_bull" if is_bull else "kill_bear"
	
	if _play_stream_throttled(sound_key, KILL_COOLDOWN, combo_pitch):
		haptic_tap()

func play_exp_coin():
	_play_stream_throttled("coin", COIN_COOLDOWN, randf_range(0.96, 1.08))

func play_level_up():
	haptic_pulse()
	for i in range(4):
		var key = "levelup_%d" % i
		get_tree().create_timer(i * 0.06).timeout.connect(func():
			_play_cached_stream(key, 1.0)
		)

func play_boss_alert():
	haptic_pulse()
	_play_cached_stream("boss_alert", 1.0)

func play_shockwave():
	trigger_haptic(70)
	_play_cached_stream("shockwave", 1.0)

# --- Core Player Pooling & Throttling Logic ---

func _play_stream_throttled(stream_key: String, cooldown: float, pitch: float = 1.0) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	var last_time = last_sound_times.get(stream_key, 0.0)
	if now - last_time < cooldown:
		return false # Throttled
		
	last_sound_times[stream_key] = now
	_play_cached_stream(stream_key, pitch)
	return true

func _play_cached_stream(stream_key: String, pitch: float = 1.0):
	if not cached_streams.has(stream_key):
		return
		
	# Select player from pool round-robin
	var p = player_pool[next_player_idx]
	next_player_idx = (next_player_idx + 1) % POOL_SIZE
	
	p.stream = cached_streams[stream_key]
	p.pitch_scale = pitch
	p.play()

# --- Procedural Waveform Synthesis (Run ONLY ONCE during _ready) ---

func _generate_synth_stream(start_freq: float, end_freq: float, duration: float, volume: float = 0.2, wave_type: String = "sine") -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	
	var data = PackedByteArray()
	data.resize(num_samples)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var current_freq = lerp(start_freq, end_freq, t)
		var phase_increment = current_freq / sample_rate
		phase = fmod(phase + phase_increment, 1.0)
		
		# Envelope (fade in / fade out)
		var env = 1.0 - t
		if t < 0.08:
			env = t / 0.08
			
		var val = 0.0
		if wave_type == "sine":
			val = sin(phase * TAU)
		elif wave_type == "square":
			val = 1.0 if phase < 0.5 else -1.0
		elif wave_type == "sawtooth":
			val = phase * 2.0 - 1.0
		elif wave_type == "noise":
			val = randf_range(-1.0, 1.0)
			
		var byte_val = int(clamp((val * env * volume * 0.5 + 0.5) * 255.0, 0, 255))
		data[i] = byte_val
		
	stream.data = data
	return stream

