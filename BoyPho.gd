extends CharacterBody2D

# Các thông số để huynh tinh chỉnh ngoài Inspector
@export var speed: float = 160.0

var target_player: Node2D = null
var is_chasing: bool = false

# Lấy các node con
@onready var aggro_area = $AggroArea

func _ready() -> void:
	# 1. Tự động phát thẻ "Enemy"
	add_to_group("Enemy")
	
	# 2. Tự động nối dây tín hiệu (Phòng trường hợp huynh quên cắm dây ở giao diện)
	if aggro_area:
		if not aggro_area.body_entered.is_connected(_on_aggro_area_body_entered):
			aggro_area.body_entered.connect(_on_aggro_area_body_entered)
		if not aggro_area.body_exited.is_connected(_on_aggro_area_body_exited):
			aggro_area.body_exited.connect(_on_aggro_area_body_exited)

func _physics_process(_delta: float) -> void:
	if is_chasing and target_player != null:
		# Lấy hướng từ Quái đến Shipper
		var direction = global_position.direction_to(target_player.global_position)
		
		# Áp công thức vận tốc chuẩn
		velocity = direction * speed
		
		# Thực hiện di chuyển
		move_and_slide()
	else:
		# Nếu không đuổi nữa thì đứng lại
		velocity = Vector2.ZERO

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
