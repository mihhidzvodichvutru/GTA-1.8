extends CanvasLayer

@onready var dien_thoai = $DienThoai
@onready var thanh_mau = $DienThoai/VoDienThoai/MarginContainer/ManHinh/ThanhTrangThai/Viettel_6G_Pin/ThanhMau
@onready var man_hinh_mo = $ManHinhMo
@onready var khung_minimap = $CumCoDinh/KhungMinimap
@onready var mission_label = $MissionLabel
@onready var money_popup = $MoneyPopup
@onready var theme_player = $ThemePlayer
@onready var txt_so_du = $DienThoai/VoDienThoai/MarginContainer/ManHinh/ThanhTrangThai/Viettel_6G_Pin/SoDuLabel
@onready var cum_sao = $CumCoDinh/CumSao
var is_phone_open = false
var tween_nhap_nhay: Tween
# Tọa độ Y của điện thoại (Ông tự căn chỉnh số này cho vừa mắt nhé)
var y_mo_full = 100  # Khi mở lên (Điện thoại nằm giữa màn hình)
var y_dong_gap = 600 # Khi giấu xuống (Chỉ thò đúng cái ThanhMau ra)

var shipper: Node2D = null

func _ready():
	_cap_nhat_tien(GameManager.money) # Lấy số dư hiện tại lúc vừa mở game
	GameManager.tien_thay_doi.connect(_cap_nhat_tien) # Lắng nghe biến động số dư
	# --- BẮT BỆNH ĐỒNG BỘ MÁU ---
	# Quét toàn bản đồ tìm thẳng thằng nào có tag "Player"
	shipper = get_tree().get_first_node_in_group("Player")
	if shipper:
		thanh_mau.max_value = 100 
		thanh_mau.value = shipper.mau
		
		# NẾU CÂU LỆNH NÀY CHẠY, THANH MÁU SẼ TỤT!
		if not shipper.mau_thay_doi.is_connected(_cap_nhat_mau):
			shipper.mau_thay_doi.connect(_cap_nhat_mau)
			
		print("📱 Điện thoại đã kết nối với Shipper thành công!")
	else:
		print("📱 LỖI CĂNG: Điện thoại không tìm thấy Shipper trong group Player!")
	# Ép điện thoại nằm ở vị trí gập lúc mới vào game
	dien_thoai.position.y = y_dong_gap
	# Đặt máu tối đa và hiện tại lúc mới mở game
	thanh_mau.max_value = 100
	thanh_mau.value = 100
	man_hinh_mo.material.set_shader_parameter("blur_amount", 0.0)
	man_hinh_mo.visible = false

	# Cập nhật kết nối tín hiệu (thêm tham số dang_lan_tron)
	WantedManager.wanted_level_changed.connect(_on_cap_do_truy_na_thay_doi)
	_on_cap_do_truy_na_thay_doi(0, false)

func _input(event):
	# Nếu bấm phím TAB (Ông nhớ vào Input Map tạo action "ui_tab" gán phím TAB nhé)
	if event.is_action_pressed("ui_tab"):
		_toggle_phone()

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

func run_mission_complete_effect(so_tien: int):
	# 1. Bật nhạc và hiện chữ Mission Passed
	theme_player.play()
	mission_label.visible = true
	mission_label.modulate.a = 0 # Bắt đầu từ tàng hình
	
	# Tween cho chữ Mission Passed hiện ra từ từ
	var t = create_tween()
	t.tween_property(mission_label, "modulate:a", 1.0, 0.1)
	
	# 2. Hiệu ứng tiền bay lên
	money_popup.text = str(so_tien) + "đ +" 
	money_popup.visible = true
	# Đặt vị trí xuất hiện ở giữa màn hình (hoặc chỗ ông muốn)
	money_popup.global_position = get_viewport().get_visible_rect().size / 2
	money_popup.modulate.a = 1.0
	
	var t_money = create_tween().set_parallel(true) # Chạy các hiệu ứng cùng lúc
	# Bay lên trên 100 pixel
	t_money.tween_property(money_popup, "global_position:y", money_popup.global_position.y - 100, 2.0)
	# Mờ dần đi
	t_money.tween_property(money_popup, "modulate:a", 0.0, 2.0)
	
	# 3. Dọn dẹp sau 5 giây
	await get_tree().create_timer(5.0).timeout
	mission_label.visible = false
	money_popup.visible = false
# Hàm nhận tin nhắn biến động Tiền
func _cap_nhat_tien(so_tien: int):
	txt_so_du.text = "Số dư: " + str(so_tien) + " VNĐ"
# Hàm nhận tin nhắn biến động Máu
func _cap_nhat_mau(mau_moi: int):
	# Dùng Tween để thanh máu tụt mượt mà chứ không bị giật cục
	var t = create_tween()
	t.tween_property(thanh_mau, "value", mau_moi, 0.3).set_trans(Tween.TRANS_SINE)

func _on_cap_do_truy_na_thay_doi(level: int, dang_lan_tron: bool):
	var cac_sao = cum_sao.get_children()
	
	# 1. Bật/Tắt các sao
	for i in range(cac_sao.size()):
		if i < level:
			cac_sao[i].modulate = Color(1.0, 0.8, 0.0, 1.0) # Vàng
		else:
			cac_sao[i].modulate = Color(0.2, 0.2, 0.2, 0.5) # Xám mờ

	# 2. Xử lý hiệu ứng Nhấp nháy
	if tween_nhap_nhay:
		tween_nhap_nhay.kill() # Dừng hiệu ứng cũ nếu có

	if dang_lan_tron and level > 0:
		# Tạo Tween chớp tắt toàn bộ cụm sao
		tween_nhap_nhay = create_tween().set_loops()
		tween_nhap_nhay.tween_property(cum_sao, "modulate:a", 0.3, 0.5)
		tween_nhap_nhay.tween_property(cum_sao, "modulate:a", 1.0, 0.5)
	else:
		# Đảm bảo sao sáng lại bình thường nếu bị phát hiện lại hoặc bị xóa
		cum_sao.modulate.a = 1.0
