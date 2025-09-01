extends Node

# 教程管理器 - 提供用户引导和帮助系统
signal tutorial_completed(tutorial_id: String)
signal help_shown(help_id: String)
signal help_hidden(help_id: String)

enum TutorialStep {
	INTRO,
	BASIC_CONTROLS,
	TOY_TYPES,
	SETTINGS_MENU,
	ADVANCED_FEATURES,
	COMPLETED
}

# 教程状态
var tutorial_active = false
var current_tutorial_step = TutorialStep.INTRO
var tutorial_progress = {}

# 帮助面板状态
var help_panels = {}
var help_visible = false

# 教程数据
var tutorials = {
	"quick_start": {
		"title": "快速入门",
		"description": "学习桌面物理玩具的基本操作",
		"steps": [
			{
				"id": "intro",
				"title": "欢迎",
				"content": "欢迎使用桌面物理玩具！这是一个透明无边框的桌面应用，您可以在桌面上与各种2D玩具互动。",
				"highlight": null,
				"action": "点击继续"
			},
			{
				"id": "basic_controls",
				"title": "基本控制",
				"content": "点击并拖拽玩具来移动它们。快速拖拽后释放可以甩出玩具。试试拖拽一个玩具！",
				"highlight": "toys",
				"action": "拖拽一个玩具"
			},
			{
				"id": "toy_types",
				"title": "玩具类型",
				"content": "我们有5种不同的玩具：纸飞机（轻）、篮球（弹跳高）、足球（中等）、羽毛球（轻）、发泄球（可形变）。",
				"highlight": "toy_info",
				"action": "观察不同玩具"
			},
			{
				"id": "settings_menu",
				"title": "设置菜单",
				"content": "按 S 键打开设置菜单，您可以调整玩具属性、音效、粒子效果等。",
				"highlight": "settings_button",
				"action": "按 S 键"
			},
			{
				"id": "special_effects",
				"title": "特殊效果",
				"content": "发泄球在高速碰撞时会形变！试试快速扔出发泄球看看效果。",
				"highlight": "stress_ball",
				"action": "测试发泄球形变"
			},
			{
				"id": "completed",
				"title": "完成",
				"content": "恭喜！您已经掌握了基本操作。按 ESC 键退出，享受您的桌面物理玩具吧！",
				"highlight": null,
				"action": "开始游戏"
			}
		]
	}
}

# 帮助主题
var help_topics = {
	"controls": {
		"title": "操作说明",
		"content": """
## 基本操作
- **鼠标左键拖拽**: 移动玩具
- **快速甩出**: 快速拖拽后释放产生抛出效果
- **ESC键**: 退出应用
- **S键**: 打开/关闭设置面板
- **Ctrl+R**: 重置所有设置为默认值

## 高级技巧
- 不同玩具有不同的物理特性
- 发泄球在高速撞击时会形变
- 可以调整重力和空气阻力
- 支持音效和粒子效果开关
		"""
	},
	"toys": {
		"title": "玩具介绍",
		"content": """
## 玩具类型

### 📄 纸飞机
- **特性**: 轻盈飘逸，低弹性
- **质量**: 0.1
- **弹性**: 0.6
- **适合**: 缓慢、优雅的运动

### 🏀 篮球
- **特性**: 高弹性，适中重量
- **质量**: 0.6
- **弹性**: 0.8
- **适合**: 高弹跳运动

### ⚽ 足球
- **特性**: 中等弹性和重量
- **质量**: 0.4
- **弹性**: 0.7
- **适合**: 平衡的运动

### 🏸 羽毛球
- **特性**: 极轻，高阻尼
- **质量**: 0.05
- **弹性**: 0.3
- **适合**: 轻柔的飘动

### 🔴 发泄球
- **特性**: 高弹性，特殊形变效果
- **质量**: 0.3
- **弹性**: 0.9
- **特殊**: 高速碰撞时会"摊成饼"
		"""
	},
	"settings": {
		"title": "设置说明",
		"content": """
## 设置面板

### 玩具设置
- **质量**: 影响玩具的重量和惯性
- **弹性**: 决定弹跳高度
- **摩擦力**: 影响滑动和停止
- **角阻尼**: 控制旋转减速
- **启用/禁用**: 可以隐藏特定玩具

### 发泄球特殊设置
- **形变阈值**: 触发形变的最低速度
- **恢复时间**: 形变后恢复原状的时间

### 全局设置
- **音效**: 开启/关闭音效
- **音量**: 调整音效音量
- **粒子效果**: 开启/关闭视觉效果
- **重力**: 调整重力强度
- **透明度**: 调整窗口透明度

### 导入/导出
- 可以导出当前设置为JSON格式
- 支持导入之前保存的设置
- 方便在不同设备间同步配置
		"""
	},
	"tips": {
		"title": "使用技巧",
		"content": """
## 实用技巧

### 性能优化
- 关闭粒子效果可以提升性能
- 降低音量或关闭音效节省资源
- 禁用不需要的玩具减少计算量

### 物理效果
- 调整重力可以模拟不同环境
- 增加弹性让玩具更有活力
- 减少摩擦力让玩具滑动更远

### 发泄球技巧
- 快速扔向墙壁或地面看形变效果
- 调整形变阈值控制敏感度
- 修改恢复时间改变游戏节奏

### 多显示器支持
- 应用会自动适应屏幕尺寸
- 在多显示器环境中效果最佳
- 透明窗口效果需要系统支持

### 故障排除
- 如果玩具不动，检查是否被卡住
- 音效问题请检查系统音量设置
- 粒子效果卡顿请降低效果质量
		"""
	}
}

