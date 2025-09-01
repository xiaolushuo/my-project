extends Node2D

const SCREEN_PADDING = 50
var screen_size: Vector2
var walls: Array[StaticBody2D] = []
var toys: Array[RigidBody2D] = []
var mouse_handler: Node2D
var settings_manager: Node
var sound_manager: Node
var particle_manager: Node
var settings_panel: Control

# 玩具预设数据
var toy_data = {
        "paper_plane": {
                "mass": 0.1,
                "bounce": 0.6,
                "friction": 0.3,
                "angular_damp": 2.0,
                "texture": "res://assets/paper_plane.png"
        },
        "basketball": {
                "mass": 0.6,
                "bounce": 0.8,
                "friction": 0.7,
                "angular_damp": 1.0,
                "texture": "res://assets/basketball.png"
        },
        "football": {
                "mass": 0.4,
                "bounce": 0.7,
                "friction": 0.6,
                "angular_damp": 1.2,
                "texture": "res://assets/football.png"
        },
        "shuttlecock": {
                "mass": 0.05,
                "bounce": 0.3,
                "friction": 0.9,
                "angular_damp": 5.0,
                "texture": "res://assets/shuttlecock.png"
        },
        "stress_ball": {
                "mass": 0.3,
                "bounce": 0.9,
                "friction": 0.5,
                "angular_damp": 3.0,
                "texture": "res://assets/stress_ball.png",
                "squash_texture": "res://assets/stress_ball_squashed.png"
        }
}

func _ready():
        # 初始化管理器
        initialize_managers()
        
        # 创建鼠标处理器
        mouse_handler = preload("res://mouse_handler.gd").new()
        add_child(mouse_handler)
        
        setup_transparent_window()
        setup_screen_walls()
        create_toys()
        
        # 连接鼠标事件
        mouse_handler.toy_clicked.connect(_on_toy_clicked)
        mouse_handler.toy_released.connect(_on_toy_released)
        
        # 连接设置管理器信号
        if settings_manager:
                settings_manager.settings_changed.connect(_on_settings_changed)
                settings_manager.toy_settings_changed.connect(_on_toy_settings_changed)
        
        # 设置输入处理
        set_process_input(true)

func initialize_managers():
        # 创建设置管理器
        settings_manager = preload("res://settings_manager.gd").new()
        add_child(settings_manager)
        
        # 创建音效管理器
        sound_manager = preload("res://sound_manager.gd").new()
        add_child(sound_manager)
        
        # 创建粒子效果管理器
        particle_manager = preload("res://particle_manager.gd").new()
        add_child(particle_manager)
        
        # 创建设置面板
        settings_panel = preload("res://settings_panel.tscn").instantiate()
        add_child(settings_panel)
        settings_panel.hide()
        
        # 将设置管理器添加到自动加载
        if not has_node("/root/SettingsManager"):
                add_child(settings_manager.duplicate())
                get_node("/root/SettingsManager").name = "SettingsManager"
        
func setup_transparent_window():
        # 获取屏幕尺寸
        screen_size = DisplayServer.screen_get_size()
        
        # 设置窗口属性
        var window = get_window()
        window.set_flag(Window.FLAG_BORDERLESS, true)
        window.set_flag(Window.FLAG_ALWAYS_ON_TOP, true)
        window.set_flag(Window.FLAG_TRANSPARENT, true)
        
        # 设置窗口尺寸为全屏
        window.size = screen_size
        window.position = Vector2.ZERO
        
        # 启用鼠标穿透（仅在空白区域）
        # 这将允许鼠标在非物理对象区域穿透
        RenderingServer.viewport_set_transparent_background(window.get_viewport_rid(), true)
        
        # 调整相机到屏幕中心
        var camera = $Camera2D
        camera.global_position = screen_size * 0.5
        camera.zoom = Vector2.ONE

func setup_screen_walls():
        var walls_container = $PhysicsContainer/Walls
        
        # 清除现有墙体
        for child in walls_container.get_children():
                child.queue_free()
        walls.clear()
        
        # 创建四面墙
        var wall_thickness = 50
        var wall_positions = [
                Vector2(screen_size.x * 0.5, -wall_thickness * 0.5),  # 顶部
                Vector2(screen_size.x * 0.5, screen_size.y + wall_thickness * 0.5),  # 底部
                Vector2(-wall_thickness * 0.5, screen_size.y * 0.5),  # 左侧
                Vector2(screen_size.x + wall_thickness * 0.5, screen_size.y * 0.5)   # 右侧
        ]
        
        var wall_sizes = [
                Vector2(screen_size.x + wall_thickness * 2, wall_thickness),  # 顶部
                Vector2(screen_size.x + wall_thickness * 2, wall_thickness),  # 底部
                Vector2(wall_thickness, screen_size.y + wall_thickness * 2),  # 左侧
                Vector2(wall_thickness, screen_size.y + wall_thickness * 2)   # 右侧
        ]
        
        for i in range(4):
                var wall = StaticBody2D.new()
                var collision_shape = CollisionShape2D.new()
                var rect_shape = RectangleShape2D.new()
                
                rect_shape.size = wall_sizes[i]
                collision_shape.shape = rect_shape
                
                wall.add_child(collision_shape)
                wall.global_position = wall_positions[i]
                
                walls_container.add_child(wall)
                walls.append(wall)

