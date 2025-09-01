import math
import os
from PIL import Image, ImageDraw

class PaperAirplaneAnimation:
    def __init__(self, width=64, height=64, frames=30):
        self.width = width
        self.height = height
        self.frames = frames
        # 定义几种不同的纸飞机样式
        self.airplane_styles = {
            "classic": [  # 经典纸飞机
                (0, 0), (20, 4), (0, 8),     # 左翼
                (0, 4), (30, 4),             # 机身
                (0, 4), (20, 0), (30, 4),    # 右翼
                (25, 4), (30, 8)             # 尾翼
            ],
            "dart": [  # 飞镖型纸飞机
                (0, 2), (25, 4), (0, 6),     # 左翼
                (0, 4), (35, 4),             # 机身
                (0, 2), (25, 0), (35, 4),    # 右翼
                (30, 4), (35, 7),            # 下尾翼
                (30, 4), (35, 1)             # 上尾翼
            ],
            "glider": [  # 滑翔机型纸飞机
                (-5, 0), (20, 4), (-5, 8),   # 大左翼
                (0, 4), (25, 4),             # 机身
                (-5, 0), (20, -4), (25, 4),  # 大右翼
                (20, 4), (25, 8),            # 下尾翼
                (20, 4), (25, 0)             # 上尾翼
            ],
            "delta": [  # 三角翼纸飞机
                (0, 0), (25, 4), (0, 8),     # 左三角翼
                (0, 4), (30, 4),             # 机身
                (0, 0), (25, -4), (30, 4),   # 右三角翼
                (0, 4), (10, 8),             # 垂直尾翼
                (25, 4), (30, 0),            # 尾翼1
                (25, 4), (30, 8)             # 尾翼2
            ]
        }
        
    def generate_parabolic_path(self, frame):
        # 改进的飞行轨迹，包含更自然的抛物线和轻微的摆动
        t = frame / self.frames
        x = t * self.width
        y = 0.15 * (x - self.width/2)**2 + 15 + 3 * math.sin(3 * t * math.pi)  # 添加摆动效果
        return x, y
    
    def calculate_rotation(self, frame):
        # 改进的旋转计算，更符合真实飞行中的姿态变化
        t = frame / self.frames
        # 主要旋转角度基于飞行轨迹的切线
        base_angle = math.atan2(2 * 0.15 * (t * self.width - self.width/2), 1)
        # 添加由于摆动产生的额外旋转
        oscillation_angle = 0.2 * math.cos(3 * t * math.pi)
        return base_angle + oscillation_angle
    
    def rotate_point(self, point, center, angle):
        # 旋转点
        s, c = math.sin(angle), math.cos(angle)
        x, y = point[0] - center[0], point[1] - center[1]
        new_x = x * c - y * s
        new_y = x * s + y * c
        return (new_x + center[0], new_y + center[1])
    
    def draw_airplane(self, draw, center, angle, style="classic"):
        # 绘制指定样式的纸飞机
        airplane_points = self.airplane_styles[style]
        rotated_points = [
            self.rotate_point(p, (12, 4), angle)  # 以机身中心为旋转点
            for p in airplane_points
        ]
        
        # 将相对坐标转换为绝对坐标
        absolute_points = [(p[0] + center[0], p[1] + center[1]) for p in rotated_points]
        
        # 根据样式绘制飞机的不同部分
        if style == "classic":
            # 经典纸飞机
            draw.line([absolute_points[0], absolute_points[1], absolute_points[2]], fill="white", width=1)  # 左翼
            draw.line([absolute_points[3], absolute_points[4]], fill="white", width=2)  # 机身
            draw.line([absolute_points[5], absolute_points[6], absolute_points[7]], fill="white", width=1)  # 右翼
            draw.line([absolute_points[8], absolute_points[9]], fill="white", width=1)  # 尾翼
        elif style == "dart":
            # 飞镖型纸飞机
            draw.line([absolute_points[0], absolute_points[1], absolute_points[2]], fill="white", width=1)  # 左翼
            draw.line([absolute_points[3], absolute_points[4]], fill="white", width=2)  # 机身
            draw.line([absolute_points[5], absolute_points[6], absolute_points[7]], fill="white", width=1)  # 右翼
            draw.line([absolute_points[8], absolute_points[9]], fill="white", width=1)  # 下尾翼
            draw.line([absolute_points[10], absolute_points[11]], fill="white", width=1)  # 上尾翼
        elif style == "glider":
            # 滑翔机型纸飞机
            draw.line([absolute_points[0], absolute_points[1], absolute_points[2]], fill="white", width=1)  # 大左翼
            draw.line([absolute_points[3], absolute_points[4]], fill="white", width=2)  # 机身
            draw.line([absolute_points[5], absolute_points[6], absolute_points[7]], fill="white", width=1)  # 大右翼
            draw.line([absolute_points[8], absolute_points[9]], fill="white", width=1)  # 下尾翼
            draw.line([absolute_points[10], absolute_points[11]], fill="white", width=1)  # 上尾翼
        elif style == "delta":
            # 三角翼纸飞机
            draw.line([absolute_points[0], absolute_points[1], absolute_points[2]], fill="white", width=1)  # 左三角翼
            draw.line([absolute_points[3], absolute_points[4]], fill="white", width=2)  # 机身
            draw.line([absolute_points[5], absolute_points[6], absolute_points[7]], fill="white", width=1)  # 右三角翼
            draw.line([absolute_points[8], absolute_points[9]], fill="white", width=1)  # 垂直尾翼
            draw.line([absolute_points[10], absolute_points[11]], fill="white", width=1)  # 尾翼1
            draw.line([absolute_points[12], absolute_points[13]], fill="white", width=1)  # 尾翼2
    
    def generate_frame(self, frame_index, style="classic"):
        # 生成单个帧
        img = Image.new('RGBA', (self.width, self.height), color=(0, 0, 0, 0))  # 透明背景
        draw = ImageDraw.Draw(img)
        
        # 获取飞机位置和旋转角度
        x, y = self.generate_parabolic_path(frame_index)
        angle = self.calculate_rotation(frame_index)
        
        # 绘制飞机
        self.draw_airplane(draw, (x, y), angle, style)
        
        return img
    
    def generate_all_frames(self, output_dir="paper_airplane_frames"):
        # 为每种样式生成动画帧
        for style_name in self.airplane_styles.keys():
            style_dir = f"{output_dir}_{style_name}"
            if not os.path.exists(style_dir):
                os.makedirs(style_dir)
                
            for i in range(self.frames):
                img = self.generate_frame(i, style_name)
                img.save(f"{style_dir}/paper_airplane_{style_name}_{i:03d}.png")
            
            print(f"已生成 {self.frames} 帧{style_name}样式动画到 {style_dir} 目录")

    def generate_static_images(self, output_dir="paper_airplane_static"):
        # 生成每种样式的静态图片供选择
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        # 为每种样式生成一张居中的静态图片
        for style_name in self.airplane_styles.keys():
            img = Image.new('RGBA', (64, 64), color=(0, 0, 0, 0))
            draw = ImageDraw.Draw(img)
            
            # 使用该样式绘制居中的飞机
            self.draw_airplane(draw, (32, 32), 0, style_name)
            img.save(f"{output_dir}/paper_airplane_{style_name}.png")
        
        print(f"已生成 {len(self.airplane_styles)} 种静态纸飞机样式到 {output_dir} 目录")