func _ready():
	# 初始化教程进度
	load_tutorial_progress()
	
	# 检查是否是首次运行
	if is_first_run():
		show_tutorial("quick_start")

func _enter_tree():
	# 确保在场景树中时管理器已初始化
	if tutorial_progress.is_empty():
		load_tutorial_progress()

# 检查是否首次运行
func is_first_run() -> bool:
	var config_path = "user://tutorial_config.cfg"
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err != OK:
		# 配置文件不存在，说明是首次运行
		mark_first_run_completed()
		return true
	
	return !config.get_value("general", "first_run_completed", false)

# 标记首次运行已完成
func mark_first_run_completed():
	var config_path = "user://tutorial_config.cfg"
	var config = ConfigFile.new()
	
	config.set_value("general", "first_run_completed", true)
	config.save(config_path)

# 加载教程进度
func load_tutorial_progress():
	var config_path = "user://tutorial_progress.cfg"
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		for section in config.get_sections():
			if section != "general":
				tutorial_progress[section] = {}
				for key in config.get_section_keys(section):
					tutorial_progress[section][key] = config.get_value(section, key)

# 保存教程进度
func save_tutorial_progress():
	var config_path = "user://tutorial_progress.cfg"
	var config = ConfigFile.new()
	
	for tutorial_id in tutorial_progress:
		for key in tutorial_progress[tutorial_id]:
			config.set_value(tutorial_id, key, tutorial_progress[tutorial_id][key])
	
	config.save(config_path)

# 显示教程
func show_tutorial(tutorial_id: String):
	if tutorial_id not in tutorials:
		print("教程不存在: ", tutorial_id)
		return
	
	tutorial_active = true
	current_tutorial_step = TutorialStep.INTRO
	
	# 初始化教程进度
	if tutorial_id not in tutorial_progress:
		tutorial_progress[tutorial_id] = {
			"current_step": 0,
			"completed": false,
			"started_time": Time.get_datetime_string_from_system()
		}
	
	# 显示教程界面
	show_tutorial_step(tutorial_id, 0)
	
	print("开始教程: ", tutorial_id)

# 显示特定教程步骤
func show_tutorial_step(tutorial_id: String, step_index: int):
	var tutorial = tutorials[tutorial_id]
	
	if step_index >= tutorial.steps.size():
		# 教程完成
		complete_tutorial(tutorial_id)
		return
	
	var step = tutorial.steps[step_index]
	
	# 更新进度
	tutorial_progress[tutorial_id]["current_step"] = step_index
	save_tutorial_progress()
	
	# 显示教程界面
	show_tutorial_interface(tutorial_id, step)
	
	# 高亮相关元素
	if step.highlight:
		highlight_element(step.highlight)

# 显示教程界面
func show_tutorial_interface(tutorial_id: String, step: Dictionary):
	# 这里应该创建一个教程界面
	# 由于是代码示例，我们简化处理
	print("教程步骤: ", step.title)
	print("内容: ", step.content)
	print("操作: ", step.action)
	
	# 在实际项目中，这里会创建UI界面
	# 例如：create_tutorial_panel(tutorial_id, step)

# 高亮元素
func highlight_element(element_id: String):
	match element_id:
		"toys":
			print("高亮玩具区域")
		"toy_info":
			print("高亮玩具信息")
		"settings_button":
			print("高亮设置按钮")
		"stress_ball":
			print("高亮发泄球")
		_:
			print("高亮元素: ", element_id)

