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
@onready var separation_area: Area2D = $SeparationArea

var target_node: Node2D = null
var nearby_peers: Array = [] 
var dang_truy_na: bool = false 

var dang_nhin_thay_player: bool = true

func _ready() -> void:
	target_node = get_tree().get_first_node_in_group("Player")
	vi_tri_chot = global_position 
	diem_tuan_tra = vi_tri_chot # Vừa sinh ra là lấy luôn chốt làm điểm tuần tra
	call_deferred("actor_setup")

func nhan_lenh_truy_na(thang_shipper: Node2D, so_sao: int) -> void:
	target_node = thang_shipper
	dang_truy_na = true
	speed = 150.0 + (so_sao * 20.0) 

func huy_truy_na() -> void:
	dang_truy_na = false
	target_node = null
	velocity = Vector2.ZERO 

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
		
		# --- LOGIC BẮT GIỮ (BUSTED) ---
	# Chỉ bắt khi đang có sao và xe cảnh sát đang ở chế độ truy đuổi
	if trang_thai == "CHASE" and WantedManager.wanted_level > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider and collider.is_in_group("Player"):
				if collider.has_method("bi_bat"):
					collider.bi_bat()
					# Chuyển cảnh sát sang trạng thái nghỉ để không spam code bắt liên tục
					trang_thai = "PATROL"
		
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

	# 2. LOGIC LÁI XE VÀ LÁCH NHAU (Chạy tiếp nếu chưa đến đích)
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return
		
	nav_agent.target_position = target_node.global_position
	var desired_velocity = Vector2.ZERO
	var distance_to_target = global_position.distance_to(target_node.global_position)

	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var pursuit_dir = global_position.direction_to(next_path_pos)
		
		# --- FIX 1: VÙNG HÒA BÌNH ---
		# Nếu cách Shipper dưới 80px, tụi nó sẽ bớt đẩy nhau để tập trung "bao vây"
		var current_sep_weight = separation_weight
		if distance_to_target < 80.0:
			current_sep_weight *= 0.3 # Giảm 70% lực đẩy khi đã áp sát
			
		var sep_dir = _get_separation_vector() * current_sep_weight
		
		var current_speed = speed
		if distance_to_target < 60.0:
			current_speed = speed * 0.5 # Rà phanh chậm lại
			
		desired_velocity = (pursuit_dir + sep_dir).normalized() * current_speed

	# Áp dụng di chuyển mượt
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
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
	_kiem_tra_bat_shipper()

func _kiem_tra_bat_shipper():
	if not dang_truy_na: return
	for i in get_slide_collision_count():
		var va_cham = get_slide_collision(i)
		var ke_bi_tong = va_cham.get_collider()
		if ke_bi_tong and ke_bi_tong.is_in_group("Player"):
			velocity = Vector2.ZERO
			dang_truy_na = false
			if ke_bi_tong.has_method("bi_tru_mau"):
				ke_bi_tong.bi_tru_mau(20)
			if has_node("/root/WantedManager"):
				WantedManager.xoa_truy_na()
			
			var push_back_dir = (global_position - ke_bi_tong.global_position).normalized()
			global_position = ke_bi_tong.global_position + push_back_dir * 62.0

# --- FIX 3: GIỚI HẠN LỰC ĐẨY (SOFT SEPARATION) ---
func _get_separation_vector() -> Vector2:
	var v = Vector2.ZERO
	for peer in nearby_peers:
		if is_instance_valid(peer) and peer != self:
			var diff = global_position - peer.global_position
			var dist = diff.length()
			if dist > 0.1: 
				# Dùng công thức suy giảm lực để không bị văng đột ngột
				v += (diff.normalized() / (dist * 0.5))
	
	# Giới hạn lực đẩy tối đa, không cho phép nó mạnh hơn lực đuổi
	return v.limit_length(0.8) 

func _on_separation_entered(body):
	if body is CharacterBody2D and body != self and body.is_in_group("CanhSat"):
		if not nearby_peers.has(body):
			nearby_peers.append(body)

func _on_separation_exited(body):
	if nearby_peers.has(body):
		nearby_peers.erase(body)
