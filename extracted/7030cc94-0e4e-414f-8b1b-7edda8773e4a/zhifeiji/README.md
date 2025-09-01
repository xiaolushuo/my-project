# 桌面物理玩具

一个透明无边框的桌面物理玩具应用，使用 Godot 4 制作。

## 功能特性

### 🎯 5种2D玩具
- **纸飞机** - 轻盈飘逸，低弹性
- **篮球** - 高弹性，适中重量
- **足球** - 中等弹性和重量
- **羽毛球** - 极轻，高阻尼
- **发泄球** - 高弹性，具有特殊形变效果

### 🎮 物理特性
- **真实弹跳** - 每个玩具都有不同的弹性系数
- **自然旋转** - 根据抛出力度产生旋转
- **相互碰撞** - 玩具之间可以碰撞
- **边界反弹** - 碰到屏幕边缘会反弹

### ✨ 特殊效果
- **发泄球形变** - 高速撞击时会瞬间"摊成饼"
- **自动恢复** - 2.5秒后自动弹回球形
- **弹性动画** - 恢复时有弹性动画效果

### 🖱️ 交互方式
- **点击拖拽** - 鼠标左键点击并拖拽玩具
- **甩出操作** - 快速拖拽后释放可以甩出玩具
- **力度感应** - 拖拽速度影响抛出力度

### 🪟 窗口特性
- **完全透明** - 背景100%透明
- **无边框** - 无窗口边框
- **置顶显示** - 始终在其他窗口上方
- **鼠标穿透** - 空白区域允许鼠标穿透

## 开发信息

### 技术栈
- **引擎**: Godot 4.3
- **语言**: GDScript
- **图形**: 2D物理 + PNG贴图
- **平台**: Windows桌面

### 项目结构
```
桌面物理玩具/
├── main.tscn              # 主场景
├── main.gd                # 主脚本
├── toy.gd                 # 玩具脚本
├── mouse_handler.gd       # 鼠标交互处理
├── stress_ball.tscn       # 发泄球预设
├── texture_generator.gd   # 纹理生成器
├── assets/                # 资源目录
│   ├── paper_plane.png
│   ├── basketball.png
│   ├── football.png
│   ├── shuttlecock.png
│   ├── stress_ball.png
│   └── stress_ball_squashed.png
├── project.godot          # Godot项目配置
├── export_presets.cfg     # 导出配置
└── icon.svg              # 应用图标
```

### 核心系统

#### 物理系统
- 使用 `RigidBody2D` 实现真实物理
- `StaticBody2D` 创建屏幕边界墙
- 自定义 `PhysicsMaterial` 设置弹性和摩擦

#### 窗口系统
- `FLAG_BORDERLESS` - 无边框
- `FLAG_ALWAYS_ON_TOP` - 置顶
- `FLAG_TRANSPARENT` - 透明
- `viewport_set_transparent_background` - 背景透明

#### 交互系统
- 鼠标位置历史记录
- 速度计算和力度转换
- 抛出轨迹预测

## 使用方法

### 运行项目
1. 安装 Godot 4.3+
2. 打开项目文件 `project.godot`
3. 按 F5 运行项目

### 导出为 EXE
1. 在 Godot 编辑器中选择 "项目" > "导出"
2. 选择 "Windows Desktop" 预设
3. 点击 "导出项目"
4. 生成的 EXE 文件可直接运行，无需安装

### 操作说明
- **ESC键** - 退出应用
- **左键拖拽** - 移动玩具
- **快速甩出** - 快速拖拽后释放产生抛出效果
- **碰撞观察** - 观察发泄球的形变效果

## 技术细节

### 透明窗口实现
```gdscript
window.set_flag(Window.FLAG_TRANSPARENT, true)
RenderingServer.viewport_set_transparent_background(window.get_viewport_rid(), true)
```

### 发泄球形变系统
- 检测碰撞速度超过阈值
- 切换纹理和碰撞形状
- 使用 Tween 做恢复动画

### 屏幕边界生成
- 动态获取屏幕尺寸
- 创建四面不可见墙体
- 自适应不同分辨率

## 自定义扩展

### 添加新玩具
1. 在 `toy_data` 字典中添加配置
2. 创建对应的纹理资源
3. 调整物理参数

### 修改物理效果
- 调整 `mass` - 质量
- 调整 `bounce` - 弹性
- 调整 `friction` - 摩擦力
- 调整 `angular_damp` - 角阻尼

### 自定义窗口行为
- 修改 `setup_transparent_window()` 函数
- 调整窗口标志和属性

## 注意事项

- 需要 Windows 10+ 系统支持窗口透明
- 某些杀毒软件可能误报，请添加信任
- 高DPI屏幕可能需要调整缩放设置
- 建议在双显示器环境下使用以获得最佳体验

## 许可证

本项目使用 MIT 许可证，可自由使用和修改。