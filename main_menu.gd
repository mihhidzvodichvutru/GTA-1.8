extends Control
const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

func save_settings():
	# Lưu âm lượng
	config.set_value("audio", "master_volume", slider_am_luong.value)
	# Lưu chế độ màn hình
	config.set_value("display", "window_mode", opt_display.selected)
	
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK:
		return # Nếu chưa có file (lần đầu mở game) thì bỏ qua
		
	# Đọc giá trị, nếu không thấy thì dùng giá trị mặc định (100 và 0)
	var vol = config.get_value("audio", "master_volume", 100)
	var mode = config.get_value("display", "window_mode", 0)
	
	# Áp dụng lên UI
	slider_am_luong.value = vol
	opt_display.selected = mode
	
	# Gọi các hàm thực thi logic để cập nhật hệ thống
	_on_volume_changed(vol)
	_on_display_mode_selected(mode)

@onready var highlight_poly = $GiaoDienChinh/HighlightPoly # Của Menu Chính
@onready var highlight_cai_dat = $GiaoDienCaiDat/HighlightCaiDat # Của Menu Setting

@onready var giao_dien_chinh = $GiaoDienChinh
@onready var giao_dien_cai_dat = $GiaoDienCaiDat
@onready var khung_nen_cai_dat = $GiaoDienCaiDat/KhungNenCaiDat

# ==========================================
# KHAI BÁO CÁC NÚT VÀ KHUÔN TƯƠNG ỨNG
# ==========================================
@onready var buttons_main = {
	$GiaoDienChinh/VBoxContainer/BtnStart: $GiaoDienChinh/KhuonStart,
	$GiaoDienChinh/VBoxContainer/BtnOptions: $GiaoDienChinh/KhuonOptions,
	$GiaoDienChinh/VBoxContainer/BtnQuit: $GiaoDienChinh/KhuonQuit
}

@onready var buttons_settings = {
	# 1. Nút Quay Lại
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/BtnBack: $GiaoDienCaiDat/KhuonBack,
	
	# 2. Dòng Âm Lượng (Bắt sự kiện hover vào cả cái HBoxContainer chứa chữ và thanh trượt)
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxContainer: $GiaoDienCaiDat/KhuonAmLuong,
	
	# 3. Dòng Hiển Thị
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxDisplay: $GiaoDienCaiDat/KhuonHienThi
}

# Khai báo Nút Màn Hình và Thanh Trượt Âm Lượng
@onready var opt_display = $GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxDisplay/OptDisplay
@onready var slider_am_luong = $GiaoDienCaiDat/MarginContainer/VBoxContainer/HBoxContainer/HSlider

var tween_main: Tween
var tween_settings: Tween

func _ready():
	PauseMenu.can_pause = false
	# Cài đặt tàng hình lúc mới mở
	highlight_poly.modulate.a = 0.0
	highlight_poly.position = Vector2.ZERO 
	
	highlight_cai_dat.modulate.a = 0.0
	highlight_cai_dat.position = Vector2.ZERO 
	
	giao_dien_cai_dat.hide()
	
	# Kết nối hiệu ứng chuột cho Menu Chính
	for btn in buttons_main:
		var target_khuon = buttons_main[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_poly, target_khuon.polygon, "main"))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_poly, "main"))
		
	# Kết nối hiệu ứng chuột cho Menu Setting
	for btn in buttons_settings:
		var target_khuon = buttons_settings[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_cai_dat, target_khuon.polygon, "settings"))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_cai_dat, "settings"))
		
	# Kết nối chức năng click
	$GiaoDienChinh/VBoxContainer/BtnStart.pressed.connect(_on_btn_start_pressed)
	$GiaoDienChinh/VBoxContainer/BtnQuit.pressed.connect(func(): get_tree().quit())
	$GiaoDienChinh/VBoxContainer/BtnOptions.pressed.connect(_on_options_pressed)
	
	# LƯU Ý: Đường dẫn BtnBack lấy chuẩn xác từ ảnh Scene Tree của bạn
	$GiaoDienCaiDat/MarginContainer/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)

	# ==========================================
	# SETUP LOGIC CÀI ĐẶT
	# ==========================================
	
	# --- 1. Cài đặt Hiển thị ---
	opt_display.clear()
	opt_display.add_item("Cửa Sổ")
	opt_display.add_item("Toàn Màn Hình")
	
	# Kiểm tra màn hình hiện tại để hiển thị đúng chữ
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		opt_display.select(1)
	else:
		opt_display.select(0)
		
	opt_display.item_selected.connect(_on_display_mode_selected)

	# --- 2. Cài đặt Âm lượng (Mặc định 100%) ---
	slider_am_luong.min_value = 0
	slider_am_luong.max_value = 100
	slider_am_luong.value = 100 # Default là 100%
	
	# Lắng nghe sự kiện khi người chơi kéo thanh trượt
	slider_am_luong.value_changed.connect(_on_volume_changed)

	load_settings()

