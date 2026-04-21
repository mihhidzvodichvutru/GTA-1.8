extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 600.0 

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_node: Node2D = null

func _ready() -> void:
	target_node = get_tree().get_first_node_in_group("Player")
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if target_node:
		nav_agent.target_position = target_node.global_position

func _physics_process(delta: float) -> void:
	if not target_node:
		return
		
	nav_agent.target_position = target_node.global_position

	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var desired_velocity: Vector2 = global_position.direction_to(next_path_pos) * speed
	var new_velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	# SỰ KHÁC BIỆT NẰM Ở ĐÂY:
	# Nếu Avoidance đang bật, ta nộp new_velocity vào hàm set_velocity của nav_agent
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		# Nếu tắt, chạy như bình thường
		velocity = new_velocity
		_apply_movement()

# Hàm này nhận lại vận tốc an toàn (đã lách nhau) từ NavigationAgent2D
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	_apply_movement()

# Tách phần di chuyển và xoay mặt ra một hàm riêng cho gọn
func _apply_movement():
	if velocity.length() > 0:
		rotation = velocity.angle()
	move_and_slide()

# (Giữ nguyên hàm _on_catch_area_body_entered của ông ở dưới đây)
# ...
