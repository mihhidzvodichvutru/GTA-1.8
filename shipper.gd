extends CharacterBody2D

@export var speed: float = 400.0
@export var rotation_speed: float = 3.5

var rotation_direction: float = 0.0

func get_input():
	# Lấy tín hiệu rẽ trái phải (Phím A/D hoặc Mũi tên Trái/Phải)
	rotation_direction = Input.get_axis("ui_left", "ui_right")
	
	# Lấy tín hiệu tiến lùi (Phím W/S hoặc Mũi tên Lên/Xuống)
	var input_dir = Input.get_axis("ui_down", "ui_up") 
	
	# Tính toán vận tốc theo hướng mũi xe. 
	# transform.y là trục dọc của xe, nhân với âm input_dir vì Godot trục Y hướng xuống dưới
	velocity = transform.y * -input_dir * speed 

func _physics_process(delta: float):
	get_input()
	
	# Cơ chế thực tế: Chỉ cho phép bẻ lái khi xe ĐANG DI CHUYỂN
	if velocity.length() > 0:
		# Đảo chiều bẻ lái khi đi lùi để giống thật hơn
		var direction_modifier = 1 if velocity.dot(transform.y) < 0 else -1
		rotation += rotation_direction * rotation_speed * delta * direction_modifier
		
	# Lệnh thần thánh giúp xe di chuyển và tự trượt khi đụng tường
	move_and_slide()