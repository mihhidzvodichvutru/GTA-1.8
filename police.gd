extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 600.0 
@export var separation_weight: float = 2.0 # Độ mạnh của lực đẩy đồng bọn

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var separation_area: Area2D = $SeparationArea

var target_node: Node2D = null
var nearby_peers: Array = [] # Danh sách đồng bọn đang ở quá gần

func _ready() -> void:
	target_node = get_tree().get_first_node_in_group("Player")
	# Kết nối tín hiệu từ Area2D vào code
	separation_area.body_entered.connect(_on_separation_entered)
	separation_area.body_exited.connect(_on_separation_exited)
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if target_node:
		nav_agent.target_position = target_node.global_position

func _physics_process(delta: float) -> void:
	if not target_node: return
	
	nav_agent.target_position = target_node.global_position
	var desired_velocity = Vector2.ZERO

	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		# 1. Hướng đuổi theo A*
		var pursuit_dir = global_position.direction_to(next_path_pos)
		
		# 2. Cộng thêm lực đẩy đồng bọn từ SeparationArea
		var sep_dir = _get_separation_vector()
		
		# Hợp lực: Đuổi theo + Đẩy nhau ra
		desired_velocity = (pursuit_dir + sep_dir).normalized() * speed

<<<<<<< HEAD
	# Áp dụng gia tốc để bẻ lái mượt
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	if velocity.length() > 5.0:
		rotation = velocity.angle()
		
	move_and_slide()

# Logic tính toán lực đẩy dựa trên Area2D của ông
func _get_separation_vector() -> Vector2:
	var v = Vector2.ZERO
	for peer in nearby_peers:
		if peer != self:
			var diff = global_position - peer.global_position
			# Khoảng cách càng gần, lực đẩy càng mạnh
			v += diff.normalized() / diff.length()
	return v * separation_weight * 100 # Nhân thêm hệ số để lực đẩy có tác dụng

# Các hàm nhận tín hiệu từ Area2D
func _on_separation_entered(body):
	if body is CharacterBody2D and body != self:
		nearby_peers.append(body)

func _on_separation_exited(body):
	nearby_peers.erase(body)
=======
# Tách phần di chuyển và xoay mặt ra một hàm riêng cho gọn
func _apply_movement():
	if velocity.length() > 0:
		# Đã đổi thành - PI / 2 dành cho trường hợp đầu xe chĩa XUỐNG DƯỚI
		rotation = velocity.angle() - PI / 2
	move_and_slide()
>>>>>>> f29a7fcd32ccec941b4cb0da8f32ec0f3fb4c120
