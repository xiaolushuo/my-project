extends Node

# 图片优化工具 - 为桌面物理玩具项目优化图片资源
# 
# 优化策略：
# 1. 标准尺寸：64x64像素（符合项目设计规范）
# 2. 文件大小：尽量控制在50KB以下
# 3. 格式：PNG（支持透明背景）
# 4. 质量：保持足够清晰度的同时优化文件大小

const TARGET_SIZE = 64
const MAX_FILE_SIZE_KB = 50

func _ready():
	print("图片优化工具已启动")
	optimize_basketball_image()

func optimize_basketball_image():
	var source_path = "res://assets/篮球.png"
	var output_path = "res://assets/basketball.png"
	
	print("开始优化篮球图片...")
	
	if not ResourceLoader.exists(source_path):
		print("错误：找不到源文件 ", source_path)
		return
	
	# 加载原始图片
	var original_texture = load(source_path) as Texture2D
	if not original_texture:
		print("错误：无法加载图片")
		return
	
	var original_image = original_texture.get_image()
	print("原始图片尺寸: ", original_image.get_width(), "x", original_image.get_height())
	
	# 优化图片
	var optimized_image = optimize_image(original_image)
	
	# 保存优化后的图片
	save_optimized_image(optimized_image, output_path)
	
	print("篮球图片优化完成！")
	print("原始文件: 篮球.png")
	print("优化文件: basketball.png")

func optimize_image(source_image: Image) -> Image:
	# 1. 调整尺寸到64x64
	var optimized_image = Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)
	
	# 复制并缩放图片
	source_image.resize(TARGET_SIZE, TARGET_SIZE, Image.INTERPOLATE_LANCZOS)
	optimized_image.copy_from(source_image)
	
	# 2. 确保背景透明（如果需要）
	# process_transparency(optimized_image)
	
	# 3. 优化颜色深度（如果图片过大）
	# 这里可以根据需要进一步压缩
	
	return optimized_image

func process_transparency(image: Image):
	# 处理背景透明度
	# 将接近白色的像素设为透明（如果图片有白色背景）
	var threshold = 0.95
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			
			# 如果像素接近白色，设为透明
			if pixel.r > threshold and pixel.g > threshold and pixel.b > threshold:
				image.set_pixel(x, y, Color.TRANSPARENT)

func save_optimized_image(image: Image, output_path: String):
	# 保存为PNG格式
	image.save_png(output_path.replace("res://", ""))
	
	# 创建纹理资源
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# 保存为资源文件
	ResourceSaver.save(texture, output_path)
	print("图片已保存到: ", output_path)

# 批量优化所有图片的函数
func optimize_all_images():
	var assets_dir = "res://assets/"
	var dir = DirAccess.open(assets_dir)
	
	if not dir:
		print("无法打开assets目录")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.starts_with("basketball"):
			var source_path = assets_dir + file_name
			var output_path = assets_dir + file_name.get_basename() + "_optimized.png"
			
			print("优化图片: ", file_name)
			
			var texture = load(source_path) as Texture2D
			if texture:
				var image = texture.get_image()
				var optimized_image = optimize_image(image)
				save_optimized_image(optimized_image, output_path)
		
		file_name = dir.get_next()
	
	print("批量优化完成！")

# 获取图片信息的辅助函数
func get_image_info(image_path: String):
	if ResourceLoader.exists(image_path):
		var texture = load(image_path) as Texture2D
		if texture:
			var image = texture.get_image()
			print("图片信息 - ", image_path)
			print("  尺寸: ", image.get_width(), "x", image.get_height())
			print("  格式: ", image.get_format())