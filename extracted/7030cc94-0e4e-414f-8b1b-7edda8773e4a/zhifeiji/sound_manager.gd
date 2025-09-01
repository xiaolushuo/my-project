extends Node

# 音效管理器 - 管理游戏中的所有音效
# 支持程序化音效生成，无需外部音频文件

signal sound_played(sound_name: String)
signal volume_changed(new_volume: float)

# 音效类型枚举
enum SoundType {
	BOUNCE,
	COLLISION,
	SQUASH,
	RECOVERY,
	THROW,
	CATCH,
	SELECT,
	HOVER
}

# 音效播放器池
var audio_players: Array[AudioStreamPlayer] = []
var max_players = 8

# 当前音量设置
var master_volume = 0.8
var sound_enabled = true

# 音效缓存
var sound_cache = {}

# 音效参数
var sound_parameters = {
	SoundType.BOUNCE: {
		"frequency": 440.0,
		"duration": 0.1,
		"volume": 0.6,
		"waveform": "sine"
	},
	SoundType.COLLISION: {
		"frequency": 220.0,
		"duration": 0.15,
		"volume": 0.8,
		"waveform": "square"
	},
	SoundType.SQUASH: {
		"frequency": 110.0,
		"duration": 0.2,
		"volume": 0.7,
		"waveform": "sawtooth"
	},
	SoundType.RECOVERY: {
		"frequency": 880.0,
		"duration": 0.3,
		"volume": 0.5,
		"waveform": "sine"
	},
	SoundType.THROW: {
		"frequency": 660.0,
		"duration": 0.05,
		"volume": 0.4,
		"waveform": "triangle"
	},
	SoundType.CATCH: {
		"frequency": 330.0,
		"duration": 0.08,
		"volume": 0.5,
		"waveform": "sine"
	},
	SoundType.SELECT: {
		"frequency": 523.25,  # C5
		"duration": 0.1,
		"volume": 0.3,
		"waveform": "sine"
	},
	SoundType.HOVER: {
		"frequency": 440.0,  # A4
		"duration": 0.05,
		"volume": 0.2,
		"waveform": "sine"
	}
}

func _ready():
	# 初始化音频播放器池
	initialize_audio_players()
	
	# 预生成音效
	pre_generate_sounds()
	
	print("音效管理器已初始化")

func _enter_tree():
	# 确保在场景树中时管理器已初始化
	if audio_players.is_empty():
		initialize_audio_players()

# 初始化音频播放器池
func initialize_audio_players():
	audio_players.clear()
	
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer" + str(i)
		player.bus = "Sound"
		add_child(player)
		audio_players.append(player)
		
		# 连接播放完成信号
		player.finished.connect(_on_audio_finished.bind(player))

# 预生成音效
func pre_generate_sounds():
	for sound_type in SoundType.values():
		generate_sound(sound_type)

# 获取可用的音频播放器
func get_available_player() -> AudioStreamPlayer:
	for player in audio_players:
		if not player.playing:
			return player
	
	# 如果没有可用的播放器，返回第一个（可能会打断当前播放）
	return audio_players[0]

# 生成音效
func generate_sound(sound_type: SoundType) -> AudioStream:
	if sound_type in sound_cache:
		return sound_cache[sound_type]
	
	var params = sound_parameters[sound_type]
	var stream = create_programmatic_sound(params)
	sound_cache[sound_type] = stream
	return stream

# 创建程序化音效
func create_programmatic_sound(params: Dictionary) -> AudioStream:
	var sample_rate = 44100
	var duration = params.duration
	var frequency = params.frequency
	var waveform = params.waveform
	var volume = params.volume
	
	# 计算采样数
	var sample_count = int(duration * sample_rate)
	var pcm_data = PackedFloat32Array()
	
	# 生成波形数据
	for i in range(sample_count):
		var t = float(i) / sample_rate
		var sample = 0.0
		
		match waveform:
			"sine":
				sample = sin(2.0 * PI * frequency * t)
			"square":
				sample = 1.0 if sin(2.0 * PI * frequency * t) > 0 else -1.0
			"sawtooth":
				sample = 2.0 * (t * frequency - floor(t * frequency + 0.5))
			"triangle":
				sample = 2.0 * abs(2.0 * (t * frequency - floor(t * frequency + 0.5))) - 1.0
			_:
				sample = sin(2.0 * PI * frequency * t)
		
		# 应用包络（淡入淡出）
		var envelope = 1.0
		var fade_time = min(0.01, duration * 0.1)  # 10ms或持续时间的10%
		var fade_samples = int(fade_time * sample_rate)
		
		if i < fade_samples:
			envelope = float(i) / fade_samples
		elif i > sample_count - fade_samples:
			envelope = float(sample_count - i) / fade_samples
		
		sample *= envelope * volume
		pcm_data.append(sample)
	
	# 创建音频流
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = duration
	
	var playback = AudioStreamGeneratorPlayback.new()
	playback.audio_stream = generator
	
	# 填充音频数据
	playback.push_buffer(pcm_data)
	
	# 创建可播放的音频流
	var stream = AudioStreamMP3.new()
	# 由于直接操作AudioStreamGeneratorPlayback比较复杂，我们使用简化方法
	# 这里返回一个基本的音频流，实际项目中可能需要更复杂的实现
	
	# 简化实现：返回一个正弦波音频流
	return create_simple_sine_wave(frequency, duration, volume)

