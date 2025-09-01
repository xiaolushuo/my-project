extends Node

# 粒子效果管理器 - 管理游戏中的所有粒子效果
# 支持碰撞、弹跳、形变等事件的粒子效果

signal particle_effect_started(effect_name: String, position: Vector2)
signal particle_effect_ended(effect_name: String)

# 粒子效果类型枚举
enum EffectType {
	BOUNCE,
	COLLISION,
	SQUASH,
	RECOVERY,
	THROW,
	CATCH,
	SPARKLE,
	TRAIL
}

# 粒子效果池
var particle_pools = {}
var max_particles_per_effect = 50

# 效果启用状态
var effects_enabled = true

# 粒子参数配置
var effect_parameters = {
	EffectType.BOUNCE: {
		"count": 8,
		"lifetime": 0.5,
		"initial_velocity_min": 50.0,
		"initial_velocity_max": 150.0,
		"spread": 45.0,
		"color_start": Color.WHITE,
		"color_end": Color.TRANSPARENT,
		"size_start": 2.0,
		"size_end": 0.5,
		"gravity": Vector2(0, 200.0),
		"damping": 0.95
	},
	EffectType.COLLISION: {
		"count": 12,
		"lifetime": 0.8,
		"initial_velocity_min": 100.0,
		"initial_velocity_max": 300.0,
		"spread": 90.0,
		"color_start": Color.YELLOW,
		"color_end": Color.RED,
		"size_start": 3.0,
		"size_end": 1.0,
		"gravity": Vector2(0, 300.0),
		"damping": 0.9
	},
	EffectType.SQUASH: {
		"count": 15,
		"lifetime": 1.0,
		"initial_velocity_min": 20.0,
		"initial_velocity_max": 80.0,
		"spread": 180.0,
		"color_start": Color.RED,
		"color_end": Color.DARK_RED,
		"size_start": 4.0,
		"size_end": 1.0,
		"gravity": Vector2(0, 100.0),
		"damping": 0.98
	},
	EffectType.RECOVERY: {
		"count": 20,
		"lifetime": 1.2,
		"initial_velocity_min": 30.0,
		"initial_velocity_max": 100.0,
		"spread": 360.0,
		"color_start": Color.GREEN,
		"color_end": Color.TRANSPARENT,
		"size_start": 2.0,
		"size_end": 0.0,
		"gravity": Vector2(0, -50.0),
		"damping": 0.92
	},
	EffectType.THROW: {
		"count": 6,
		"lifetime": 0.3,
		"initial_velocity_min": 80.0,
		"initial_velocity_max": 200.0,
		"spread": 30.0,
		"color_start": Color.CYAN,
		"color_end": Color.BLUE,
		"size_start": 2.0,
		"size_end": 0.5,
		"gravity": Vector2(0, 150.0),
		"damping": 0.96
	},
	EffectType.CATCH: {
		"count": 10,
		"lifetime": 0.4,
		"initial_velocity_min": 20.0,
		"initial_velocity_max": 60.0,
		"spread": 120.0,
		"color_start": Color.WHITE,
		"color_end": Color.TRANSPARENT,
		"size_start": 3.0,
		"size_end": 0.0,
		"gravity": Vector2(0, 100.0),
		"damping": 0.94
	},
	EffectType.SPARKLE: {
		"count": 5,
		"lifetime": 0.6,
		"initial_velocity_min": 10.0,
		"initial_velocity_max": 40.0,
		"spread": 360.0,
		"color_start": Color.YELLOW,
		"color_end": Color.TRANSPARENT,
		"size_start": 2.0,
		"size_end": 0.0,
		"gravity": Vector2(0, -20.0),
		"damping": 0.9
	},
	EffectType.TRAIL: {
		"count": 3,
		"lifetime": 0.2,
		"initial_velocity_min": 10.0,
		"initial_velocity_max": 30.0,
		"spread": 15.0,
		"color_start": Color.WHITE,
		"color_end": Color.TRANSPARENT,
		"size_start": 1.5,
		"size_end": 0.0,
		"gravity": Vector2.ZERO,
		"damping": 0.95
	}
}

func _ready():
	# 初始化粒子池
	initialize_particle_pools()
	print("粒子效果管理器已初始化")

func _enter_tree():
	# 确保在场景树中时管理器已初始化
	if particle_pools.is_empty():
		initialize_particle_pools()

