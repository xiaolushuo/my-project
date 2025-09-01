extends Node

func _ready():
	var generator = preload("res://texture_generator.gd").new()
	add_child(generator)
	
	# 等待一帧后退出
	await get_tree().process_frame
	get_tree().quit()