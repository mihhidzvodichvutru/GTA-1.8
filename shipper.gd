extends CharacterBody2D

@export var max_speed: float = 100    
@export var acceleration: float = 150 # Lên ga từ từ (đi thẳng)
@export var friction: float = 800     # Quán tính phanh khi nhả phím
# --- BIẾN MỚI ---
@export var traction: float = 200    # Độ bám đường: Thông số càng cao, cua càng gắt, hết trượt!

func _physics_process(delta):
	var move_dir = Vector2.ZERO
	
	if Input.is_physical_key_pressed(KEY_W): move_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): move_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): move_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move_dir.x += 1
		
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		rotation = move_dir.angle() + PI / 2
		
		# --- BÍ QUYẾT TRỊ TRƯỢT BĂNG NẰM Ở ĐÂY ---
		# Hàm dot() để soi xem góc bẻ lái có gắt không. 
		# Đi thẳng = 1 | Rẽ vuông góc = 0 | Quay đầu = -1
		var do_lech_huong = velocity.normalized().dot(move_dir)
		var luc_ap_dung = acceleration
		
		# Nếu đang chạy nhanh (> 10) mà bẻ lái lệch đi (dot < 0.9)
		if do_lech_huong < 0.9 and velocity.length() > 10:
			luc_ap_dung = traction # Vứt gia tốc đi, xài lực bám đường bẻ lái ngay lập tức!
			
		velocity = velocity.move_toward(move_dir * max_speed, luc_ap_dung * delta)
		
	else:
		# Khi nhả ga
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()

var mau_hien_tai: int = 100

func bi_tru_mau(luong_sat_thuong: int):
	mau_hien_tai -= luong_sat_thuong
	print("Ối! Shipper vừa bị tông, mất ", luong_sat_thuong, " máu! Còn lại: ", mau_hien_tai)
	
	if mau_hien_tai <= 0:
		print("Game Over!")
		# Sau này ông gọi màn hình Game Over ở đây