extends CanvasLayer

# --- CÁC NODE GIAO DIỆN ---
@onready var bg_texture = $GiaoDienChinh/TextureRect
@onready var lbl_tien = $LblTien
@onready var highlight_poly = $GiaoDienChinh/HighlightPoly
@onready var wasted_overlay = $WastedOverlay
@onready var giao_dien_chinh = $GiaoDienChinh
@onready var man_hinh_xam = $WastedOverlay/ManHinhXam
@onready var chu_gta = $WastedOverlay/ChuWasted

# --- BIẾN CHỨA ẢNH TỪ NGOÀI VÀO ---
@export var anh_tai_nan: Texture2D 
@export var anh_bi_bat: Texture2D

# --- TỪ ĐIỂN MAP NÚT BẤM VÀ KHUÔN ĐA GIÁC ---
@onready var buttons_main = {
	$GiaoDienChinh/VBoxContainer/BtnRestart: $GiaoDienChinh/KhuonRestart,
	$GiaoDienChinh/VBoxContainer/BtnQuit: $GiaoDienChinh/KhuonQuit
}

var tween_main: Tween

func _ready():
	# 1. Ẩn khối đa giác lúc ban đầu
	highlight_poly.modulate.a = 0.0
	
	# 2. Lặp qua các nút để gắn sự kiện di chuột (Hover)
	for btn in buttons_main:
		var target_khuon = buttons_main[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_poly, target_khuon.polygon))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_poly))
		
	# 3. Gắn sự kiện click
	$GiaoDienChinh/VBoxContainer/BtnRestart.pressed.connect(_on_btn_choi_lai_pressed)
	$GiaoDienChinh/VBoxContainer/BtnQuit.pressed.connect(_on_btn_thoat_pressed)

# ==========================================
# HÀM SETUP (Được gọi từ shipper.gd khi chết)
# ==========================================
func setup_cinematic(ly_do: String):
	# GIAI ĐOẠN 1: HIỆN WASTED + XÁM
	giao_dien_chinh.visible = false
	wasted_overlay.visible = true
	
	if ly_do == "wasted":
		chu_gta.text = "WASTED"
		chu_gta.add_theme_color_override("font_color", Color.DARK_RED)
	else:
		chu_gta.text = "BUSTED"
		chu_gta.add_theme_color_override("font_color", Color.BLUE)

	# Hiệu ứng Shader và Chữ (giống như cũ nhưng chỉ chạy cho Overlay)
	var shader_mat = man_hinh_xam.material as ShaderMaterial
	var t = create_tween().set_parallel(true)
	t.tween_method(func(val): shader_mat.set_shader_parameter("do_xam", val), 0.0, 1.0, 0.5)
	
	chu_gta.scale = Vector2(0.5, 0.5)
	t.tween_property(chu_gta, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUART)
	t.tween_property(chu_gta, "modulate:a", 1.0, 0.3)

func show_final_menu():
	# GIAI ĐOẠN 2: TẮT WASTED -> HIỆN MENU CHÍNH
	wasted_overlay.visible = false
	giao_dien_chinh.visible = true
	# Cập nhật tiền
	lbl_tien.text = "Tổng thu nhập: " + str(GameManager.money) + " VNĐ"

# ==========================================
# XỬ LÝ CHỨC NĂNG NÚT
# ==========================================
func _on_btn_choi_lai_pressed():
	# 1. Quan trọng: Mở đóng băng game trước
	get_tree().paused = false
	
	# 2. Reset tiền
	GameManager.money = 0 
	
	# 3. Xóa chính cái Menu này đi để nó không đè lên Map mới
	queue_free()
	
	# 4. Load lại Scene. 
	# Dùng reload_current_scene() sẽ an toàn và nhanh hơn nếu ông đang ở MainMap
	get_tree().reload_current_scene()

func _on_btn_thoat_pressed():
	get_tree().quit()

# ==========================================
# HIỆU ỨNG HOVER ĐA GIÁC (Tối ưu từ Pause Menu)
# ==========================================
func _move_highlight(hl_node: Polygon2D, target_polygon: PackedVector2Array):
	var tw = create_tween()
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = tw
	
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(hl_node, "polygon", target_polygon, 0.3)
	tw.parallel().tween_property(hl_node, "modulate:a", 0.8, 0.3)

func _hide_highlight(hl_node: Polygon2D):
	var tw = create_tween()
	if tween_main and tween_main.is_valid(): tween_main.kill()
	tween_main = tw
	
	tw.tween_property(hl_node, "modulate:a", 0.0, 0.2)
