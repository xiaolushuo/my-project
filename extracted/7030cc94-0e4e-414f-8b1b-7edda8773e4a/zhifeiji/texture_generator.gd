extends Node

# 生成和优化 PNG 图像资源
# 图片优化策略：
# 1. 标准尺寸：64x64像素
# 2. 文件格式：PNG（支持透明背景）
# 3. 目标大小：50KB以下
# 4. 质量标准：保持清晰度同时优化性能

const TARGET_SIZE = 64
const MAX_FILE_SIZE_KB = 50

func _ready():
	create_toy_textures()
	print("\n=== 图片优化策略指南 ===")
	print_optimization_guide()

func create_toy_textures():
	var assets_path = "res://assets/"
	
	# 确保资源目录存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets"):
		dir.make_dir("assets")
	
	print("开始生成玩具纹理...")
	
	# 创建各种玩具的简单纹理
	create_paper_plane_texture()
	create_basketball_texture()
	create_football_texture()
	create_shuttlecock_texture()
	create_stress_ball_texture()
	create_stress_ball_squashed_texture()
	
	print("纹理生成完成！")

func create_paper_plane_texture():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制纸飞机形状（简单三角形）
	for y in range(20, 44):
		for x in range(10, 54):
			var center_x = 32
			var center_y = 32
			var dx = abs(x - center_x)
			var dy = abs(y - center_y)
			
			if dx + dy * 2 < 20:
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/paper_plane.png")
	print("纸飞机纹理已创建")

func create_basketball_texture():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	var radius = 28
	
	for y in range(64):
		for x in range(64):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var color = Color.ORANGE
				# 添加一些纹理线条
				if abs(x - 32) < 2 or abs(y - 32) < 2:
					color = Color.DARK_ORANGE
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/basketball.png")
	print("篮球纹理已创建")

func create_football_texture():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	var radius = 28
	
	for y in range(64):
		for x in range(64):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var color = Color.SADDLE_BROWN
				# 添加足球图案
				var angle = atan2(y - 32, x - 32)
				if sin(angle * 5) > 0.5:
					color = Color.WHITE
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/football.png")
	print("足球纹理已创建")

func create_shuttlecock_texture():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 羽毛球头部（圆形）
	var center = Vector2(32, 45)
	for y in range(35, 55):
		for x in range(22, 42):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= 10:
				image.set_pixel(x, y, Color.WHITE)
	
	# 羽毛部分（锥形）
	for y in range(10, 35):
		var width = (35 - y) * 0.6
		for x in range(32 - int(width), 32 + int(width)):
			if x >= 0 and x < 64:
				image.set_pixel(x, y, Color.LIGHT_GRAY)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/shuttlecock.png")
	print("羽毛球纹理已创建")

func create_stress_ball_texture():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(32, 32)
	var radius = 28
	
	for y in range(64):
		for x in range(64):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var color = Color.RED
				# 添加一些高光效果
				var highlight_distance = Vector2(x, y).distance_to(Vector2(25, 25))
				if highlight_distance < 8:
					color = color.lightened(0.3)
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/stress_ball.png")
	print("发泄球纹理已创建")

func create_stress_ball_squashed_texture():
	var image = Image.create(96, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(48, 16)
	var width = 40
	var height = 12
	
	for y in range(32):
		for x in range(96):
			var dx = (x - center.x) / float(width)
			var dy = (y - center.y) / float(height)
			
			if dx * dx + dy * dy <= 1.0:
				var color = Color.DARK_RED
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	ResourceSaver.save(texture, "res://assets/stress_ball_squashed.png")
	print("发泄球压扁纹理已创建")

# 打印优化策略指南
func print_optimization_guide():
	print("桌面物理玩具项目 - 图片优化策略")
	print("1. 标准规格:")
	print("   - 尺寸: 64x64 像素")
	print("   - 格式: PNG (支持透明背景)")
	print("   - 目标文件大小: 50KB 以下")
	print("   - 颜色模式: RGBA (支持透明度)")
	print("")
	print("2. 优化流程:")
	print("   - 使用高质量重采样算法调整尺寸")
	print("   - 启用PNG优化压缩")
	print("   - 保持透明度支持")
	print("   - 验证文件大小是否符合要求")
	print("")
	print("3. 质量标准:")
	print("   - 保持足够的视觉清晰度")
	print("   - 确保物理形状识别度")
	print("   - 适配32像素碰撞半径的显示需求")
	print("   - 在不同分辨率下的兼容性")
	print("")
	print("4. 应用场景:")
	print("   - 适用于所有玩具纹理")
	print("   - 兼容项目的物理系统")
	print("   - 支持透明窗口显示")
	print("   - 优化桌面应用性能")