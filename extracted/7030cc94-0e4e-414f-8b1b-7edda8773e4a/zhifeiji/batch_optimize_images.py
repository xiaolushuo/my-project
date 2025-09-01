#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
桌面物理玩具项目 - 批量图片优化工具

该脚本用于批量优化项目中的所有图片资源，确保它们符合项目标准：
- 尺寸: 64x64 像素
- 格式: PNG (支持透明背景)
- 文件大小: 50KB 以下
- 质量: 保持视觉清晰度

使用方法:
1. 将需要优化的图片放入 assets/ 目录
2. 运行此脚本
3. 优化后的图片将保存为适合项目使用的格式

作者: Qoder AI Assistant
日期: 2025-09-01
"""

import os
import sys
from PIL import Image, ImageFilter
from pathlib import Path
import json
from datetime import datetime

class ImageOptimizer:
    """图片优化器类"""
    
    def __init__(self):
        self.target_size = 64
        self.max_file_size_kb = 50
        self.assets_dir = Path("assets")
        self.backup_dir = Path("assets/backups")
        self.supported_formats = {'.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.webp'}
        
        # 创建必要的目录
        self.assets_dir.mkdir(exist_ok=True)
        self.backup_dir.mkdir(exist_ok=True)
        
        # 优化统计
        self.stats = {
            'processed': 0,
            'optimized': 0,
            'errors': 0,
            'total_size_before': 0,
            'total_size_after': 0
        }
    
    def is_supported_format(self, file_path):
        """检查文件格式是否支持"""
        return file_path.suffix.lower() in self.supported_formats
    
    def backup_original(self, file_path):
        """备份原始文件"""
        backup_path = self.backup_dir / file_path.name
        try:
            # 如果备份已存在，添加时间戳
            if backup_path.exists():
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                name_parts = file_path.stem, timestamp, file_path.suffix
                backup_path = self.backup_dir / f"{name_parts[0]}_{name_parts[1]}{name_parts[2]}"
            
            # 复制文件到备份目录
            import shutil
            shutil.copy2(file_path, backup_path)
            print(f"  ✓ 原始文件已备份到: {backup_path}")
            return True
        except Exception as e:
            print(f"  ✗ 备份失败: {e}")
            return False
    
    def optimize_single_image(self, input_path, output_path=None, backup=True):
        """优化单个图片"""
        input_path = Path(input_path)
        
        if not input_path.exists():
            print(f"错误: 文件不存在 - {input_path}")
            return False
        
        if not self.is_supported_format(input_path):
            print(f"跳过不支持的格式: {input_path}")
            return False
        
        # 设置输出路径
        if output_path is None:
            output_path = input_path
        else:
            output_path = Path(output_path)
        
        print(f"\n正在优化: {input_path.name}")
        
        try:
            # 获取原始文件信息
            original_size = input_path.stat().st_size
            self.stats['total_size_before'] += original_size
            
            # 备份原始文件（如果需要）
            if backup and input_path == output_path:
                if not self.backup_original(input_path):
                    return False
            
            # 打开并优化图片
            with Image.open(input_path) as img:
                print(f"  原始尺寸: {img.width}x{img.height}")
                print(f"  原始大小: {original_size / 1024:.1f} KB")
                print(f"  颜色模式: {img.mode}")
                
                # 转换为RGBA模式以支持透明度
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # 调整尺寸到目标大小
                optimized_img = img.resize(
                    (self.target_size, self.target_size), 
                    Image.Resampling.LANCZOS
                )
                
                # 可选: 轻微锐化处理
                optimized_img = optimized_img.filter(ImageFilter.UnsharpMask(radius=0.5, percent=150, threshold=3))
                
                # 保存优化后的图片
                optimized_img.save(output_path, 'PNG', optimize=True, compress_level=9)
                
                # 验证结果
                new_size = output_path.stat().st_size
                self.stats['total_size_after'] += new_size
                compression_ratio = (1 - new_size / original_size) * 100
                
                print(f"  ✓ 优化完成!")
                print(f"  优化尺寸: {self.target_size}x{self.target_size}")
                print(f"  优化大小: {new_size / 1024:.1f} KB")
                print(f"  压缩比: {compression_ratio:.1f}%")
                
                # 检查是否符合大小要求
                size_kb = new_size / 1024
                if size_kb <= self.max_file_size_kb:
                    print(f"  ✓ 文件大小符合要求 (≤{self.max_file_size_kb}KB)")
                else:
                    print(f"  ⚠ 文件大小超出建议值 ({size_kb:.1f}KB > {self.max_file_size_kb}KB)")
                
                self.stats['processed'] += 1
                self.stats['optimized'] += 1
                return True
                
        except Exception as e:
            print(f"  ✗ 优化失败: {e}")
            self.stats['errors'] += 1
            return False
    
    def batch_optimize(self, pattern="*"):
        """批量优化assets目录中的图片"""
        print("=== 桌面物理玩具项目 - 批量图片优化工具 ===\n")
        
        # 查找需要优化的图片
        image_files = []
        for ext in self.supported_formats:
            image_files.extend(self.assets_dir.glob(f"{pattern}{ext}"))
        
        if not image_files:
            print("未找到需要优化的图片文件")
            return
        
        print(f"找到 {len(image_files)} 个图片文件待优化:")
        for img_file in image_files:
            size_kb = img_file.stat().st_size / 1024
            print(f"  - {img_file.name} ({size_kb:.1f} KB)")
        
        print("\n开始批量优化...")
        
        # 逐个优化
        for img_file in image_files:
            self.optimize_single_image(img_file)
        
        # 输出统计信息
        self.print_statistics()
    
    def print_statistics(self):
        """打印优化统计信息"""
        print("\n" + "="*50)
        print("优化统计报告")
        print("="*50)
        print(f"处理文件数: {self.stats['processed']}")
        print(f"成功优化: {self.stats['optimized']}")
        print(f"处理错误: {self.stats['errors']}")
        
        if self.stats['total_size_before'] > 0:
            total_compression = (1 - self.stats['total_size_after'] / self.stats['total_size_before']) * 100
            print(f"总大小减少: {self.stats['total_size_before'] / 1024:.1f} KB → {self.stats['total_size_after'] / 1024:.1f} KB")
            print(f"总压缩比: {total_compression:.1f}%")
        
        print("="*50)
    
    def create_optimization_report(self):
        """创建优化报告"""
        report_path = "OPTIMIZATION_REPORT.json"
        report_data = {
            "optimization_date": datetime.now().isoformat(),
            "project": "桌面物理玩具",
            "target_specifications": {
                "size": f"{self.target_size}x{self.target_size}",
                "format": "PNG",
                "max_file_size_kb": self.max_file_size_kb,
                "color_mode": "RGBA"
            },
            "statistics": self.stats,
            "optimization_strategy": {
                "resampling_algorithm": "LANCZOS",
                "compression_level": 9,
                "transparency_support": True,
                "sharpening_filter": "UnsharpMask"
            }
        }
        
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, ensure_ascii=False, indent=2)
        
        print(f"优化报告已保存到: {report_path}")

def main():
    """主函数"""
    optimizer = ImageOptimizer()
    
    # 检查命令行参数
    if len(sys.argv) > 1:
        # 优化指定文件
        for file_path in sys.argv[1:]:
            optimizer.optimize_single_image(file_path)
    else:
        # 批量优化所有图片
        optimizer.batch_optimize()
    
    # 生成优化报告
    optimizer.create_optimization_report()

if __name__ == "__main__":
    main()