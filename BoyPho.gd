extends CharacterBody2D

@export var speed: float = 90
@export var steer_force: float = 10.0

@export var sat_thuong: int = 10
@export var thoi_gian_hoi_chieu: float = 1.0 
var thoi_gian_da_qua: float = 0.0

var current_avoid_dir: Vector2 = Vector2.ZERO
var target_player: Node2D = null

# --- 1. HỆ THỐNG MÁY TRẠNG THÁI ---
enum State { WANDER, CHASE }
var current_state = State.WANDER
var wander_dir: Vector2 = Vector2.ZERO
var time_to_change_dir: float = 0.0

@onready var aggro_area = $AggroArea
@onready var ray_left = $RayLeft
@onready var ray_center = $RayCenter
@onready var ray_right = $RayRight

func _ready() -> void:
	add_to_group("Enemy")
	_pick_new_wander_dir() # Bắt đầu game là đi dạo luôn
	
	if aggro_area:
		# Kẻ địch được spawn ra kiểm tra xem nếu chưa kết nối thì mới kết nối
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)

# Hàm random hướng đi lúc rảnh rỗi
func _pick_new_wander_dir():
	var random_angle = randf() * PI * 2
	wander_dir = Vector2(cos(random_angle), sin(random_angle))
	time_to_change_dir = randf_range(2.0, 5.0) # Đi thẳng 2-5 giây rồi mới bẻ lái

func _physics_process(delta: float) -> void:
	thoi_gian_da_qua += delta

	# --- 2. HỆ THỐNG DESPAWN THÔNG MINH ---
	# Tự tìm Shipper để đo khoảng cách, quá 2500px thì tự sát cho nhẹ máy
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		if global_position.distance_to(players[0].global_position) > 2500.0:
			queue_free()
			return

	var desired_dir = Vector2.ZERO
	var current_speed = speed

	# --- 3. XỬ LÝ TRẠNG THÁI ---
	match current_state:
		State.WANDER:
			current_speed = speed * 0.4 # Đi lượn lờ thì đi chậm thôi (40% tốc độ)
			time_to_change_dir -= delta
			if time_to_change_dir <= 0:
				_pick_new_wander_dir()
			desired_dir = wander_dir

		State.CHASE:
			if target_player != null:
				current_speed = speed # Đuổi thì vặn max ga
				var distance = global_position.distance_to(target_player.global_position)
				if distance > 45.0: 
					desired_dir = global_position.direction_to(target_player.global_position)
				else:
					if velocity.length() > 0:
						desired_dir = velocity.normalized()
			else:
				current_state = State.WANDER # Mất dấu thì đi lượn tiếp

	# --- 4. HỆ THỐNG NÉ TƯỜNG DÙNG CHUNG ---
	# (Cho cả lúc đi dạo và rượt đuổi)
	if velocity.length() > 5.0:
		ray_left.force_raycast_update()
		ray_center.force_raycast_update()
		ray_right.force_raycast_update()

	var target_avoid_dir = Vector2.ZERO 
	if ray_center.is_colliding():
		target_avoid_dir = ray_center.get_collision_normal()
	elif ray_left.is_colliding():
		target_avoid_dir = ray_left.get_collision_normal()
	elif ray_right.is_colliding():
		target_avoid_dir = ray_right.get_collision_normal()

	current_avoid_dir = current_avoid_dir.lerp(target_avoid_dir, 15.0 * delta)
	var final_dir = desired_dir
	
	if current_avoid_dir.length() > 0.01:
		final_dir = (desired_dir + current_avoid_dir * 2.5).normalized()
		# Nếu đang đi dạo mà đập mặt vào tường -> Dội lại và đổi hướng dạo
		if current_state == State.WANDER and target_avoid_dir != Vector2.ZERO:
			wander_dir = current_avoid_dir

	velocity = velocity.lerp(final_dir * current_speed, steer_force * delta)

	if velocity.length() > 5.0:
		rotation = velocity.angle() + PI / 2

	move_and_slide()
	
	# --- 5. VA CHẠM TRỪ MÁU (Giữ nguyên) ---
	for i in get_slide_collision_count():
		var va_cham = get_slide_collision(i)
		var ke_bi_tong = va_cham.get_collider()
		
		# --- BẮT ĐẦU DEBUG ---
		print("💥 Vừa tông trúng: ", ke_bi_tong.name)
		
		if ke_bi_tong and ke_bi_tong.is_in_group("Player"):
			print("✅ Đúng là Player rồi!")
			
		if thoi_gian_da_qua >= thoi_gian_hoi_chieu:
				print("⏳ Đã hồi chiêu xong! Chuẩn bị cắn máu...")
				
				if ke_bi_tong.has_method("bi_tru_mau"):
					ke_bi_tong.bi_tru_mau(sat_thuong)
					print("🩸 Đã gọi hàm bi_tru_mau thành công!")
				else:
					print("❌ LỖI: Không tìm thấy hàm bi_tru_mau trong xe Shipper")
					
			thoi_gian_da_qua = 0.0
			else:
				print("⌛ Đang hồi chiêu, chưa tông được tiếp...")

# --- 6. TÍN HIỆU TẦM NHÌN (Đã xóa cái Hive Mind) ---
func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body
		current_state = State.CHASE
		# Đã xóa dòng get_tree().call_group ở đây!

func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print(">>> Shipper đã cắt đuôi thành công.")
		target_player = null
		current_state = State.WANDER
