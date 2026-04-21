extends CharacterBody2D

@export var max_speed: float = 100    
@export var acceleration: float = 150 
@export var friction: float = 800     
@export var traction: float = 200    
@export var game_over_scene: PackedScene # <--- Ô NÀY SẼ HIỆN TRÊN INSPECTOR
@export var dead_sfx: AudioStream


@onready var hinh_bi_bat = $HinhBiBat
@onready var sfx_game_over = $SFX_GameOver
var da_chet: bool = false
var mau: int = 100 # Đưa biến máu lên đây cho dễ quản lý

signal mau_thay_doi(mau_hien_tai)

func _physics_process(delta):
	if da_chet: return # Nếu chết rồi thì không cho lái xe nữa
	
	var move_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): move_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): move_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): move_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move_dir.x += 1
		
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		rotation = move_dir.angle() + PI / 2
		var do_lech_huong = velocity.normalized().dot(move_dir)
		var luc_ap_dung = acceleration
		
		if do_lech_huong < 0.9 and velocity.length() > 10:
			luc_ap_dung = traction 
			
		velocity = velocity.move_toward(move_dir * max_speed, luc_ap_dung * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()

# --- HÀM TRỪ MÁU (FIXED) ---
func bi_tru_mau(sat_thuong: int):
	if da_chet: return # Đã chết rồi thì không trừ thêm nữa
	
	mau -= sat_thuong
	if mau < 0: mau = 0
	
	mau_thay_doi.emit(mau)
	print("🩸 Máu hiện tại: ", mau)
	
	if mau <= 0:
		print("💀 Kích hoạt trạng thái Wasted!")
		chet("wasted") # <--- PHẢI CÓ DÒNG NÀY THÌ MENU MỚI HIỆN!

# --- HÀM XỬ LÝ GAME OVER (CINEMATIC) ---
func chet(ly_do: String):
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
	
	if game_over_scene:
		var menu = game_over_scene.instantiate()
		get_tree().root.add_child(menu)
		menu.setup_cinematic(ly_do) 
	
		await get_tree().create_timer(0.9).timeout 
		
		Engine.time_scale = 1.0
		menu.show_final_menu() 
	
	get_tree().paused = true