func create_toys():
        var toys_container = $PhysicsContainer/Toys
        var spawn_positions = [
                Vector2(300, 300),
                Vector2(500, 300),
                Vector2(700, 300),
                Vector2(900, 300),
                Vector2(1100, 300)
        ]
        
        var toy_names = ["paper_plane", "basketball", "football", "shuttlecock", "stress_ball"]
        
        for i in range(toy_names.size()):
                var toy_name = toy_names[i]
                var toy = create_toy(toy_name)
                toy.global_position = spawn_positions[i]
                toys_container.add_child(toy)
                toys.append(toy)

func create_toy(toy_name: String) -> RigidBody2D:
        # 检查玩具是否启用
        if settings_manager and not settings_manager.is_toy_enabled(toy_name):
                return null
        
        var data = toy_data[toy_name]
        
        # 如果有设置管理器，使用设置中的参数
        if settings_manager:
                var settings = settings_manager.get_toy_settings(toy_name)
                data = data.duplicate()
                for key in settings:
                        if key in data:
                                data[key] = settings[key]
        
        var toy = RigidBody2D.new()
        
        # 设置物理属性
        toy.mass = data.mass
        toy.physics_material_override = PhysicsMaterial.new()
        toy.physics_material_override.bounce = data.bounce
        toy.physics_material_override.friction = data.friction
        toy.angular_damp = data.angular_damp
        
        # 创建碰撞形状
        var collision_shape = CollisionShape2D.new()
        var circle_shape = CircleShape2D.new()
        circle_shape.radius = 32
        collision_shape.shape = circle_shape
        toy.add_child(collision_shape)
        
        # 创建精灵
        var sprite = Sprite2D.new()
        if ResourceLoader.exists(data.texture):
                sprite.texture = load(data.texture)
        else:
                # 创建临时纹理
                var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
                var color = Color.BLUE
                match toy_name:
                        "paper_plane": color = Color.WHITE
                        "basketball": color = Color.ORANGE
                        "football": color = Color.BROWN
                        "shuttlecock": color = Color.WHITE
                        "stress_ball": color = Color.RED
                image.fill(color)
                var texture = ImageTexture.new()
                texture.set_image(image)
                sprite.texture = texture
        
        toy.add_child(sprite)
        
        # 添加特殊属性
        toy.set_meta("toy_type", toy_name)
        if toy_name == "stress_ball":
                toy.set_meta("is_squashed", false)
                toy.set_meta("squash_timer", 0.0)
                if settings_manager:
                        toy.set_meta("squash_threshold", settings_manager.get_toy_settings(toy_name).get("squash_threshold", 400.0))
                        toy.set_meta("recovery_time", settings_manager.get_toy_settings(toy_name).get("recovery_time", 2.5))
                else:
                        toy.set_meta("squash_threshold", 400.0)
                        toy.set_meta("recovery_time", 2.5)
        
        # 连接输入事件
        toy.input_event.connect(_on_toy_input_event.bind(toy))
        
        # 连接碰撞信号
        toy.body_entered.connect(_on_toy_collision.bind(toy))
        
        return toy

func _on_toy_input_event(toy: RigidBody2D, _viewport: Node, event: InputEvent, _shape_idx: int):
        # 鼠标事件由 mouse_handler 处理
        pass

func _on_toy_clicked(toy: RigidBody2D):
        var toy_type = toy.get_meta("toy_type", "")
        print("点击了玩具: ", toy_type)
        
        # 播放音效和粒子效果
        if sound_manager:
                sound_manager.play_toy_sound(toy_type, "catch")
        if particle_manager:
                particle_manager.play_toy_effect(toy_type, "catch", {"position": toy.global_position})

func _on_toy_released(toy: RigidBody2D, velocity: Vector2):
        var toy_type = toy.get_meta("toy_type", "")
        print("释放了玩具: ", toy_type, " 速度: ", velocity)
        
        # 播放音效和粒子效果
        if sound_manager:
                sound_manager.play_toy_sound(toy_type, "throw", {"throw_force": velocity.length() / 1000.0})
        if particle_manager:
                particle_manager.play_toy_effect(toy_type, "throw", {
                        "position": toy.global_position,
                        "velocity": velocity
                })

func _process(delta):
        # 处理发泄球形变
        for toy in toys:
                if toy.get_meta("toy_type") == "stress_ball":
                        handle_stress_ball(toy, delta)

