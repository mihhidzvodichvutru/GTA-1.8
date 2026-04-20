extends CharacterBody2D

# Các thông số để huynh tinh chỉnh ngoài Inspector
@export var speed: float = 160.0
@export var steer_force: float = 0.1 # Độ bẻ lái: 0.1 là bo cua mượt, 1.0 là quay xe gắt

var target_player: Node2D = null
var is_chasing: bool = false

# Lấy các node con
@onready var aggro_area = $AggroArea

# Kéo 3 cái râu vừa tạo vào đây để code nhận diện
@onready var ray_left = $RayLeft
@onready var ray_center = $RayCenter
@onready var ray_right = $RayRight

func _ready() -> void:
	# 1. Tự động phát thẻ "Enemy"
	add_to_group("Enemy")
	
	# 2. Tự động nối dây tín hiệu
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)

func _physics_process(_delta: float) -> void:
	if is_chasing and target_player != null:
		# 1. Hướng khao khát: Vector thô đâm thẳng vào Shipper
		var desired_dir = global_position.direction_to(target_player.global_position)
		
		# 2. Xoay 3 cái râu về phía đang chạy
		if velocity.length() > 0:
			var angle = velocity.angle()
			ray_left.rotation = angle - deg_to_rad(45)
			ray_center.rotation = angle
			ray_right.rotation = angle + deg_to_rad(45)

		# 3. Tính toán lực dội lại khi đụng tường
		var avoid_dir = Vector2.ZERO
		if ray_center.is_colliding():
			# Mắt kẹt thẳng mặt -> Ép rẽ sang 1 bên vuông góc (90 độ)
			avoid_dir = velocity.rotated(deg_to_rad(90)).normalized()
		elif ray_left.is_colliding():
			# Tường bên trái -> Dạt sang phải
			avoid_dir = velocity.rotated(deg_to_rad(90)).normalized()
		elif ray_right.is_colliding():
			# Tường bên phải -> Dạt sang trái
			avoid_dir = velocity.rotated(deg_to_rad(-90)).normalized()

		# 4. Trộn hệ vector: Vừa nhắm Shipper, vừa cộng thêm lực dạt tường
		var final_dir = (desired_dir + avoid_dir * 1.5).normalized()
		
		# 5. Dùng Lerp để bẻ lái từ từ, tạo cảm giác lách trượt mượt mà
		velocity = velocity.lerp(final_dir * speed, steer_force)
		
		move_and_slide()
	else:
		# Phanh từ từ khi mất dấu thay vì khựng lại ngay lập tức
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
		move_and_slide()

# --- Các hàm nhận tín hiệu ---
func start_chasing(player):
	target_player = player
	is_chasing = true

func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# 1. Tự mình đuổi
		target_player = body
		is_chasing = true
		
		# 2. Hô hào cả đàn (Gọi đến tất cả các node trong group Enemy)
		get_tree().call_group("Enemy", "start_chasing", body)

func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print(">>> Shipper đã chạy thoát khỏi tầm nhìn.")
		target_player = null
		is_chasing = false