# ==========================================
# HÀM LƯỚT HIGHLIGHT CHUNG
# ==========================================
func _move_highlight(hl_node: Polygon2D, target_polygon: PackedVector2Array, type: String):
	var tw = create_tween()
	# Tách biệt 2 hiệu ứng để không đá nhau
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
	# Khóa không cho HighlightPoly tàng hình khi nó đang làm nền cho Settings
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

# ==========================================
# BIẾN HÌNH CHUYỂN MENU (CHỈ DÙNG 1 KHỐI POLY)
# ==========================================
func _on_options_pressed():
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = create_tween()
	tween_main.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# 1. Khối Highlight giãn nở thành kích thước của Bảng Cài Đặt
	tween_main.parallel().tween_property(highlight_poly, "polygon", khung_nen_cai_dat.polygon, 0.6)
	
	# 2. Làm khối Highlight đậm màu lên (1.0) để làm nền 
	tween_main.parallel().tween_property(highlight_poly, "modulate:a", 1.0, 0.6)
	
	# 3. Làm mờ chữ của Menu chính đi
	tween_main.parallel().tween_property(giao_dien_chinh, "modulate:a", 0.0, 0.2)
	
	# 4. Hiện chữ của Menu Cài Đặt lên
	giao_dien_cai_dat.show()
	giao_dien_cai_dat.modulate.a = 0.0
	tween_main.parallel().tween_property(giao_dien_cai_dat, "modulate:a", 1.0, 0.3).set_delay(0.3)
	
	tween_main.tween_callback(giao_dien_chinh.hide)


func _on_back_pressed():
	# Ẩn khối lướt của Setting đi (nếu có)
	_hide_highlight(highlight_cai_dat, "settings")
	
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = create_tween()
	tween_main.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Lấy lại tọa độ khuôn của nút Cài Đặt
	var khuon_options_polygon = buttons_main[$GiaoDienChinh/VBoxContainer/BtnOptions].polygon
	
	# 1. Thu nhỏ Bảng Nền về lại ôm khít chữ CÀI ĐẶT
	tween_main.parallel().tween_property(highlight_poly, "polygon", khuon_options_polygon, 0.6)
	
	# 2. Làm khối Highlight hơi trong suốt lại (0.8) như lúc bình thường
	tween_main.parallel().tween_property(highlight_poly, "modulate:a", 0.8, 0.6)
	
	# 3. Làm mờ chữ Menu cài đặt đi
	tween_main.parallel().tween_property(giao_dien_cai_dat, "modulate:a", 0.0, 0.2)
	
	# 4. Hiện lại chữ của Menu chính
	giao_dien_chinh.show()
	tween_main.parallel().tween_property(giao_dien_chinh, "modulate:a", 1.0, 0.3).set_delay(0.2)
	
	tween_main.tween_callback(giao_dien_cai_dat.hide)

# ==========================================
# CÁC HÀM THỰC THI LOGIC CÀI ĐẶT
# ==========================================

func _on_display_mode_selected(index: int):
	if index == 0: # Cửa sổ
		get_window().mode = Window.MODE_WINDOWED
		get_window().move_to_center()
	else: # Toàn màn hình
		# Dùng call_deferred để tránh lỗi "Embedded window" hoặc bị Windows chặn
		get_window().set_deferred("mode", Window.MODE_EXCLUSIVE_FULLSCREEN)
	
	save_settings()

func _on_volume_changed(value: float):
	# Lấy kênh âm thanh tổng (Master)
	var bus_idx = AudioServer.get_bus_index("Master")
	
	# Nếu kéo về 0 thì tắt tiếng hẳn luôn (Mute)
	if value == 0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		# Đổi từ thang 0-100 sang thang 0.0-1.0, sau đó ép sang Decibel
		var db_volume = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db_volume)
	save_settings()
# ==========================================
# HÀM CHO MAIN MENU GỌI KÉ
# ==========================================
func show_settings_only():
	# Hàm này chỉ dùng khi gọi từ Main Menu, không làm đóng băng game
	visible = true
	giao_dien_chinh.hide()
	giao_dien_cai_dat.show()
	giao_dien_cai_dat.modulate.a = 1.0
	
	highlight_poly.modulate.a = 1.0
	highlight_poly.polygon = khung_nen_cai_dat.polygon
	
	load_settings()
func _on_btn_start_pressed():
	# 1. Chuyển sang bản đồ chính
	get_tree().change_scene_to_file("res://main_map.tscn")
	
	# 2. Đánh thức Tổng đài cảnh sát để rải quân
	WantedManager.reset_he_thong_canh_sat()
