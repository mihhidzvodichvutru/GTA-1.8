extends CanvasLayer

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

@onready var highlight_poly = $GiaoDienChinh/HighlightPoly
@onready var highlight_cai_dat = $GiaoDienCaiDat/HighlightCaiDat

@onready var giao_dien_chinh = $GiaoDienChinh
@onready var giao_dien_cai_dat = $GiaoDienCaiDat
@onready var khung_nen_cai_dat = $GiaoDienCaiDat/KhungNenCaiDat

# Khai báo các nút của Menu Tạm Dừng
@onready var buttons_main = {
	$GiaoDienChinh/VBoxContainer/BtnResume: $GiaoDienChinh/KhuonResume,
	$GiaoDienChinh/VBoxContainer/BtnRestart: $GiaoDienChinh/KhuonRestart,
	$GiaoDienChinh/VBoxContainer/BtnOptions: $GiaoDienChinh/KhuonOptions,
	$GiaoDienChinh/VBoxContainer/BtnQuit: $GiaoDienChinh/KhuonQuit
}

# Khai báo các nút của Menu Cài Đặt (Copied từ Main Menu)
@onready var buttons_settings = {
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/BtnBack: $GiaoDienCaiDat/KhuonBack,
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxContainer: $GiaoDienCaiDat/KhuonAmLuong,
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxDisplay: $GiaoDienCaiDat/KhuonHienThi
}

@onready var opt_display = $GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxDisplay/OptDisplay
@onready var slider_am_luong = $GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxContainer/HSlider

var tween_main: Tween
var tween_settings: Tween
var is_paused: bool = false
var can_pause: bool = false

func _ready():
	# 1. Ẩn menu khi mới vào game
	visible = false
	highlight_poly.modulate.a = 0.0
	highlight_cai_dat.modulate.a = 0.0
	giao_dien_cai_dat.hide()
	
	# 2. Setup Dropdown Màn Hình
	opt_display.clear()
	opt_display.add_item("Cửa Sổ")
	opt_display.add_item("Toàn Màn Hình")
	
	# 3. Kết nối chuột cho Main Pause
	for btn in buttons_main:
		var target_khuon = buttons_main[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_poly, target_khuon.polygon, "main"))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_poly, "main"))
		
	# 4. Kết nối chuột cho Settings
	for btn in buttons_settings:
		var target_khuon = buttons_settings[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_cai_dat, target_khuon.polygon, "settings"))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_cai_dat, "settings"))
		
	# 5. Kết nối chức năng nút bấm
	$GiaoDienChinh/VBoxContainer/BtnResume.pressed.connect(_toggle_pause)
	$GiaoDienChinh/VBoxContainer/BtnRestart.pressed.connect(_restart_game)
	$GiaoDienChinh/VBoxContainer/BtnOptions.pressed.connect(_on_options_pressed)
	$GiaoDienChinh/VBoxContainer/BtnQuit.pressed.connect(func(): get_tree().quit())
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)
	
	# 6. Kết nối Slider và Option
	slider_am_luong.value_changed.connect(_on_volume_changed)
	opt_display.item_selected.connect(_on_display_mode_selected)

# ==========================================
# LOGIC TẠM DỪNG GAME (PAUSE)
# ==========================================
func _input(event):
	if event.is_action_pressed("ui_pause"):
		print("--- Đã nhận lệnh bấm phím ESC ---")
		print("Trạng thái can_pause hiện tại: ", can_pause)
		
		if not can_pause:
			print("Lệnh bị chặn vì can_pause đang là FALSE")
			return
			
		_toggle_pause()
		print("Đã gọi hàm _toggle_pause thành công!")

func _toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		# Reset UI về trang chính mỗi khi ấn ESC
		giao_dien_chinh.show()
		giao_dien_chinh.modulate.a = 1.0
		giao_dien_cai_dat.hide()
		highlight_poly.modulate.a = 0.0
		
		# Load setting mới nhất đề phòng người chơi vừa chỉnh ở Main Menu
		load_settings()