# 初始化粒子池
func initialize_particle_pools():
	particle_pools.clear()
	
	for effect_type in EffectType.values():
		var pool = []
		for i in range(max_particles_per_effect):
			var particle = create_particle()
			pool.append(particle)
		particle_pools[effect_type] = pool

# 创建单个粒子
func create_particle() -> CPUParticles2D:
	var particle = CPUParticles2D.new()
	particle.emitting = false
	particle.one_shot = true
	particle.explosiveness = 1.0
	particle.randomness = 0.3
	particle.fixed_fps = 60
	particle.fract_delta = true
	particle.interpolate = true
	particle.local_coords = false
	add_child(particle)
	return particle

# 获取可用的粒子
func get_available_particle(effect_type: EffectType) -> CPUParticles2D:
	var pool = particle_pools[effect_type]
	
	for particle in pool:
		if not particle.emitting:
			return particle
	
	# 如果没有可用的粒子，创建一个新的
	var new_particle = create_particle()
	pool.append(new_particle)
	return new_particle

# 播放粒子效果
func play_effect(effect_type: EffectType, position: Vector2, direction: Vector2 = Vector2.ZERO, custom_params: Dictionary = {}):
	if not effects_enabled:
		return
	
	var particle = get_available_particle(effect_type)
	if not particle:
		return
	
	# 获取效果参数
	var params = effect_parameters[effect_type].duplicate()
	
	# 应用自定义参数
	for key in custom_params:
		params[key] = custom_params[key]
	
	# 配置粒子
	configure_particle(particle, params, position, direction)
	
	# 播放效果
	particle.restart()
	particle.emitting = true
	
	# 发送信号
	particle_effect_started.emit(EffectType.keys()[effect_type], position)
	
	# 设置自动清理
	await get_tree().create_timer(params.lifetime + 0.5).timeout
	particle.emitting = false
	particle_effect_ended.emit(EffectType.keys()[effect_type], position)

# 配置粒子参数
func configure_particle(particle: CPUParticles2D, params: Dictionary, position: Vector2, direction: Vector2):
	particle.global_position = position
	particle.amount = params.count
	particle.lifetime = params.lifetime
	particle.direction = direction.angle() if direction != Vector2.ZERO else 0
	particle.spread = deg_to_rad(params.spread)
	particle.gravity = params.gravity
	particle.damping = params.damping
	
	# 设置颜色
	var gradient = Gradient.new()
	gradient.add_point(0.0, params.color_start)
	gradient.add_point(1.0, params.color_end)
	particle.color_gradient = gradient
	
	# 设置大小
	var size_gradient = Curve.new()
	size_gradient.add_point(Vector2(0.0, params.size_start))
	size_gradient.add_point(Vector2(1.0, params.size_end))
	particle.size_curve = size_gradient
	
	# 设置初始速度
	var speed_min = params.initial_velocity_min
	var speed_max = params.initial_velocity_max
	particle.initial_velocity_min = speed_min
	particle.initial_velocity_max = speed_max

# 播放弹跳效果
func play_bounce_effect(position: Vector2, velocity: Vector2 = Vector2.ZERO):
	var impact_force = velocity.length() / 500.0
	var custom_params = {
		"count": int(8 + impact_force * 8),
		"initial_velocity_min": 50.0 + impact_force * 100,
		"initial_velocity_max": 150.0 + impact_force * 200
	}
	play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)

# 播放碰撞效果
func play_collision_effect(position: Vector2, impact_force: float = 1.0):
	var custom_params = {
		"count": int(12 + impact_force * 8),
		"initial_velocity_min": 100.0 + impact_force * 150,
		"initial_velocity_max": 300.0 + impact_force * 300
	}
	play_effect(EffectType.COLLISION, position, Vector2.ZERO, custom_params)

# 播放形变效果
func play_squash_effect(position: Vector2):
	play_effect(EffectType.SQUASH, position, Vector2.ZERO)

# 播放恢复效果
func play_recovery_effect(position: Vector2):
	play_effect(EffectType.RECOVERY, position, Vector2.ZERO)

# 播放投掷效果
func play_throw_effect(position: Vector2, direction: Vector2, throw_force: float = 1.0):
	var custom_params = {
		"count": int(6 + throw_force * 4),
		"initial_velocity_min": 80.0 + throw_force * 100,
		"initial_velocity_max": 200.0 + throw_force * 200
	}
	play_effect(EffectType.THROW, position, direction, custom_params)

