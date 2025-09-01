extends Node

# 设置管理器 - 管理游戏设置和玩具属性配置
signal settings_changed
signal toy_settings_changed(toy_type: String)

# 默认玩具设置
var default_toy_settings = {
	"paper_plane": {
		"mass": 0.1,
		"bounce": 0.6,
		"friction": 0.3,
		"angular_damp": 2.0,
		"enabled": true,
		"color": Color.WHITE
	},
	"basketball": {
		"mass": 0.6,
		"bounce": 0.8,
		"friction": 0.7,
		"angular_damp": 1.0,
		"enabled": true,
		"color": Color.ORANGE
	},
	"football": {
		"mass": 0.4,
		"bounce": 0.7,
		"friction": 0.6,
		"angular_damp": 1.2,
		"enabled": true,
		"color": Color.SADDLE_BROWN
	},
	"shuttlecock": {
		"mass": 0.05,
		"bounce": 0.3,
		"friction": 0.9,
		"angular_damp": 5.0,
		"enabled": true,
		"color": Color.WHITE
	},
	"stress_ball": {
		"mass": 0.3,
		"bounce": 0.9,
		"friction": 0.5,
		"angular_damp": 3.0,
		"enabled": true,
		"color": Color.RED,
		"squash_threshold": 400.0,
		"recovery_time": 2.5
	}
}

# 全局设置
var global_settings = {
	"sound_enabled": true,
	"sound_volume": 0.8,
	"particle_effects": true,
	"show_help": true,
	"auto_save": true,
	"window_transparency": 1.0,
	"gravity": 980.0,
	"air_resistance": 0.02
}

# 当前设置
var current_toy_settings = {}
var current_global_settings = {}

# 配置文件路径
var config_path = "user://physics_toys_config.cfg"

func _ready():
	load_settings()
	apply_global_settings()

func _enter_tree():
	# 确保在场景树中时设置是加载的
	if current_toy_settings.is_empty():
		load_settings()

# 加载设置
func load_settings():
	# 初始化当前设置为默认值
	current_toy_settings = default_toy_settings.duplicate(true)
	current_global_settings = global_settings.duplicate(true)
	
	# 尝试从文件加载配置
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		# 加载全局设置
		for section in config.get_sections():
			if section == "global":
				for key in config.get_section_keys(section):
					if key in current_global_settings:
						current_global_settings[key] = config.get_value(section, key)
			elif section in current_toy_settings:
				for key in config.get_section_keys(section):
					if key in current_toy_settings[section]:
						current_toy_settings[section][key] = config.get_value(section, key)
		
		print("设置已从配置文件加载")
	else:
		print("使用默认设置")

# 保存设置
func save_settings():
	var config = ConfigFile.new()
	
	# 保存全局设置
	config.set_value("global", "version", "1.0")
	for key in current_global_settings:
		config.set_value("global", key, current_global_settings[key])
	
	# 保存玩具设置
	for toy_type in current_toy_settings:
		for key in current_toy_settings[toy_type]:
			config.set_value(toy_type, key, current_toy_settings[toy_type][key])
	
	# 保存到文件
	var err = config.save(config_path)
	if err == OK:
		print("设置已保存")
		return true
	else:
		print("保存设置失败: ", err)
		return false

# 获取玩具设置
func get_toy_settings(toy_type: String) -> Dictionary:
	if toy_type in current_toy_settings:
		return current_toy_settings[toy_type]
	return {}

# 更新玩具设置
func update_toy_settings(toy_type: String, settings: Dictionary):
	if toy_type in current_toy_settings:
		for key in settings:
			if key in current_toy_settings[toy_type]:
				current_toy_settings[toy_type][key] = settings[key]
		
		# 发送设置变更信号
		toy_settings_changed.emit(toy_type)
		
		# 自动保存
		if current_global_settings.get("auto_save", true):
			save_settings()

# 获取全局设置
func get_global_settings() -> Dictionary:
	return current_global_settings

