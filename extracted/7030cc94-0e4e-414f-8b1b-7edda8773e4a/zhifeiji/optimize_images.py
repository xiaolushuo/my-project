from PIL import Image
import os

def optimize_basketball_image():
    """
    优化篮球图片策略：
    1. 调整尺寸到64x64像素（符合项目标准）
    2. 优化压缩质量以减小文件大小
    3. 保持PNG格式以支持透明背景
    4. 目标文件大小：50KB以下
    """
    
    input_path = r"e:\vscode\zhifeiji\assets\篮球.png"
    output_path = r"e:\vscode\zhifeiji\assets\basketball.png"
    
    if not os.path.exists(input_path):
        print(f"错误：找不到源文件 {input_path}")
        return
    
    try:
        # 打开原始图片
        with Image.open(input_path) as img:
            print(f"原始图片信息:")
            print(f"  尺寸: {img.width}x{img.height}")
            print(f"  模式: {img.mode}")
            print(f"  文件大小: {os.path.getsize(input_path) / 1024:.1f} KB")
            
            # 转换为RGBA模式（支持透明度）
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # 调整尺寸到64x64像素，使用高质量重采样
            optimized_img = img.resize((64, 64), Image.Resampling.LANCZOS)
            
            # 保存优化后的图片
            optimized_img.save(output_path, 'PNG', optimize=True)
            
            print(f"\n优化完成!")
            print(f"优化后图片信息:")
            print(f"  尺寸: {optimized_img.width}x{optimized_img.height}")
            print(f"  文件大小: {os.path.getsize(output_path) / 1024:.1f} KB")
            print(f"  文件路径: {output_path}")
            
            # 计算压缩比
            original_size = os.path.getsize(input_path)
            optimized_size = os.path.getsize(output_path)
            compression_ratio = (1 - optimized_size / original_size) * 100
            
            print(f"  压缩比: {compression_ratio:.1f}%")
            
    except Exception as e:
        print(f"优化过程中出错: {e}")

def create_optimization_guide():
    """
    创建图片优化策略指南
    """
    guide = """
# 桌面物理玩具项目 - 图片优化策略指南

## 1. 标准规格
- **尺寸**: 64x64 像素
- **格式**: PNG (支持透明背景)
- **目标文件大小**: 50KB 以下
- **颜色模式**: RGBA (支持透明度)

## 2. 优化流程
1. 使用高质量重采样算法 (LANCZOS) 调整尺寸
2. 启用PNG优化压缩
3. 保持透明度支持
4. 验证文件大小是否符合要求

## 3. 质量标准
- 保持足够的视觉清晰度
- 确保物理形状识别度
- 适合32像素碰撞半径的显示需求
- 在不同分辨率下的兼容性

## 4. 应用场景
- 适用于所有玩具纹理
- 兼容项目的物理系统
- 支持透明窗口显示
- 优化桌面应用性能

## 5. 技术要求
- 与Godot 4.3兼容
- 支持RigidBody2D的纹理需求
- 适配项目的碰撞检测系统
- 保持低内存占用
"""
    
    guide_path = r"e:\vscode\zhifeiji\IMAGE_OPTIMIZATION_GUIDE.md"
    with open(guide_path, 'w', encoding='utf-8') as f:
        f.write(guide)
    
    print(f"优化策略指南已创建: {guide_path}")

if __name__ == "__main__":
    print("=== 桌面物理玩具项目 - 图片优化工具 ===\n")
    
    # 优化篮球图片
    optimize_basketball_image()
    
    # 创建优化指南
    create_optimization_guide()
    
    print("\n=== 优化完成 ===")