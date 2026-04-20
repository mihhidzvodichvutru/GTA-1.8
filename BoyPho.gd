extends CharacterBody2D

# Đệ tăng steer_force mặc định lên cao hơn một chút, vì ta sẽ đồng bộ nó với delta
@export var speed: float = 150
@export var steer_force: float = 10.0 # Mức 5.0 - 10.0 là bao mượt khi chạy với delta

# Biến đệm để làm mượt lực dạt tường
var current_avoid_dir: Vector2 = Vector2.ZERO

var target_player: Node2D = null
var is_chasing: bool = false

@onready var aggro_area = $AggroArea
@onready var ray_left = $RayLeft
@onready var ray_center = $RayCenter
@onready var ray_right = $RayRight

func _ready() -> void:
	add_to_group("Enemy")
	
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)

func _physics_process(delta: float) -> void:
	if is_chasing and target_player != null:
		
		# --- FIX LỖI VĂNG XE KHI ÁP SÁT ĐUÔI ---
		var distance = global_position.distance_to(target_player.global_position)
		var desired_dir = Vector2.ZERO
		
		if distance > 45.0: # Huynh có thể tăng giảm số 45 này cho vừa với thân xe
			# Khi ở xa: Nhắm thẳng vào tâm Shipper
			desired_dir = global_position.direction_to(target_player.global_position)
		else:
			# Khi áp sát: Khóa vô lăng, giữ nguyên hướng lao tới để húc, 
			# không để vector bị bẻ ngoắt 90 độ khi chênh lệch 1-2 pixel
			if velocity.length() > 0:
				desired_dir = velocity.normalized()
		# ----------------------------------------
		
		# Chỉ xoay râu khi thực sự có vận tốc (> 10) để tránh bị giật cục xoay vòng lúc mới khởi động
		if velocity.length() > 10.0:
			var angle = velocity.angle()
			ray_left.rotation = angle - deg_to_rad(45)
			ray_center.rotation = angle
			ray_right.rotation = angle + deg_to_rad(45)
			
			# Cập nhật va chạm ngay lập tức trong frame hiện tại chống dịch chuyển tức thời
			ray_left.force_raycast_update()
			ray_center.force_raycast_update()
			ray_right.force_raycast_update()

		var target_avoid_dir = Vector2.ZERO 
		
		# Lấy hướng pháp tuyến của bức tường nếu có va chạm
		if ray_center.is_colliding():
			target_avoid_dir = ray_center.get_collision_normal()
		elif ray_left.is_colliding():
			target_avoid_dir = ray_left.get_collision_normal()
		elif ray_right.is_colliding():
			target_avoid_dir = ray_right.get_collision_normal()

		# LERP LỰC DẠT TƯỜNG: Đây là mấu chốt để hết bị giật
		current_avoid_dir = current_avoid_dir.lerp(target_avoid_dir, 15.0 * delta)

		var final_dir = desired_dir
		
		# Chỉ bẻ lái dạt ra khi lực đệm (current_avoid_dir) vẫn còn tồn tại
		if current_avoid_dir.length() > 0.01:
			final_dir = (desired_dir + current_avoid_dir * 2.5).normalized()
		
		# Phải nhân steer_force với delta để không bị bẻ lái quá gắt theo số Frame
		velocity = velocity.lerp(final_dir * speed, steer_force * delta)
		
		move_and_slide()
	else:
		# Giảm tốc từ từ khi mất dấu Shipper
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		move_and_slide()

# --- Các hàm nhận tín hiệu giữ nguyên ---
func start_chasing(player):
	target_player = player
	is_chasing = true

func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body
		is_chasing = true
		get_tree().call_group("Enemy", "start_chasing", body)

func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print(">>> Shipper đã chạy thoát khỏi tầm nhìn.")
		target_player = null
		is_chasing = false
