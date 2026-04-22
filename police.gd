extends CharacterBody2D

var trang_thai: String = "PATROL"
var vi_tri_chot: Vector2
var diem_tuan_tra: Vector2
var thoi_gian_nghi: float = 0.0
@export var speed: float = 150.0
@export var acceleration: float = 600.0 
var path_update_timer: float = 0.0
var thoi_gian_khong_thay_player: float = 0.0
@export var MAX_THOI_GIAN_CHO: float = 10.0 # Sau 10s không thấy sẽ tự biến mất
@export var tam_nhin: float = 1500.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_node: Node2D = null

var dang_nhin_thay_player: bool = true

func _ready() -> void:
	target_node = get_tree().get_first_node_in_group("Player")
	vi_tri_chot = global_position 
	diem_tuan_tra = vi_tri_chot # Vừa sinh ra là lấy luôn chốt làm điểm tuần tra
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if target_node:
		nav_agent.target_position = target_node.global_position

func _physics_process(delta: float) -> void:
	if not target_node:
		return
		
	# 1. KIỂM TRA TRẠNG THÁI ĐỂ XÁC ĐỊNH MỤC TIÊU GPS
	if trang_thai == "CHASE":
		nav_agent.target_position = target_node.global_position
	else:
		# ĐANG ĐI TUẦN (PATROL)
		if thoi_gian_nghi > 0.0:
			# Đứng nghỉ tại chỗ
			thoi_gian_nghi -= delta
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			move_and_slide()
			return
		
		# Gán mục tiêu là điểm tuần tra
		nav_agent.target_position = diem_tuan_tra
			
		# Nếu đã đến nơi (hoặc cách dưới 30 pixel)
		if global_position.distance_to(diem_tuan_tra) < 30.0 or nav_agent.is_navigation_finished():
			thoi_gian_nghi = randf_range(1.5, 3.5) # Dừng lại quan sát 1.5 đến 3.5 giây
			
			# Quay compa tìm điểm đi tuần mới cách chốt từ 150-300 pixel
			var goc_ngau_nhien = randf() * TAU
			var khoang_cach = randf_range(150.0, 300.0)
			var diem_ngau_nhien = vi_tri_chot + Vector2(cos(goc_ngau_nhien), sin(goc_ngau_nhien)) * khoang_cach
			
			# Dùng thuật toán ép cái tọa độ ngẫu nhiên đó xuống mặt đường an toàn
			var nav_map = get_world_2d().navigation_map
			diem_tuan_tra = NavigationServer2D.map_get_closest_point(nav_map, diem_ngau_nhien)

	# 2. LOGIC LÁI XE VÀ LÁCH NHAU
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var desired_velocity: Vector2 = global_position.direction_to(next_path_pos) * speed
	var new_velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		velocity = new_velocity
		_apply_movement()

# Hàm này nhận lại vận tốc an toàn (đã lách nhau) từ NavigationAgent2D
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	_apply_movement()

# Tách phần di chuyển và xoay mặt ra một hàm riêng cho gọn
func _apply_movement():
	if velocity.length() > 0:
		# Đã đổi thành - PI / 2 dành cho trường hợp đầu xe chĩa XUỐNG DƯỚI
		rotation = velocity.angle() - PI / 2
	move_and_slide()

# ==========================================
# 3. HỆ THỐNG BẮT GIỮ MỚI (DÙNG AREA2D)
# ==========================================
func _on_catch_area_body_entered(body: Node2D) -> void:
	# Chỉ kích hoạt bắt giữ khi xe đang ở trạng thái truy đuổi
	if trang_thai == "CHASE" and WantedManager.wanted_level > 0:
		# Check xem kẻ lọt vào vùng quét có đúng là người chơi không
		if body.is_in_group("Player"):
			print("🚨 CẢNH SÁT: Đã túm cổ Shipper!")
			
			# Gọi hàm nhận sát thương của Shipper (Ép chết luôn)
			if body.has_method("bi_bat"):
				body.bi_bat()
			
			# Hoặc nếu ông viết sẵn hàm bi_bat() bên Shipper thì gọi nó
			# if body.has_method("bi_bat"): body.bi_bat()
			
			# Chuyển cảnh sát sang trạng thái nghỉ đi tuần
			trang_thai = "PATROL"