# 播放接住效果
func play_catch_effect(position: Vector2):
	play_effect(EffectType.CATCH, position, Vector2.ZERO)

# 播放闪光效果
func play_sparkle_effect(position: Vector2):
	play_effect(EffectType.SPARKLE, position, Vector2.ZERO)

# 播放轨迹效果
func play_trail_effect(position: Vector2, direction: Vector2):
	play_effect(EffectType.TRAIL, position, direction)

# 根据玩具类型播放不同的粒子效果
func play_toy_effect(toy_type: String, effect_event: String, params: Dictionary = {}):
	var position = params.get("position", Vector2.ZERO)
	var velocity = params.get("velocity", Vector2.ZERO)
	var impact_force = params.get("impact_force", 1.0)
	
	match effect_event:
		"bounce":
			match toy_type:
				"paper_plane":
					# 纸飞机：轻柔的白色粒子
					var custom_params = {
						"color_start": Color.WHITE,
						"color_end": Color.LIGHT_GRAY,
						"count": 5,
						"initial_velocity_min": 30,
						"initial_velocity_max": 80
					}
					play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)
				"basketball":
					# 篮球：橙色粒子，较多
					var custom_params = {
						"color_start": Color.ORANGE,
						"color_end": Color.DARK_ORANGE,
						"count": 12,
						"initial_velocity_min": 80,
						"initial_velocity_max": 200
					}
					play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)
				"football":
					# 足球：棕色粒子，中等
					var custom_params = {
						"color_start": Color.SADDLE_BROWN,
						"color_end": Color.BROWN,
						"count": 8,
						"initial_velocity_min": 60,
						"initial_velocity_max": 150
					}
					play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)
				"shuttlecock":
					# 羽毛球：白色轻柔粒子
					var custom_params = {
						"color_start": Color.WHITE,
						"color_end": Color.TRANSPARENT,
						"count": 3,
						"initial_velocity_min": 20,
						"initial_velocity_max": 50,
						"gravity": Vector2(0, 50)
					}
					play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)
				"stress_ball":
					# 发泄球：红色粒子，弹性效果
					var custom_params = {
						"color_start": Color.RED,
						"color_end": Color.PINK,
						"count": 10,
						"initial_velocity_min": 70,
						"initial_velocity_max": 180
					}
					play_effect(EffectType.BOUNCE, position, velocity.normalized(), custom_params)
				_:
					play_bounce_effect(position, velocity)
		
		"collision":
			play_collision_effect(position, impact_force)
		
		"squash":
			play_squash_effect(position)
		
		"recovery":
			play_recovery_effect(position)
		
		"throw":
			var direction = velocity.normalized()
			var throw_force = velocity.length() / 1000.0
			play_throw_effect(position, direction, throw_force)
		
		"catch":
			play_catch_effect(position)
		
		"sparkle":
			play_sparkle_effect(position)
		
		_:
			print("未知的粒子效果事件: ", effect_event)

# 设置效果启用状态
func set_effects_enabled(enabled: bool):
	effects_enabled = enabled
	
	if not enabled:
		# 停止所有粒子效果
		stop_all_effects()

# 获取效果启用状态
func are_effects_enabled() -> bool:
	return effects_enabled

# 停止所有粒子效果
func stop_all_effects():
	for effect_type in particle_pools:
		var pool = particle_pools[effect_type]
		for particle in pool:
			particle.emitting = false

# 清理资源
func cleanup():
	stop_all_effects()
	
	for effect_type in particle_pools:
		var pool = particle_pools[effect_type]
		for particle in pool:
			particle.queue_free()
	
	particle_pools.clear()

# 创建连续粒子效果（用于轨迹等）
func create_continuous_effect(effect_type: EffectType, parent_node: Node2D) -> CPUParticles2D:
	var particle = create_particle()
	particle.one_shot = false
	particle.lifetime = 0.5
	particle.amount = 3
	particle.emitting = true
	
	# 配置基本参数
	var params = effect_parameters[effect_type]
	configure_particle(particle, params, Vector2.ZERO, Vector2.ZERO)
	
	# 添加到父节点
	parent_node.add_child(particle)
	
	return particle

# 停止连续效果
func stop_continuous_effect(particle: CPUParticles2D):
	if particle and is_instance_valid(particle):
		particle.emitting = false
		await get_tree().create_timer(particle.lifetime).timeout
		if is_instance_valid(particle):
			particle.queue_free()