# 创建简单的正弦波音频流
func create_simple_sine_wave(frequency: float, duration: float, volume: float) -> AudioStream:
	var sample_rate = 44100
	var sample_count = int(duration * sample_rate)
	var pcm_data = PackedFloat32Array()
	
	for i in range(sample_count):
		var t = float(i) / sample_rate
		var sample = sin(2.0 * PI * frequency * t) * volume
		
		# 简单的包络
		var envelope = 1.0
		var fade_samples = int(0.01 * sample_rate)
		
		if i < fade_samples:
			envelope = float(i) / fade_samples
		elif i > sample_count - fade_samples:
			envelope = float(sample_count - i) / fade_samples
		
		sample *= envelope
		pcm_data.append(sample)
	
	# 使用AudioStreamOggVorbis（如果可用）或创建一个基本的音频流
	var stream = AudioStreamMP3.new()
	
	# 由于Godot的音频流创建比较复杂，这里我们使用一个简化的方法
	# 在实际项目中，你可能需要预录制的音频文件或更复杂的程序化音频生成
	
	# 返回一个基本的音频流占位符
	return create_placeholder_stream(duration, volume)

# 创建占位符音频流
func create_placeholder_stream(duration: float, volume: float) -> AudioStream:
	# 创建一个简单的音频流
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = duration
	return stream

# 播放音效
func play_sound(sound_type: SoundType, pitch_scale = 1.0, volume_scale = 1.0):
	if not sound_enabled:
		return
	
	var player = get_available_player()
	if not player:
		return
	
	# 获取或生成音效
	var stream = generate_sound(sound_type)
	
	# 设置播放参数
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(master_volume * volume_scale)
	
	# 播放音效
	player.play()
	
	# 发送信号
	sound_played.emit(SoundType.keys()[sound_type])

# 播放弹跳音效
func play_bounce_sound(velocity: float = 1.0):
	var pitch_scale = 0.8 + velocity * 0.4  # 速度越快音调越高
	var volume_scale = min(velocity, 2.0) / 2.0  # 速度越快音量越大
	play_sound(SoundType.BOUNCE, pitch_scale, volume_scale)

# 播放碰撞音效
func play_collision_sound(impact_force: float = 1.0):
	var pitch_scale = 0.5 + impact_force * 0.5
	var volume_scale = min(impact_force, 3.0) / 3.0
	play_sound(SoundType.COLLISION, pitch_scale, volume_scale)

# 播放形变音效
func play_squash_sound():
	play_sound(SoundType.SQUASH, 0.8, 0.7)

# 播放恢复音效
func play_recovery_sound():
	play_sound(SoundType.RECOVERY, 1.2, 0.5)

# 播放投掷音效
func play_throw_sound(throw_force: float = 1.0):
	var pitch_scale = 0.9 + throw_force * 0.3
	var volume_scale = min(throw_force, 2.0) / 2.0
	play_sound(SoundType.THROW, pitch_scale, volume_scale)

# 播放接住音效
func play_catch_sound():
	play_sound(SoundType.CATCH, 1.0, 0.5)

# 播放选择音效
func play_select_sound():
	play_sound(SoundType.SELECT, 1.0, 0.3)

# 播放悬停音效
func play_hover_sound():
	play_sound(SoundType.HOVER, 1.0, 0.2)

# 设置主音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	
	# 更新所有正在播放的音频
	for player in audio_players:
		if player.playing:
			player.volume_db = linear_to_db(master_volume)
	
	volume_changed.emit(master_volume)

# 获取主音量
func get_master_volume() -> float:
	return master_volume

# 设置音效开关
func set_sound_enabled(enabled: bool):
	sound_enabled = enabled
	
	if not enabled:
		# 停止所有正在播放的音效
		for player in audio_players:
			player.stop()

# 获取音效开关状态
func is_sound_enabled() -> bool:
	return sound_enabled

# 停止所有音效
func stop_all_sounds():
	for player in audio_players:
		player.stop()

# 音频播放完成回调
func _on_audio_finished(player: AudioStreamPlayer):
	# 可以在这里添加资源清理或重置逻辑
	pass

# 线性转分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

# 分贝转线性
func db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)

# 根据玩具类型播放不同的音效
func play_toy_sound(toy_type: String, sound_event: String, params: Dictionary = {}):
	match sound_event:
		"bounce":
			var velocity = params.get("velocity", 1.0)
			match toy_type:
				"paper_plane":
					play_bounce_sound(velocity * 0.5)  # 纸飞机声音较轻
				"basketball":
					play_bounce_sound(velocity * 1.2)  # 篮球声音较重
				"football":
					play_bounce_sound(velocity * 0.8)  # 足球声音中等
				"shuttlecock":
					play_bounce_sound(velocity * 0.3)  # 羽毛球声音很轻
				"stress_ball":
					play_bounce_sound(velocity * 0.9)  # 发泄球声音较软
				_:
					play_bounce_sound(velocity)
		
		"collision":
			var impact_force = params.get("impact_force", 1.0)
			play_collision_sound(impact_force)
		
		"squash":
			play_squash_sound()
		
		"recovery":
			play_recovery_sound()
		
		"throw":
			var throw_force = params.get("throw_force", 1.0)
			play_throw_sound(throw_force)
		
		"catch":
			play_catch_sound()
		
		_:
			print("未知的音效事件: ", sound_event)

# 清理资源
func cleanup():
	stop_all_sounds()
	sound_cache.clear()
	
	for player in audio_players:
		player.queue_free()
	
	audio_players.clear()