func handle_stress_ball(toy: RigidBody2D, delta: float):
        var is_squashed = toy.get_meta("is_squashed", false)
        var squash_timer = toy.get_meta("squash_timer", 0.0)
        var recovery_time = toy.get_meta("recovery_time", 2.5)
        
        if is_squashed:
                squash_timer += delta
                toy.set_meta("squash_timer", squash_timer)
                
                if squash_timer >= recovery_time:
                        # 恢复球形
                        toy.set_meta("is_squashed", false)
                        toy.set_meta("squash_timer", 0.0)
                        
                        var sprite = toy.get_child(1) as Sprite2D
                        if ResourceLoader.exists(toy_data.stress_ball.texture):
                                sprite.texture = load(toy_data.stress_ball.texture)
                        
                        # 恢复碰撞形状
                        var collision_shape = toy.get_child(0) as CollisionShape2D
                        var circle_shape = CircleShape2D.new()
                        circle_shape.radius = 32
                        collision_shape.shape = circle_shape
                        
                        # 播放恢复音效和粒子效果
                        if sound_manager:
                                sound_manager.play_toy_sound("stress_ball", "recovery")
                        if particle_manager:
                                particle_manager.play_toy_effect("stress_ball", "recovery", {"position": toy.global_position})

func _on_toy_collision(body: Node, toy: RigidBody2D):
        var toy_type = toy.get_meta("toy_type", "")
        
        # 检查发泄球高速碰撞
        if toy_type == "stress_ball":
                var velocity = toy.linear_velocity.length()
                var squash_threshold = toy.get_meta("squash_threshold", 400.0)
                if velocity > squash_threshold and not toy.get_meta("is_squashed", false):
                        squash_stress_ball(toy)
        
        # 播放碰撞音效和粒子效果
        var impact_force = min(velocity / 500.0, 3.0)
        if sound_manager:
                sound_manager.play_toy_sound(toy_type, "collision", {"impact_force": impact_force})
        if particle_manager:
                particle_manager.play_toy_effect(toy_type, "collision", {
                        "position": toy.global_position,
                        "impact_force": impact_force
                })

func squash_stress_ball(toy: RigidBody2D):
        toy.set_meta("is_squashed", true)
        toy.set_meta("squash_timer", 0.0)
        
        # 更换为扁平纹理
        var sprite = toy.get_child(1) as Sprite2D
        if ResourceLoader.exists(toy_data.stress_ball.squash_texture):
                sprite.texture = load(toy_data.stress_ball.squash_texture)
        
        # 修改碰撞形状为椭圆
        var collision_shape = toy.get_child(0) as CollisionShape2D
        var capsule_shape = CapsuleShape2D.new()
        capsule_shape.radius = 20
        capsule_shape.height = 10
        collision_shape.shape = capsule_shape
        
        # 播放形变音效和粒子效果
        if sound_manager:
                sound_manager.play_toy_sound("stress_ball", "squash")
        if particle_manager:
                particle_manager.play_toy_effect("stress_ball", "squash", {"position": toy.global_position})

# 设置变更回调
func _on_settings_changed():
        var global_settings = settings_manager.get_global_settings()
        
        # 应用音效设置
        if sound_manager:
                sound_manager.set_sound_enabled(global_settings.get("sound_enabled", true))
                sound_manager.set_master_volume(global_settings.get("sound_volume", 0.8))
        
        # 应用粒子效果设置
        if particle_manager:
                particle_manager.set_effects_enabled(global_settings.get("particle_effects", true))
        
        # 应用重力设置
        ProjectSettings.set_setting("physics/2d/default_gravity", global_settings.get("gravity", 980.0))

# 玩具设置变更回调
func _on_toy_settings_changed(toy_type: String):
        # 更新现有玩具的物理属性
        for toy in toys:
                if toy.get_meta("toy_type") == toy_type:
                        var settings = settings_manager.get_toy_settings(toy_type)
                        toy.mass = settings.get("mass", 0.1)
                        toy.physics_material_override.bounce = settings.get("bounce", 0.5)
                        toy.physics_material_override.friction = settings.get("friction", 0.5)
                        toy.angular_damp = settings.get("angular_damp", 1.0)
                        
                        # 更新发泄球特殊设置
                        if toy_type == "stress_ball":
                                toy.set_meta("squash_threshold", settings.get("squash_threshold", 400.0))
                                toy.set_meta("recovery_time", settings.get("recovery_time", 2.5))

func _input(event):
        # ESC键退出
        if event is InputEventKey and event.pressed:
                if event.keycode == KEY_ESCAPE:
                        get_tree().quit()
                
                # S键打开设置面板
                if event.keycode == KEY_S:
                        if settings_panel:
                                settings_panel.toggle_panel()
                
                # R键重置设置
                if event.keycode == KEY_R and event.ctrl_pressed:
                        if settings_manager:
                                settings_manager.reset_to_defaults()