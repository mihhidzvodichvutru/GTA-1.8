extends CharacterBody2D

@export var speed: float = 90
@export var steer_force: float = 10.0
@export var separation_weight: float = 2.0 # Trọng số tách bầy

@export var sat_thuong: int = 10
@export var thoi_gian_hoi_chieu: float = 1.0 
var thoi_gian_da_qua: float = 0.0

var current_avoid_dir: Vector2 = Vector2.ZERO
var target_player: Node2D = null
var nearby_peers: Array = [] # Cái túi đựng đồng bọn

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
	_pick_new_wander_dir() 
	
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)

func _pick_new_wander_dir():
	var random_angle = randf() * PI * 2
	wander_dir = Vector2(cos(random_angle), sin(random_angle))
	time_to_change_dir = randf_range(2.0, 5.0) 

func _physics_process(delta: float) -> void:
	thoi_gian_da_qua += delta

	# --- 2. HỆ THỐNG DESPAWN THÔNG MINH ---
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
			current_speed = speed * 0.4 
			time_to_change_dir -= delta
			if time_to_change_dir <= 0:
				_pick_new_wander_dir()
			desired_dir = wander_dir

		State.CHASE:
			if target_player != null:
				current_speed = speed 
				var distance = global_position.distance_to(target_player.global_position)
				if distance > 45.0: 
					desired_dir = global_position.direction_to(target_player.global_position)
				else:
					if velocity.length() > 0:
						desired_dir = velocity.normalized()
			else:
				current_state = State.WANDER 

	# --- 4. HỆ THỐNG NÉ TƯỜNG DÙNG CHUNG ---
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
	
	# ==========================================
	# --- 4.5. TÍNH TOÁN LỰC ĐẨY NHAU (ĐÃ FIX) ---
	# ==========================================
	var separation_dir = Vector2.ZERO
	for peer in nearby_peers:
		if is_instance_valid(peer) and peer != self: 
			var diff = global_position - peer.global_position
			var dist = diff.length()
			
			# Lỗi chia cho 0: Nếu 2 con spawn đè lên nhau y hệt, dist = 0 sẽ làm game lỗi
			if dist == 0:
				# Tạo một hướng đẩy ngẫu nhiên để chúng tách ra ngay lập tức
				diff = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
				dist = 0.1 
			
			# Chỉ đẩy nhau khi lại quá gần (khoảng cách < 50 pixel)
			if dist < 50.0:
				# Công thức mới: Càng gần đẩy càng mạnh, lực đẩy mượt hơn
				separation_dir += (diff.normalized() * (50.0 / dist))
				
	# Giới hạn lực đẩy tối đa để tụi nó không bị văng đi quá mạnh
	if separation_dir.length() > 0:
		separation_dir = separation_dir.limit_length(5.0) 
		separation_dir *= separation_weight
	
	# --- TỔNG HỢP CÁC LỰC ---
	var final_dir = desired_dir
	
	if current_avoid_dir.length() > 0.01:
		final_dir = (desired_dir + current_avoid_dir * 2.5).normalized()
		if current_state == State.WANDER and target_avoid_dir != Vector2.ZERO:
			wander_dir = current_avoid_dir

	# Cộng lực tách bầy vào hướng đi chính
	if separation_dir.length() > 0:
		final_dir = (final_dir + separation_dir).normalized()

	velocity = velocity.lerp(final_dir * current_speed, steer_force * delta)

	# --- FIX LỖI CHẠY NGANG (Giữ nguyên của ông) ---
	if velocity.length() > 5.0:
		rotation = velocity.angle()

	move_and_slide()
	
	# --- 5. VA CHẠM TRỪ MÁU ---
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

# --- 6. TÍN HIỆU TẦM NHÌN ---
func _on_aggro_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body
		current_state = State.CHASE

func _on_aggro_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = null
		current_state = State.WANDER

# --- 7. TÍN HIỆU TÁCH BẦY ---
func _on_separation_area_body_entered(body: Node2D) -> void:
	if body != self and body.is_in_group("Enemy"):
		if not nearby_peers.has(body):
			nearby_peers.append(body)

func _on_separation_area_body_exited(body: Node2D) -> void:
	if nearby_peers.has(body):
		nearby_peers.erase(body)
