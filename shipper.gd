extends CharacterBody2D

# Bỏ biến speed cũ đi, thay bằng 3 thông số "chuẩn xe máy" này:
@export var max_speed: float = 200    # Tốc độ tối đa (tôi giảm xuống 300 cho vừa ngõ hẻm)
@export var acceleration: float = 210 # Độ "bốc" của xe (số càng nhỏ xe lên ga càng chậm)
@export var friction: float = 800    # Quán tính/Ma sát (số càng nhỏ xe trượt càng dài khi nhả ga)

func _physics_process(delta):
	var move_dir = Vector2.ZERO
	
	# 1. Nhận tín hiệu WASD (giữ nguyên)
	if Input.is_physical_key_pressed(KEY_W): move_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): move_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): move_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move_dir.x += 1
		
	# 2. Xử lý di chuyển chéo và xoay mặt xe (giữ nguyên)
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		rotation = move_dir.angle() + PI / 2
		
		# 3A. KHI ĐANG VẶN GA: Tăng tốc dần đều về phía max_speed
		# Dùng move_toward để uốn nắn vận tốc từ từ, nhân với delta để mượt mà trên mọi máy
		velocity = velocity.move_toward(move_dir * max_speed, acceleration * delta)
		
	else:
		# 3B. KHI NHẢ GA: Giảm tốc dần đều về 0 (Tạo cảm giác trượt quán tính)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# 4. Áp dụng lực và chạy
	move_and_slide()
