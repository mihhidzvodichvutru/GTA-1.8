extends CanvasLayer

@onready var dien_thoai = $DienThoai
@onready var thanh_mau = $DienThoai/VoDienThoai/MarginContainer/ManHinh/ThanhTrangThai/Viettel_6G_Pin/ThanhMau
@onready var man_hinh_mo = $ManHinhMo
@onready var khung_minimap = $CumCoDinh/KhungMinimap
var is_phone_open = false

# Tọa độ Y của điện thoại (Ông tự căn chỉnh số này cho vừa mắt nhé)
var y_mo_full = 100  # Khi mở lên (Điện thoại nằm giữa màn hình)
var y_dong_gap = 600 # Khi giấu xuống (Chỉ thò đúng cái ThanhMau ra)

func _ready():
	# Ép điện thoại nằm ở vị trí gập lúc mới vào game
	dien_thoai.position.y = y_dong_gap
	# Đặt máu tối đa và hiện tại lúc mới mở game
	thanh_mau.max_value = 100
	thanh_mau.value = 100
	man_hinh_mo.material.set_shader_parameter("blur_amount", 0.0)
	man_hinh_mo.visible = false

func _input(event):
	# Nếu bấm phím TAB (Ông nhớ vào Input Map tạo action "ui_tab" gán phím TAB nhé)
	if event.is_action_pressed("ui_tab"):
		_toggle_phone()
	# Dùng phím Space để test (phím ui_accept mặc định của Godot)
	if event.is_action_pressed("ui_accept"):
		_nhan_sat_thuong(15) # Mỗi lần ấn Space bị trừ 15 máu

func _toggle_phone():
	is_phone_open = !is_phone_open
	var target_y = y_mo_full if is_phone_open else y_dong_gap
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(dien_thoai, "position:y", target_y, 0.4)
	
	if is_phone_open:
		khung_minimap.visible = false
		man_hinh_mo.visible = true
		# Tăng dần độ mờ của Shader lên 2.5
		tw.tween_property(man_hinh_mo.material, "shader_parameter/blur_amount", 2.5, 0.4) 
	else:
		khung_minimap.visible = true
		# Giảm độ mờ về 0, xong xuôi thì tắt Node đi
		tw.tween_property(man_hinh_mo.material, "shader_parameter/blur_amount", 0.0, 0.4).finished.connect(func(): man_hinh_mo.visible = false)

# Hàm này là Ổ CẮM chờ sẵn để bạn ông gọi sau này
func _nhan_sat_thuong(luong_sat_thuong: float):
	var mau_con_lai = thanh_mau.value - luong_sat_thuong
	if mau_con_lai < 0:
		mau_con_lai = 0
		
	# Dùng Tween để tạo hiệu ứng máu tụt dần xuống thay vì giật cục
	var tw = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(thanh_mau, "value", mau_con_lai, 0.3)
