extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 600.0 

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_node: Node2D = null

func _ready() -> void:
	# Lưu ý: Theo như setting hôm trước, group của ông đang là "Player" (chữ P viết hoa)
	target_node = get_tree().get_first_node_in_group("Player")
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().physics_frame
	if target_node:
		nav_agent.target_position = target_node.global_position

func _physics_process(delta: float) -> void:
	if not target_node:
		return
		
	# Cập nhật vị trí shipper liên tục
	nav_agent.target_position = target_node.global_position

	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var desired_velocity: Vector2 = global_position.direction_to(next_path_pos) * speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	if velocity.length() > 0:
		rotation = velocity.angle()
		
	move_and_slide()

# ==========================================
# PHẦN XỬ LÝ TÍN HIỆU TÓM NGƯỜI CHƠI
# ==========================================
func _on_catch_area_body_entered(body: Node2D) -> void:
	# Kiểm tra xem cái vật thể vừa đi vào vòng Area2D có mang group "Player" không
	if body.is_in_group("Player"):
		# In ra dòng chữ đỏ lòm ở cửa sổ Output (dưới cùng màn hình) để test
		print_rich("[color=red]WASTED! ĐÃ TÓM ĐƯỢC SHIPPER![/color]")
		
		# Dừng mọi hoạt động vật lý của cảnh sát (đứng im tại chỗ luôn)
		set_physics_process(false)
		
		# (Tùy chọn) Chỗ này sau này ông có thể thêm code gọi màn hình Game Over,
		# hoặc trừ tiền, trừ sao, respawn lại player...
