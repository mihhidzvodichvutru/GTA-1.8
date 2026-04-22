extends CharacterBody2D

@export var max_speed: float = 100    
@export var acceleration: float = 150 
@export var friction: float = 800     
@export var traction: float = 200    
@export var game_over_scene: PackedScene
@export var game_over_scene2: PackedScene
@export var dead_sfx: AudioStream

@onready var sfx_game_over = $SFX_GameOver
var da_chet: bool = false
var mau: int = 100 # Đưa biến máu lên đây cho dễ quản lý

signal mau_thay_doi(mau_hien_tai)

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
		
		# --- HỆ THỐNG PHẠT NGUỘI VÀ TRUY NÃ ---
var tien_mat: int = 500 # Cho Shipper ít tiền khởi nghiệp

func bi_bat_loi_vuot_den():
	print("Shipper: Chết dở, vượt đèn đỏ bị camera quay lại rồi!")
	
	get_tree().paused = true

func bi_bat(ly_do: String = "busted"): 
	if da_chet: return
	da_chet = true
	
	# Ẩn HUD
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud: hud.visible = false

	# --- DEBUG ÂM THANH ---
	if dead_sfx:
		print("🔊 Đang phát âm thanh chết...")
		sfx_game_over.stream = dead_sfx
		sfx_game_over.play()
	else:
		print("⚠️ CẢNH BÁO: Quên chưa gán file âm thanh vào ô Dead Sfx ở Inspector!")

	Engine.time_scale = 0.2
	
	if game_over_scene2:
		var menu = game_over_scene2.instantiate()
		get_tree().root.add_child(menu)
		
		# Bây giờ lệnh này sẽ chạy ngon vì ly_do đã có giá trị mặc định
		menu.setup_cinematic(ly_do) 
	
		await get_tree().create_timer(0.9).timeout
		
		Engine.time_scale = 1.0
		menu.show_final_menu() 
	
	get_tree().paused = true