# 更新全局设置
func update_global_settings(settings: Dictionary):
	for key in settings:
		if key in current_global_settings:
			current_global_settings[key] = settings[key]
	
	# 发送设置变更信号
	settings_changed.emit()
	
	# 应用全局设置
	apply_global_settings()
	
	# 自动保存
	if current_global_settings.get("auto_save", true):
		save_settings()

# 应用全局设置
func apply_global_settings():
	# 应用重力设置
	ProjectSettings.set_setting("physics/2d/default_gravity", current_global_settings.gravity)
	
	# 应用窗口透明度
	if Engine.is_editor_hint():
		return
	
	var window = get_window()
	if window:
		# 设置窗口透明度
		var transparency = current_global_settings.get("window_transparency", 1.0)
		# 注意：透明度设置可能需要根据具体平台调整

# 重置为默认设置
func reset_to_defaults():
	current_toy_settings = default_toy_settings.duplicate(true)
	current_global_settings = global_settings.duplicate(true)
	
	# 发送设置变更信号
	settings_changed.emit()
	for toy_type in current_toy_settings:
		toy_settings_changed.emit(toy_type)
	
	# 应用设置
	apply_global_settings()
	
	# 保存设置
	save_settings()

# 导出设置为JSON
func export_settings() -> String:
	var export_data = {
		"global": current_global_settings,
		"toys": current_toy_settings,
		"version": "1.0",
		"export_time": Time.get_datetime_string_from_system()
	}
	return JSON.stringify(export_data, "\t")

# 从JSON导入设置
func import_settings(json_data: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_data)
	
	if parse_result != OK:
		print("导入设置失败: ", json.get_error_message())
		return false
	
	var data = json.data
	
	# 导入全局设置
	if "global" in data:
		for key in data.global:
			if key in current_global_settings:
				current_global_settings[key] = data.global[key]
	
	# 导入玩具设置
	if "toys" in data:
		for toy_type in data.toys:
			if toy_type in current_toy_settings:
				for key in data.toys[toy_type]:
					if key in current_toy_settings[toy_type]:
						current_toy_settings[toy_type][key] = data.toys[toy_type][key]
	
	# 应用设置
	apply_global_settings()
	
	# 发送设置变更信号
	settings_changed.emit()
	for toy_type in current_toy_settings:
		toy_settings_changed.emit(toy_type)
	
	# 保存设置
	save_settings()
	
	print("设置导入成功")
	return true

# 获取可用的玩具类型
func get_available_toy_types() -> Array:
	return current_toy_settings.keys()

# 检查玩具是否启用
func is_toy_enabled(toy_type: String) -> bool:
	var settings = get_toy_settings(toy_type)
	return settings.get("enabled", true)

# 设置玩具启用状态
func set_toy_enabled(toy_type: String, enabled: bool):
	update_toy_settings(toy_type, {"enabled": enabled})

# 获取玩具物理参数
func get_toy_physics_params(toy_type: String) -> Dictionary:
	var settings = get_toy_settings(toy_type)
	return {
		"mass": settings.get("mass", 0.1),
		"bounce": settings.get("bounce", 0.5),
		"friction": settings.get("friction", 0.5),
		"angular_damp": settings.get("angular_damp", 1.0)
	}

# 验证设置值
func validate_setting_value(toy_type: String, key: String, value) -> bool:
	match key:
		"mass":
			return value is float and value > 0 and value <= 10.0
		"bounce":
			return value is float and value >= 0 and value <= 1.0
		"friction":
			return value is float and value >= 0 and value <= 1.0
		"angular_damp":
			return value is float and value >= 0 and value <= 10.0
		"sound_volume":
			return value is float and value >= 0 and value <= 1.0
		"window_transparency":
			return value is float and value >= 0 and value <= 1.0
		"gravity":
			return value is float and value >= 0 and value <= 2000.0
		"squash_threshold":
			return value is float and value > 0 and value <= 1000.0
		"recovery_time":
			return value is float and value > 0 and value <= 10.0
		_:
			return true  # 其他设置默认通过验证