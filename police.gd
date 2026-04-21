extends CharacterBody2D

@export var speed: float = 160.0
@export var acceleration: float = 400.0 # Giảm nhẹ gia tốc để xe chạy đầm hơn
@export var separation_weight: float = 1.5 # Giảm trọng số tách bầy để bớt lắc

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var separation_area: Area2D = $SeparationArea

var target_node: Node2D = null
var nearby_peers: Array = [] 
var dang_truy_na: bool = false 

func _ready() -> void:
	add_to_group("CanhSat")
	if separation_area:
		separation_area.body_entered.connect(_on_separation_entered)
		separation_area.body_exited.connect(_on_separation_exited)

func nhan_lenh_truy_na(thang_shipper: Node2D, so_sao: int) -> void:
	target_node = thang_shipper
	dang_truy_na = true
	speed = 150.0 + (so_sao * 20.0) 

func huy_truy_na() -> void:
	dang_truy_na = false
	target_node = null
	velocity = Vector2.ZERO 

func _physics_process(delta: float) -> void:
	if not dang_truy_na or not is_instance_valid(target_node):
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
	
	# --- FIX 2: LÀM MƯỢT GÓC XOAY ---
	if velocity.length() > 20.0: # Chỉ xoay khi đang chạy đủ nhanh để tránh rung lắc tại chỗ
		var target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, 10.0 * delta)
		
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
