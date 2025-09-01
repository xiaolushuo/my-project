extends Control

# 设置面板 - 提供图形化界面来调整游戏设置
signal settings_closed
signal settings_applied

@onready var settings_manager = $"/root/SettingsManager" as SettingsManager
@onready var tab_container = $MarginContainer/VBoxContainer/TabContainer
@onready var close_button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var toy_type_option = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ToySelector/ToyTypeOption
@onready var enabled_check = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ToySelector/EnabledCheck
@onready var stress_ball_settings = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/StressBallSettings

# 玩具设置控件
@onready var mass_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/MassControl/MassSlider
@onready var mass_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/MassControl/MassValue
@onready var bounce_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/BounceControl/BounceSlider
@onready var bounce_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/BounceControl/BounceValue
@onready var friction_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/FrictionControl/FrictionSlider
@onready var friction_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/FrictionControl/FrictionValue
@onready var angular_damp_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/AngularDampControl/AngularDampSlider
@onready var angular_damp_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/AngularDampControl/AngularDampValue

# 发泄球专用设置
@onready var squash_threshold_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/StressBallSettings/SquashThresholdControl/SquashThresholdSlider
@onready var squash_threshold_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/StressBallSettings/SquashThresholdControl/SquashThresholdValue
@onready var recovery_time_slider = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/StressBallSettings/RecoveryTimeControl/RecoveryTimeSlider
@onready var recovery_time_value = $MarginContainer/VBoxContainer/TabContainer/ToysTab/ScrollContainer/ToySettings/StressBallSettings/RecoveryTimeControl/RecoveryTimeValue

# 全局设置控件
@onready var sound_check_box = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/SoundSection/SoundEnabled/SoundCheckBox
@onready var sound_volume_slider = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/SoundSection/SoundVolume/SoundVolumeSlider
@onready var sound_volume_value = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/SoundSection/SoundVolume/SoundVolumeValue
@onready var gravity_slider = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/PhysicsSection/GravityControl/GravitySlider
@onready var gravity_value = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/PhysicsSection/GravityControl/GravityValue
@onready var transparency_slider = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/WindowSection/TransparencyControl/TransparencySlider
@onready var transparency_value = $MarginContainer/VBoxContainer/TabContainer/GlobalTab/WindowSection/TransparencyControl/TransparencyValue

# 按钮
@onready var reset_button = $MarginContainer/VBoxContainer/Buttons/ResetButton
@onready var export_button = $MarginContainer/VBoxContainer/Buttons/ExportButton
@onready var import_button = $MarginContainer/VBoxContainer/Buttons/ImportButton
@onready var save_button = $MarginContainer/VBoxContainer/Buttons/SaveButton

var current_toy_type = ""
var is_initializing = false

func _ready():
	# 连接信号
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	# 连接滑块信号
	mass_slider.value_changed.connect(_on_mass_changed)
	bounce_slider.value_changed.connect(_on_bounce_changed)
	friction_slider.value_changed.connect(_on_friction_changed)
	angular_damp_slider.value_changed.connect(_on_angular_damp_changed)
	squash_threshold_slider.value_changed.connect(_on_squash_threshold_changed)
	recovery_time_slider.value_changed.connect(_on_recovery_time_changed)
	
	sound_check_box.toggled.connect(_on_sound_enabled_changed)
	sound_volume_slider.value_changed.connect(_on_sound_volume_changed)
	gravity_slider.value_changed.connect(_on_gravity_changed)
	transparency_slider.value_changed.connect(_on_transparency_changed)
	
	# 连接玩具选择器
	toy_type_option.item_selected.connect(_on_toy_type_selected)
	enabled_check.toggled.connect(_on_enabled_changed)
	
	# 初始化界面
	initialize_ui()
	load_current_settings()
	
	# 初始隐藏
	hide()

func initialize_ui():
	# 填充玩具类型选项
	toy_type_option.clear()
	var toy_types = settings_manager.get_available_toy_types()
	for toy_type in toy_types:
		var display_name = get_toy_display_name(toy_type)
		toy_type_option.add_item(display_name)
	
	# 如果有玩具类型，选择第一个
	if toy_types.size() > 0:
		current_toy_type = toy_types[0]
		toy_type_option.selected = 0
		update_toy_controls_visibility()

func get_toy_display_name(toy_type: String) -> String:
	match toy_type:
		"paper_plane":
			return "纸飞机"
		"basketball":
			return "篮球"
		"football":
			return "足球"
		"shuttlecock":
			return "羽毛球"
		"stress_ball":
			return "发泄球"
		_:
			return toy_type

func load_current_settings():
	is_initializing = true
	
	# 加载当前选择的玩具设置
	if current_toy_type != "":
		load_toy_settings(current_toy_type)
	
	# 加载全局设置
	load_global_settings()
	
	is_initializing = false

