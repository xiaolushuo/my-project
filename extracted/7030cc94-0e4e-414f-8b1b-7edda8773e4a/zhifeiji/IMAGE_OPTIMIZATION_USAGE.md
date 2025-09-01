# 图片优化使用指南

## 概述
这个项目使用统一的图片优化策略，确保所有游戏资源都符合性能和质量标准。

## 优化规格标准
- **尺寸**: 64x64 像素
- **格式**: PNG (支持透明背景)
- **文件大小**: ≤50KB
- **颜色模式**: RGBA (支持透明度)

## 使用方法

### 1. 单个图片优化
```bash
# 使用 Python 脚本优化单个图片
python optimize_images.py

# 或批量优化工具
python batch_optimize_images.py path/to/image.png
```

### 2. 批量优化
```bash
# 优化 assets 目录下的所有图片
python batch_optimize_images.py
```

### 3. 在 Godot 中使用
1. 运行 `texture_generator.gd` 生成基础纹理
2. 运行 `image_optimizer.gd` 进行优化处理
3. 查看优化指南输出

## 文件说明

### 优化工具
- `optimize_images.py` - 基础图片优化脚本
- `batch_optimize_images.py` - 高级批量优化工具
- `image_optimizer.gd` - Godot 内置优化器
- `texture_generator.gd` - 纹理生成和优化指南

### 配置文件
- `IMAGE_OPTIMIZATION_GUIDE.md` - 详细优化策略文档
- `OPTIMIZATION_REPORT.json` - 优化统计报告

## 优化效果示例

### 篮球图片优化
- **优化前**: 1024x797, 898.1KB
- **优化后**: 64x64, 5.6KB
- **压缩比**: 99.4%
- **质量**: 保持高清晰度

## 注意事项

1. **备份原始文件**: 批量优化工具会自动备份原始文件到 `assets/backups/` 目录
2. **透明背景**: 优化过程会保持PNG透明背景支持
3. **质量控制**: 使用LANCZOS算法确保缩放质量
4. **性能优化**: 所有优化图片都针对Godot 4.3引擎优化

## 项目集成

优化后的图片会自动被项目识别和使用：
- 篮球: `assets/basketball.png` 
- 其他玩具: 按照相同标准优化

所有图片都与项目的物理系统（32像素碰撞半径）完美兼容。

## 故障排除

如果遇到问题：
1. 确保安装了 Pillow 库: `pip install Pillow`
2. 检查图片格式是否支持
3. 验证文件路径是否正确
4. 查看优化报告了解详细信息