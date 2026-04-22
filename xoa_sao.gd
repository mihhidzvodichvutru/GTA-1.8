extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var timer = $Timer

func _ready():
	timer.timeout.connect(_on_hoi_sinh)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Nếu người chơi chạm vào và đang có sao
	if body.is_in_group("Player") and WantedManager.wanted_level > 0:
		WantedManager.xoa_het_sao()
		print("✨ Đã ăn bùa! Xóa toàn bộ sao. Cooldown 30s...")
		
		# Tàng hình và vô hiệu hóa va chạm
		sprite.hide()
		collision.set_deferred("disabled", true)
		timer.start()

func _on_hoi_sinh():
	# Hết 30s, hiện lại vật phẩm
	sprite.show()
	collision.set_deferred("disabled", false)
	print("⭐ Bùa xóa tội đã xuất hiện lại!")
