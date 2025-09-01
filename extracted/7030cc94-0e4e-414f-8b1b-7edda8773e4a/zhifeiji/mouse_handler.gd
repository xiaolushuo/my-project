extends Node2D

# 鼠标交互管理器
signal toy_clicked(toy: RigidBody2D)
signal toy_released(toy: RigidBody2D, velocity: Vector2)

var dragging_toy: RigidBody2D = null
var drag_start_pos: Vector2
var drag_current_pos: Vector2
var drag_start_time: float
var drag_positions: Array[Vector2] = []
var drag_times: Array[float] = []

const POSITION_HISTORY_SIZE = 10
const MIN_THROW_VELOCITY = 50.0
const MAX_THROW_VELOCITY = 2000.0
const VELOCITY_SMOOTHING = 0.8

func _ready():
	# 确保鼠标事件能被接收
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				handle_mouse_press(event.global_position)
			else:
				handle_mouse_release(event.global_position)
	
	elif event is InputEventMouseMotion and dragging_toy:
		handle_mouse_drag(event.global_position)

func handle_mouse_press(mouse_pos: Vector2):
	# 检查是否点击了玩具
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = 1  # 假设玩具在第1层
	
	var result = space_state.intersect_point(query)
	if result.size() > 0:
		var body = result[0].collider
		if body is RigidBody2D:
			start_dragging(body, mouse_pos)

func start_dragging(toy: RigidBody2D, mouse_pos: Vector2):
	dragging_toy = toy
	drag_start_pos = mouse_pos
	drag_current_pos = mouse_pos
	drag_start_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
	
	# 清空历史位置
	drag_positions.clear()
	drag_times.clear()
	
	# 暂停玩具物理
	toy.freeze = true
	toy.sleeping = false
	
	# 发送信号
	toy_clicked.emit(toy)

func handle_mouse_drag(mouse_pos: Vector2):
	if not dragging_toy:
		return
	
	drag_current_pos = mouse_pos
	var current_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
	
	# 更新玩具位置
	dragging_toy.global_position = mouse_pos
	
	# 记录位置历史用于计算速度
	drag_positions.append(mouse_pos)
	drag_times.append(current_time)
	
	# 限制历史记录大小
	if drag_positions.size() > POSITION_HISTORY_SIZE:
		drag_positions.pop_front()
		drag_times.pop_front()

func handle_mouse_release(mouse_pos: Vector2):
	if not dragging_toy:
		return
	
	var toy = dragging_toy
	var current_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
	
	# 计算抛出速度
	var throw_velocity = calculate_throw_velocity(current_time)
	
	# 恢复物理
	toy.freeze = false
	
	# 应用抛出力
	if throw_velocity.length() > MIN_THROW_VELOCITY:
		var impulse = throw_velocity * toy.mass
		impulse = impulse.limit_length(MAX_THROW_VELOCITY * toy.mass)
		toy.apply_central_impulse(impulse)
		
		# 添加旋转
		var torque_factor = throw_velocity.length() / 1000.0
		var torque = randf_range(-200, 200) * torque_factor
		toy.apply_torque_impulse(torque)
	
	# 发送信号
	toy_released.emit(toy, throw_velocity)
	
	# 清理
	dragging_toy = null
	drag_positions.clear()
	drag_times.clear()

func calculate_throw_velocity(current_time: float) -> Vector2:
	if drag_positions.size() < 2:
		return Vector2.ZERO
	
	# 使用最近几个位置计算平均速度
	var velocity_samples: Array[Vector2] = []
	var sample_count = min(5, drag_positions.size() - 1)
	
	for i in range(sample_count):
		var idx = drag_positions.size() - 1 - i
		if idx > 0:
			var pos_diff = drag_positions[idx] - drag_positions[idx - 1]
			var time_diff = max(drag_times[idx] - drag_times[idx - 1], 0.016)  # 最小16ms
			velocity_samples.append(pos_diff / time_diff)
	
	if velocity_samples.is_empty():
		return Vector2.ZERO
	
	# 计算加权平均速度（最近的样本权重更高）
	var weighted_velocity = Vector2.ZERO
	var total_weight = 0.0
	
	for i in range(velocity_samples.size()):
		var weight = (i + 1.0) / velocity_samples.size()  # 越新权重越高
		weighted_velocity += velocity_samples[i] * weight
		total_weight += weight
	
	if total_weight > 0:
		weighted_velocity /= total_weight
	
	return weighted_velocity

func get_dragging_toy() -> RigidBody2D:
	return dragging_toy

func is_dragging() -> bool:
	return dragging_toy != null