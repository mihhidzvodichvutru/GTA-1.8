extends CharacterBody2D

@export var speed: float = 400.0

func _physics_process(_delta):
	var move_dir = Vector2.ZERO
	
	# 1. Nhận tín hiệu WASD 
	if Input.is_physical_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		move_dir.x += 1
		
	# 2. Xử lý di chuyển chéo (W+A, W+D...)
	if move_dir != Vector2.ZERO:
		# Lệnh normalized() giúp đi chéo tốc độ vẫn đều, không bị phóng nhanh như hack
		move_dir = move_dir.normalized()
		
		# ĐIỂM MẤU CHỐT: Xoay mặt theo hướng phím WASD
		# angle() lấy góc của hướng di chuyển. Cộng thêm PI/2 (90 độ) để bù lại 
		# góc nhìn mặc định của ảnh Godot (do ảnh mặc định đang ngửa mặt lên trên).
		rotation = move_dir.angle() + PI / 2
		
	# 3. Áp dụng lực và chạy
	velocity = move_dir * speed
	move_and_slide()