# 完成教程
func complete_tutorial(tutorial_id: String):
	tutorial_progress[tutorial_id]["completed"] = true
	tutorial_progress[tutorial_id]["completed_time"] = Time.get_datetime_string_from_system()
	save_tutorial_progress()
	
	tutorial_active = false
	tutorial_completed.emit(tutorial_id)
	
	print("教程完成: ", tutorial_id)

# 跳过教程
func skip_tutorial(tutorial_id: String):
	tutorial_active = false
	print("跳过教程: ", tutorial_id)

# 显示帮助
func show_help(help_id: String):
	if help_id not in help_topics:
		print("帮助主题不存在: ", help_id)
		return
	
	var topic = help_topics[help_id]
	help_panels[help_id] = true
	help_visible = true
	
	help_shown.emit(help_id)
	
	# 显示帮助界面
	show_help_interface(help_id, topic)
	
	print("显示帮助: ", help_id, " - ", topic.title)

# 显示帮助界面
func show_help_interface(help_id: String, topic: Dictionary):
	# 这里应该创建一个帮助界面
	print("帮助主题: ", topic.title)
	print("内容: ", topic.content)
	
	# 在实际项目中，这里会创建UI界面
	# 例如：create_help_panel(help_id, topic)

# 隐藏帮助
func hide_help(help_id: String):
	if help_id in help_panels:
		help_panels[help_id] = false
	
	# 检查是否还有显示的帮助面板
	help_visible = false
	for panel_id in help_panels:
		if help_panels[panel_id]:
			help_visible = true
			break
	
	help_hidden.emit(help_id)
	
	print("隐藏帮助: ", help_id)

# 隐藏所有帮助
func hide_all_help():
	for help_id in help_panels.keys():
		hide_help(help_id)

# 获取可用的教程列表
func get_available_tutorials() -> Array:
	return tutorials.keys()

# 获取可用的帮助主题列表
func get_available_help_topics() -> Array:
	return help_topics.keys()

# 检查教程是否已完成
func is_tutorial_completed(tutorial_id: String) -> bool:
	if tutorial_id in tutorial_progress:
		return tutorial_progress[tutorial_id].get("completed", false)
	return false

# 获取教程进度
func get_tutorial_progress(tutorial_id: String) -> Dictionary:
	if tutorial_id in tutorial_progress:
		return tutorial_progress[tutorial_id]
	return {}

# 重置教程进度
func reset_tutorial_progress(tutorial_id: String = ""):
	if tutorial_id == "":
		# 重置所有教程
		tutorial_progress.clear()
	else:
		# 重置特定教程
		if tutorial_id in tutorial_progress:
			tutorial_progress[tutorial_id] = {
				"current_step": 0,
				"completed": false,
				"started_time": Time.get_datetime_string_from_system()
			}
	
	save_tutorial_progress()

# 获取当前教程状态
func get_current_tutorial_state() -> Dictionary:
	return {
		"active": tutorial_active,
		"current_step": current_tutorial_step,
		"tutorial_id": get_current_tutorial_id()
	}

# 获取当前教程ID
func get_current_tutorial_id() -> String:
	for tutorial_id in tutorial_progress:
		if not tutorial_progress[tutorial_id].get("completed", false):
			return tutorial_id
	return ""

# 创建快速提示
func show_quick_tip(tip_id: String):
	var tips = {
		"welcome": "欢迎！按 S 键打开设置",
		"drag": "拖拽玩具来移动它们",
		"throw": "快速拖拽后释放来甩出玩具",
		"settings": "按 S 键调整游戏设置",
		"stress_ball": "发泄球在高速撞击时会形变！",
		"escape": "按 ESC 键退出游戏"
	}
	
	if tip_id in tips:
		print("快速提示: ", tips[tip_id])
		# 在实际项目中，这里会显示一个提示框
		# show_tooltip(tips[tip_id])

# 显示控制提示
func show_controls_help():
	var help_text = """
快捷键：
S - 设置面板
ESC - 退出
Ctrl+R - 重置设置

鼠标操作：
左键拖拽 - 移动玩具
快速释放 - 甩出玩具
	"""
	print(help_text)
	# 在实际项目中，这里会显示一个帮助框

# 清理资源
func cleanup():
	hide_all_help()
	tutorial_active = false
	tutorial_progress.clear()
	help_panels.clear()