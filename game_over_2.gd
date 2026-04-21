extends CanvasLayer

# --- CÁC NODE GIAO DIỆN (Đảm bảo tên Node trong GameOver2.tscn y hệt Scene cũ) ---
@onready var bg_texture = $GiaoDienChinh/TextureRect
@onready var lbl_tien = $LblTien
@onready var highlight_poly = $GiaoDienChinh/HighlightPoly
@onready var busted_overlay = $WastedOverlay # Vẫn để tên cũ hoặc đổi thành BustedOverlay tùy ông
@onready var giao_dien_chinh = $GiaoDienChinh
@onready var man_hinh_xam = $WastedOverlay/ManHinhXam
@onready var chu_gta = $WastedOverlay/ChuWasted

# --- TỪ ĐIỂN MAP NÚT BẤM ---
@onready var buttons_main = {
	$GiaoDienChinh/VBoxContainer/BtnRestart: $GiaoDienChinh/KhuonRestart,
	$GiaoDienChinh/VBoxContainer/BtnQuit: $GiaoDienChinh/KhuonQuit
}

var tween_main: Tween

func _ready():
	# 1. Ẩn khối đa giác lúc ban đầu
	highlight_poly.modulate.a = 0.0
	
	# 2. Gán sự kiện Hover
	for btn in buttons_main:
		var target_khuon = buttons_main[btn]
		btn.mouse_entered.connect(func(): _move_highlight(highlight_poly, target_khuon.polygon))
		btn.mouse_exited.connect(func(): _hide_highlight(highlight_poly))
		
	# 3. Gắn sự kiện click
	$GiaoDienChinh/VBoxContainer/BtnRestart.pressed.connect(_on_btn_choi_lai_pressed)
	$GiaoDienChinh/VBoxContainer/BtnQuit.pressed.connect(_on_btn_thoat_pressed)

# ==========================================
# HÀM SETUP (Gọi từ shipper.gd: bi_bat())
# ==========================================
func setup_cinematic():
	# GIAI ĐOẠN 1: HIỆN BUSTED + XÁM
	giao_dien_chinh.visible = false
	busted_overlay.visible = true
	
	# Thiết lập chữ BUSTED màu xanh cảnh sát
	chu_gta.text = "BUSTED"
	chu_gta.add_theme_color_override("font_color", Color.CYAN)
	
	# Nếu ông có Sprite/TextureRect hiện ảnh nhân vật lúc bị bắt, gán ở đây:
	if bg_texture and anh_bi_bat:
		bg_texture.texture = anh_bi_bat

	# Hiệu ứng Shader xám màn hình
	var shader_mat = man_hinh_xam.material as ShaderMaterial
	var t = create_tween().set_parallel(true)
	if shader_mat:
		t.tween_method(func(val): shader_mat.set_shader_parameter("do_xam", val), 0.0, 1.0, 0.5)
	
	# Hiệu ứng chữ to dần
	chu_gta.scale = Vector2(0.5, 0.5)
	t.tween_property(chu_gta, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUART)
	t.tween_property(chu_gta, "modulate:a", 1.0, 0.3)

func show_final_menu():
	# GIAI ĐOẠN 2: TẮT OVERLAY -> HIỆN MENU
	busted_overlay.visible = false
	giao_dien_chinh.visible = true
	# Hiển thị số tiền kiếm được trước khi bị tóm
	lbl_tien.text = "Tổng thu nhập: " + str(GameManager.money) + " VNĐ"

# ==========================================
# XỬ LÝ NÚT BẤM (Giống hệt bản cũ)
# ==========================================
func _on_btn_choi_lai_pressed():
	get_tree().paused = false
	GameManager.money = 0 
	queue_free()
	get_tree().reload_current_scene()

func _on_btn_thoat_pressed():
	get_tree().quit()

# ==========================================
# HIỆU ỨNG HOVER
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