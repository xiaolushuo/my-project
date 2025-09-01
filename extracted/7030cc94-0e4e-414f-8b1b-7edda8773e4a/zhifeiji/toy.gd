extends RigidBody2D

@export var toy_type: String = ""
var is_squashed: bool = false
var squash_timer: float = 0.0
var original_texture: Texture2D
var squashed_texture: Texture2D
var tween: Tween

# 碰撞检测相关
var collision_velocity_threshold: float = 500.0

# 管理器引用
var settings_manager: Node
var sound_manager: Node
var particle_manager: Node

func _ready():
	# 获取管理器引用
	settings_manager = get_node_or_null("/root/SettingsManager")
	sound_manager = get_node_or_null("/root/SoundManager")
	particle_manager = get_node_or_null("/root/ParticleManager")
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	
	# 设置玩具特定属性
	setup_toy_properties()
	
	# 连接到设置管理器信号
	if settings_manager:
		settings_manager.toy_settings_changed.connect(_on_toy_settings_changed)

func setup_toy_properties():
	var sprite = $Sprite2D
	match toy_type:
		"stress_ball":
			if settings_manager:
				var settings = settings_manager.get_toy_settings(toy_type)
				collision_velocity_threshold = settings.get("squash_threshold", 400.0)
			if ResourceLoader.exists("res://assets/stress_ball.png"):
				original_texture = load("res://assets/stress_ball.png")
			if ResourceLoader.exists("res://assets/stress_ball_squashed.png"):
				squashed_texture = load("res://assets/stress_ball_squashed.png")

func _on_body_entered(body):
	if toy_type == "stress_ball" and not is_squashed:
		var velocity = linear_velocity.length()
		if velocity > collision_velocity_threshold:
			trigger_squash_effect()
	
	# 播放弹跳音效和粒子效果
	if sound_manager:
		sound_manager.play_toy_sound(toy_type, "bounce", {"velocity": velocity})
	if particle_manager:
		particle_manager.play_toy_effect(toy_type, "bounce", {
			"position": global_position,
			"velocity": linear_velocity
		})

func trigger_squash_effect():
	if is_squashed:
		return
			
	is_squashed = true
	squash_timer = 0.0
	
	var sprite = $Sprite2D
	var collision = $CollisionShape2D
	
	# 创建补间动画
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	# 纹理切换
	if squashed_texture:
		sprite.texture = squashed_texture
	
	# 缩放动画 - 瞬间压扁
	sprite.scale = Vector2(1.5, 0.3)
	
	# 修改碰撞形状
	if collision.shape is CircleShape2D:
		var new_shape = CapsuleShape2D.new()
		new_shape.radius = 20
		new_shape.height = 10
		collision.shape = new_shape
	
	# 获取恢复时间
	var recovery_time = 2.5
	if settings_manager:
		recovery_time = settings_manager.get_toy_settings(toy_type).get("recovery_time", 2.5)
	
	# 恢复时间后恢复
	await get_tree().create_timer(recovery_time).timeout
	restore_ball_shape()

func restore_ball_shape():
	if not is_squashed:
		return
			
	is_squashed = false
	squash_timer = 0.0
	
	var sprite = $Sprite2D
	var collision = $CollisionShape2D
	
	# 创建恢复动画
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	# 弹性恢复动画
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# 恢复纹理
	if original_texture:
		sprite.texture = original_texture
	
	# 恢复碰撞形状
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 32
	collision.shape = circle_shape

func _process(delta):
	if is_squashed:
		squash_timer += delta

# 玩具设置变更回调
func _on_toy_settings_changed(changed_toy_type: String):
	if changed_toy_type == toy_type:
		if settings_manager:
			var settings = settings_manager.get_toy_settings(toy_type)
			collision_velocity_threshold = settings.get("squash_threshold", 400.0)
			
			# 更新物理属性
			mass = settings.get("mass", 0.1)
			physics_material_override.bounce = settings.get("bounce", 0.5)
			physics_material_override.friction = settings.get("friction", 0.5)
			angular_damp = settings.get("angular_damp", 1.0)