# 使用示例
if __name__ == "__main__":
    animation = PaperAirplaneAnimation()
    
    # 生成静态图片供选择
    animation.generate_static_images()
    
    # 生成动画帧
    animation.generate_all_frames()
    
    # 为了与Godot项目集成，我们也生成一张静态纹理用于默认显示
    # 这将替代texture_generator.gd中生成的静态纸飞机纹理
    static_img = Image.new('RGBA', (64, 64), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(static_img)
    
    # 绘制一个默认的静态纸飞机（居中）
    airplane_points = [
        (12, 28), (42, 32), (12, 36),  # 左翼
        (12, 32), (52, 32),            # 机身
        (12, 28), (42, 24), (52, 32),  # 右翼
        (47, 32), (52, 36)             # 尾翼
    ]
    
    # 绘制飞机的各个部分
    draw.line([airplane_points[0], airplane_points[1], airplane_points[2]], fill="white", width=1)  # 左翼
    draw.line([airplane_points[3], airplane_points[4]], fill="white", width=2)  # 机身
    draw.line([airplane_points[5], airplane_points[6], airplane_points[7]], fill="white", width=1)  # 右翼
    draw.line([airplane_points[8], airplane_points[9]], fill="white", width=1)  # 尾翼
    
    static_img.save("assets/paper_plane.png")
    print("已生成Godot项目使用的静态纸飞机纹理: assets/paper_plane.png")