func load_toy_settings(toy_type: String):
	var settings = settings_manager.get_toy_settings(toy_type)
	
	# 更新控件值
	mass_slider.value = settings.get("mass", 0.1)
	bounce_slider.value = settings.get("bounce", 0.5)
	friction_slider.value = settings.get("friction", 0.5)
	angular_damp_slider.value = settings.get("angular_damp", 1.0)
	enabled_check.button_pressed = settings.get("enabled", true)
	
	# 更新显示值
	update_value_labels()
	
	# 如果是发泄球，加载特殊设置
	if toy_type == "stress_ball":
		squash_threshold_slider.value = settings.get("squash_threshold", 400.0)
		recovery_time_slider.value = settings.get("recovery_time", 2.5)
		squash_threshold_value.text = str(int(squash_threshold_slider.value))
		recovery_time_value.text = str(recovery_time_slider.value) + "s"

func load_global_settings():
	var global_settings = settings_manager.get_global_settings()
	
	sound_check_box.button_pressed = global_settings.get("sound_enabled", true)
	sound_volume_slider.value = global_settings.get("sound_volume", 0.8)
	gravity_slider.value = global_settings.get("gravity", 980.0)
	transparency_slider.value = global_settings.get("window_transparency", 1.0)
	
	# 更新显示值
	sound_volume_value.text = str(int(sound_volume_slider.value * 100)) + "%"
	gravity_value.text = str(int(gravity_slider.value))
	transparency_value.text = str(int(transparency_slider.value * 100)) + "%"

func update_toy_controls_visibility():
	# 显示/隐藏发泄球专用设置
	stress_ball_settings.visible = (current_toy_type == "stress_ball")

func update_value_labels():
	mass_value.text = str(mass_slider.value).pad_decimals(2)
	bounce_value.text = str(bounce_slider.value).pad_decimals(2)
	friction_value.text = str(friction_slider.value).pad_decimals(2)
	angular_damp_value.text = str(angular_damp_slider.value).pad_decimals(1)

# 信号处理函数
func _on_close_pressed():
	hide()
	settings_closed.emit()

func _on_toy_type_selected(index: int):
	var toy_types = settings_manager.get_available_toy_types()
	if index >= 0 and index < toy_types.size():
		current_toy_type = toy_types[index]
		load_toy_settings(current_toy_type)
		update_toy_controls_visibility()

func _on_enabled_changed(enabled: bool):
	if not is_initializing:
		settings_manager.set_toy_enabled(current_toy_type, enabled)

func _on_mass_changed(value: float):
	mass_value.text = str(value).pad_decimals(2)
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"mass": value})

func _on_bounce_changed(value: float):
	bounce_value.text = str(value).pad_decimals(2)
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"bounce": value})

func _on_friction_changed(value: float):
	friction_value.text = str(value).pad_decimals(2)
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"friction": value})

func _on_angular_damp_changed(value: float):
	angular_damp_value.text = str(value).pad_decimals(1)
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"angular_damp": value})

func _on_squash_threshold_changed(value: float):
	squash_threshold_value.text = str(int(value))
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"squash_threshold": value})

func _on_recovery_time_changed(value: float):
	recovery_time_value.text = str(value) + "s"
	if not is_initializing:
		settings_manager.update_toy_settings(current_toy_type, {"recovery_time": value})

func _on_sound_enabled_changed(enabled: bool):
	if not is_initializing:
		settings_manager.update_global_settings({"sound_enabled": enabled})

func _on_sound_volume_changed(value: float):
	sound_volume_value.text = str(int(value * 100)) + "%"
	if not is_initializing:
		settings_manager.update_global_settings({"sound_volume": value})

func _on_gravity_changed(value: float):
	gravity_value.text = str(int(value))
	if not is_initializing:
		settings_manager.update_global_settings({"gravity": value})

func _on_transparency_changed(value: float):
	transparency_value.text = str(int(value * 100)) + "%"
	if not is_initializing:
		settings_manager.update_global_settings({"window_transparency": value})

func _on_reset_pressed():
	# 确认对话框
	# 这里简化处理，实际应该显示确认对话框
	settings_manager.reset_to_defaults()
	load_current_settings()
	print("设置已重置为默认值")

func _on_export_pressed():
	var json_data = settings_manager.export_settings()
	
	# 复制到剪贴板
	DisplayServer.clipboard_set(json_data)
	
	# 显示成功消息
	print("设置已导出到剪贴板")
	# 这里可以添加用户界面的成功提示

func _on_import_pressed():
	var clipboard_data = DisplayServer.clipboard_get()
	
	if clipboard_data and clipboard_data.length() > 0:
		var success = settings_manager.import_settings(clipboard_data)
		if success:
			load_current_settings()
			print("设置导入成功")
		else:
			print("设置导入失败")
	else:
		print("剪贴板为空")

func _on_save_pressed():
	var success = settings_manager.save_settings()
	if success:
		print("设置已保存")
		settings_applied.emit()
	else:
		print("保存设置失败")

# 公共方法
func show_panel():
	show()
	load_current_settings()

func hide_panel():
	hide()

func toggle_panel():
	if visible:
		hide_panel()
	else:
		show_panel()