func _restart_game():
	# 1. Gọi lại hàm toggle để nó tự động mở khóa thời gian và giấu cái Menu đi
	_toggle_pause()
	
	# 2. Ép Godot load thẳng file map chính, khỏi cần nhớ current_scene là ai
	get_tree().change_scene_to_file("res://main_map.tscn")

# ==========================================
# LOGIC SAVE / LOAD (Giống Main Menu)
# ==========================================
func save_settings():
	config.set_value("audio", "master_volume", slider_am_luong.value)
	config.set_value("display", "window_mode", opt_display.selected)
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK:
		return 
		
	var vol = config.get_value("audio", "master_volume", 100)
	var mode = config.get_value("display", "window_mode", 0)
	
	slider_am_luong.value = vol
	opt_display.selected = mode
	
	_on_volume_changed(vol)
	
	# Cập nhật hiển thị màn hình (dùng deferred để an toàn)
	if mode == 0:
		get_window().mode = Window.MODE_WINDOWED
	else:
		get_window().set_deferred("mode", Window.MODE_EXCLUSIVE_FULLSCREEN)

# ==========================================
# CÁC HÀM XỬ LÝ SETTING
# ==========================================
func _on_display_mode_selected(index: int):
	if index == 0: 
		get_window().mode = Window.MODE_WINDOWED
		get_window().move_to_center()
	else: 
		get_window().set_deferred("mode", Window.MODE_EXCLUSIVE_FULLSCREEN)
	save_settings()

func _on_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Master")
	if value == 0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db_volume = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db_volume)
	save_settings()

# ==========================================
# BIẾN HÌNH CHUYỂN MENU & HOVER
# ==========================================
func _move_highlight(hl_node: Polygon2D, target_polygon: PackedVector2Array, type: String):
	var tw = create_tween()
	if type == "main":
		if tween_main and tween_main.is_valid(): tween_main.kill()
		tween_main = tw
	else:
		if tween_settings and tween_settings.is_valid(): tween_settings.kill()
		tween_settings = tw
		
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(hl_node, "polygon", target_polygon, 0.3)
	tw.parallel().tween_property(hl_node, "modulate:a", 0.8, 0.3)

func _hide_highlight(hl_node: Polygon2D, type: String):
	if type == "main" and giao_dien_cai_dat.visible:
		return 
		
	var tw = create_tween()
	if type == "main":
		if tween_main and tween_main.is_valid(): tween_main.kill()
		tween_main = tw
	else:
		if tween_settings and tween_settings.is_valid(): tween_settings.kill()
		tween_settings = tw
		
	tw.tween_property(hl_node, "modulate:a", 0.0, 0.2)

func _on_options_pressed():
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = create_tween()
	tween_main.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween_main.parallel().tween_property(highlight_poly, "polygon", khung_nen_cai_dat.polygon, 0.6)
	tween_main.parallel().tween_property(highlight_poly, "modulate:a", 1.0, 0.6)
	tween_main.parallel().tween_property(giao_dien_chinh, "modulate:a", 0.0, 0.2)
	
	giao_dien_cai_dat.show()
	giao_dien_cai_dat.modulate.a = 0.0
	tween_main.parallel().tween_property(giao_dien_cai_dat, "modulate:a", 1.0, 0.3).set_delay(0.3)
	tween_main.tween_callback(giao_dien_chinh.hide)

func _on_back_pressed():
	_hide_highlight(highlight_cai_dat, "settings")
	
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = create_tween()
	tween_main.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	var khuon_options_polygon = buttons_main[$GiaoDienChinh/VBoxContainer/BtnOptions].polygon
	
	tween_main.parallel().tween_property(highlight_poly, "polygon", khuon_options_polygon, 0.6)
	tween_main.parallel().tween_property(highlight_poly, "modulate:a", 0.8, 0.6)
	tween_main.parallel().tween_property(giao_dien_cai_dat, "modulate:a", 0.0, 0.2)
	
	giao_dien_chinh.show()
	tween_main.parallel().tween_property(giao_dien_chinh, "modulate:a", 1.0, 0.3).set_delay(0.2)
	tween_main.tween_callback(giao_dien_cai_dat.hide)
