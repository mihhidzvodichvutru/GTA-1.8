extends Control

@onready var highlight_poly = $HighlightPoly
@onready var buttons = {
	$VBoxContainer/BtnStart: $KhuonStart,
	$VBoxContainer/BtnOptions: $KhuonOptions,
	$VBoxContainer/BtnQuit: $KhuonQuit
}

var current_tween: Tween

func _ready():
	# 1. Ẩn khối highlight lúc đầu
	highlight_poly.modulate.a = 0.0
	# Đảm bảo HighlightPoly ở gốc tọa độ
	highlight_poly.position = Vector2.ZERO 
	
	# 2. Dùng vòng lặp kết nối cho sạch code
	for btn in buttons:
		var target_khuon = buttons[btn]
		btn.mouse_entered.connect(func(): _move_highlight(target_khuon.polygon))
		btn.mouse_exited.connect(_hide_highlight)
		
	# 3. Kết nối chức năng bấm
	$VBoxContainer/BtnStart.pressed.connect(func(): get_tree().change_scene_to_file("res://main_map.tscn"))
	$VBoxContainer/BtnQuit.pressed.connect(func(): get_tree().quit())

func _move_highlight(target_polygon: PackedVector2Array):
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Chỉ tween mảng điểm và độ trong suốt
	current_tween.parallel().tween_property(highlight_poly, "polygon", target_polygon, 0.3)
	current_tween.parallel().tween_property(highlight_poly, "modulate:a", 1.0, 0.3)

func _hide_highlight():
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(highlight_poly, "modulate:a", 0.0, 0.2)