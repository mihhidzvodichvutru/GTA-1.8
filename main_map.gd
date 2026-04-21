extends Node2D

# ==========================================
# PHẦN 1: CÁC BIẾN CỦA HỆ THỐNG
# ==========================================
@onready var tile_map: TileMapLayer = $NavigationRegion2D/TileMapLayer
@onready var hud = $HUD
@onready var shipper = $Shipper
@onready var minimap_camera = $HUD/CumCoDinh/KhungMinimap/Minimap/Minimap/Camera2D
@onready var minimap_viewport = $HUD/CumCoDinh/KhungMinimap/Minimap/Minimap

@onready var model_goc_shipper = $Shipper/ModelShipper 
@onready var icon_mui_ten = $Shipper/MuiTenIcon

@onready var google_map_viewport = $HUD/DienThoai/VoDienThoai/MarginContainer/ManHinh/ThanhTrangThai/Viettel_6G_Pin/GoogleMapContainer/SubViewport
@onready var camera_google_map = $HUD/DienThoai/VoDienThoai/MarginContainer/ManHinh/ThanhTrangThai/Viettel_6G_Pin/GoogleMapContainer/SubViewport/CameraGoogleMap

@export var boy_pho_scene: PackedScene 
@export var so_luong_toi_da: int = 15 # Tránh spam hàng trăm con gây lag máy

@onready var vet_gps: Line2D = $VetGPS
@onready var tap_hop_diem_giao = $CacDiemGiaoHang.get_children() 
var diem_giao_hien_tai: Node2D = null

@onready var mui_ten_la_ban: Sprite2D = $MuiTenLaBan

var dang_o_trong_vung: bool = false

var astar_grid: AStarGrid2D

# Nếu bạn chưa làm kịp giao diện hội thoại (DialogueUI), 
# hãy tạm thời để biến này thành comment (thêm dấu # ở đầu) để tránh lỗi đỏ
# @onready var dialogue_ui = $DialogueUI 

# Ngưỡng Zoom để đổi icon. Nếu Zoom < 1 thì sẽ đổi sang mũi tên.
const NGUONG_DO_ICON = 1

var toc_do_toi_da = 100.0

func _process(delta):
	if shipper:
		# Cập nhật vị trí cho cả 2 camera bản đồ
		if minimap_camera:
			minimap_camera.global_position = shipper.global_position
		
		# 2. Tính toán Dynamic Zoom dựa trên Tốc Độ (Velocity)
		var toc_do_hien_tai = shipper.velocity.length()
		var ty_le_toc_do = clamp(toc_do_hien_tai / toc_do_toi_da, 0.0, 1.0)
		
		# Đứng im -> Zoom = 1.0 (Gần) | Phóng max tốc -> Zoom = 0.3 (Xa)
		var zoom_muc_tieu = lerp(1.0, 0.3, ty_le_toc_do)
		
		# 3. Xác định độ nhạy (Asymmetric Lerp)
		var zoom_hien_tai = minimap_camera.zoom.x
		var do_nhay_zoom = 0.0
		
		if zoom_muc_tieu < zoom_hien_tai:
			do_nhay_zoom = 1.5  # Thốc ga -> Zoom xa nhanh vừa
		else:
			do_nhay_zoom = 0.3  # Phanh/Lạng lách -> Zoom gần RẤT CHẬM
			
		# 4. Tính toán Zoom mượt mà
		var zoom_muot_ma = lerp(zoom_hien_tai, zoom_muc_tieu, do_nhay_zoom * delta)
		minimap_camera.zoom = Vector2(zoom_muot_ma, zoom_muot_ma)
		
		# --- BẢN SỬA LỖI: KHÔNG ẨN MODEL GỐC NỮA ---
		# Ta chỉ cần bật/tắt mũi tên trong Minimap (nó sẽ tự đè lên model gốc)
		if zoom_muot_ma < NGUONG_DO_ICON:
			icon_mui_ten.visible = true
		else:
			icon_mui_ten.visible = false
			
		if camera_google_map:
			camera_google_map.global_position = shipper.global_position
			# Không cần set zoom ở đây nữa vì đã set cố định trong _ready rồi
	# --- BỔ SUNG LA BÀN CHỈ ĐƯỜNG CHIM BAY ---
	if shipper and diem_giao_hien_tai and mui_ten_la_ban:
		mui_ten_la_ban.visible = true
		
		# 1. Tính toán HƯỚNG từ xe Shipper đến nhà khách hàng (Trả về Vector chuẩn hóa)
		var huong_chi = shipper.global_position.direction_to(diem_giao_hien_tai.global_position)
		
		# 2. Đẩy mũi tên ra xa tâm Shipper đúng 150 pixel theo cái hướng vừa tính
		var khoang_cach_quy_dao = 150.0 # Ông có thể tăng giảm số này cho vừa mắt
		mui_ten_la_ban.global_position = shipper.global_position + (huong_chi * khoang_cach_quy_dao)
		
		# 3. Xoay góc của mũi tên cho khớp với hướng bay
		mui_ten_la_ban.rotation = huong_chi.angle()
		
	elif mui_ten_la_ban:
		mui_ten_la_ban.visible = false

			

# ==========================================
# PHẦN 2: KHỞI CHẠY KHI MỞ MAP
# ==========================================
func _ready():
	PauseMenu.can_pause = true
	setup_astar_grid()
	
	for child in get_children():
		if child is Area2D and child.name.begins_with("Boundary"):
			child.body_entered.connect(_on_boundary_entered)
	
	# 1. MÀN HÌNH CHÍNH: Mask 3 (Layer 1 + 2) -> Vẫn tàng hình icon điểm đến
	get_viewport().canvas_cull_mask = 3 

	# 2. MINIMAP: Thấy Map(1), Shipper(4), Kẻ địch(8) và cả Điểm đến(32)
	# Giá trị: 1 + 4 + 8 + 32 = 45
	if minimap_viewport:
		minimap_viewport.world_2d = get_viewport().world_2d
		minimap_viewport.canvas_cull_mask = 45

	# 3. GOOGLE MAP: Thấy Map(1), Shipper(4), GPS(16) và Điểm đến(32)
	# Giá trị: 1 + 4 + 16 + 32 = 53
	if google_map_viewport:
		google_map_viewport.world_2d = get_viewport().world_2d
		google_map_viewport.canvas_cull_mask = 53 # Đổi từ 21 thành 53

		if camera_google_map:
			camera_google_map.zoom = Vector2(0.3, 0.3)
		
	# Đảm bảo mũi tên bị ẩn lúc mới vào game
	if icon_mui_ten:
		icon_mui_ten.visible = false
	var camera_shipper = $Shipper/Camera2D2
	if camera_shipper:
		camera_shipper.make_current()
	_khoi_dong_spawner()

	chon_diem_giao_moi() # Random đơn hàng đầu tiên
	
	var gps_timer = Timer.new()
	gps_timer.wait_time = 0.1
	gps_timer.autostart = true
	gps_timer.timeout.connect(_cap_nhat_vet_gps)
	add_child(gps_timer)

	for diem in tap_hop_diem_giao:
		var vung = diem.get_node("VungGiaoHang") 
		if vung:
			if not vung.body_entered.is_connected(_on_vung_giao_hang_body_entered):
				# Bơm thẳng dữ liệu 'diem' (Ngôi nhà) vào tín hiệu
				vung.body_entered.connect(_on_vung_giao_hang_body_entered.bind(diem))
				
			if not vung.body_exited.is_connected(_on_vung_giao_hang_body_exited):
				vung.body_exited.connect(_on_vung_giao_hang_body_exited.bind(diem))
				
	chon_diem_giao_moi()

func _khoi_dong_spawner():
	await get_tree().physics_frame # Chờ mảng xanh load xong
	while true:
		# Giảm thời gian chờ xuống 0.5s hoặc 1s để ra quái liên tục chặn đầu
		await get_tree().create_timer(1.0).timeout 
		
		var hien_tai = get_tree().get_nodes_in_group("Enemy").size()
		if hien_tai < so_luong_toi_da:
			_thu_spawn_boy_pho()

# ==========================================
# PHẦN 3: LOGIC CHẠM RÌA MAP (SHIIPER VÀ NPC)
# ==========================================
func _on_boundary_entered(body: Node2D):
	if body.name == "Shipper": 
		trigger_boundary_turn_around(body)
		
	elif body.is_in_group("NPC"):
		body.queue_free()
		print("Đã xóa 1 NPC đi quá giới hạn bản đồ!")

func trigger_boundary_turn_around(shipper_node: Node2D):
	print("Shipper đã chạm rìa map! Đang xử lý quay đầu...")
	
	if "is_input_locked" in shipper_node:
		shipper_node.is_input_locked = true
	
	await get_tree().create_timer(1.5).timeout
	
	shipper_node.rotation += PI 
	
	if "is_input_locked" in shipper_node:
		shipper_node.is_input_locked = false

# ==========================================
# PHẦN 4: LOGIC TÌM ĐƯỜNG A* CŨ (GIỮ NGUYÊN)
# ==========================================
func setup_astar_grid():
	astar_grid = AStarGrid2D.new()
	var map_rect = tile_map.get_used_rect()
	astar_grid.region = map_rect
	astar_grid.cell_size = Vector2(16, 16) 
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	
	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			var cell_pos = Vector2i(x, y)
			if tile_map.get_cell_source_id(cell_pos) != -1:
				astar_grid.set_point_solid(cell_pos, true)
				
	print("Đã khởi tạo xong lưới A*! Kích thước: ", map_rect.size)

func get_path_on_grid(start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	if astar_grid.is_in_boundsv(start_cell) and astar_grid.is_in_boundsv(target_cell):
		return astar_grid.get_id_path(start_cell, target_cell)
	return []

func _thu_spawn_boy_pho():
	if not shipper or not boy_pho_scene: return

	var khoang_cach_min = 1000.0 
	var khoang_cach_max = 2000.0

	var map_rid = get_world_2d().navigation_map

	for i in range(15): 
		var goc = randf() * PI * 2
		var ban_kinh = randf_range(khoang_cach_min, khoang_cach_max)
		var toa_do_random = shipper.global_position + Vector2(cos(goc), sin(goc)) * ban_kinh

		var diem_tren_duong = NavigationServer2D.map_get_closest_point(map_rid, toa_do_random)
		var khoang_cach_thuc_te = shipper.global_position.distance_to(diem_tren_duong)

		if khoang_cach_thuc_te >= 800.0:
			var boy = boy_pho_scene.instantiate()
			
			# 1. BẮT BUỘC: Thêm vào thế giới game TRƯỚC để Godot chịu tính toán vật lý
			add_child(boy) 
			boy.global_position = diem_tren_duong 
			
			# 2. BÂY GIỜ MỚI TEST VA CHẠM
			if not boy.test_move(boy.global_transform, Vector2.ZERO):
				# Chỗ này thoáng -> Giữ lại!
				print(">>> Thả thành công (Không kẹt tường) tại: ", diem_tren_duong)
				return 
			else:
				# Chỗ này kẹt tường -> Xóa sổ cái xác này ngay lập tức!
				boy.free()

# 1. Xử lý lúc có đơn mới: Ép NPC hiện frame 0
func chon_diem_giao_moi():
	# 1. QUYÉT DỌN: Ẩn TOÀN BỘ Icon bản đồ và NPC của tất cả các nhà
	for diem in tap_hop_diem_giao:
		# Ẩn Icon giọt nước trên Google Map (Layer 6)
		# Giả sử ông đặt tên nó là "IconBanDo" hoặc dùng get_child(0)
		var icon_ban_do = diem.get_node_or_null("IconBanDo") 
		if icon_ban_do:
			icon_ban_do.visible = false
		
		# Ẩn luôn NPC trên màn hình chính (Layer 2)
		var npc = diem.get_node_or_null("NguoiNhan")
		if npc:
			npc.visible = false

	# 2. KÍCH HOẠT: Chỉ hiện điểm được chọn ngẫu nhiên
	if tap_hop_diem_giao.size() > 0:
		diem_giao_hien_tai = tap_hop_diem_giao.pick_random()
		
		print("📦 ĐƠN HÀNG MỚI: ", diem_giao_hien_tai.name)
		
		# Hiện Icon giọt nước của NHÀ NÀY trên Google Map
		var icon_muc_tieu = diem_giao_hien_tai.get_node_or_null("IconBanDo")
		if icon_muc_tieu:
			icon_muc_tieu.visible = true
			
		# Hiện NPC của NHÀ NÀY trên màn hình chính
		var npc_muc_tieu = diem_giao_hien_tai.get_node_or_null("NguoiNhan")
		if npc_muc_tieu:
			npc_muc_tieu.frame = 0 # Trạng thái chờ
			npc_muc_tieu.visible = true
		
		_cap_nhat_vet_gps()

func _cap_nhat_vet_gps():
	if not shipper or not diem_giao_hien_tai: 
		vet_gps.points = []
		return
		
	var start_pos = shipper.global_position
	var target_pos = diem_giao_hien_tai.global_position
	var map_rid = get_world_2d().navigation_map
	
	# Tính toán đường đi
	var duong_di = NavigationServer2D.map_get_path(map_rid, start_pos, target_pos, true)
	
	# Bơm dữ liệu vào đường Line2D
	if duong_di.size() > 0:
		vet_gps.points = duong_di
	else:
		# FALLBACK: Nếu mảng xanh bị đứt hoàn toàn không nối được, 
		# vẽ một đường thẳng tắp từ xe đến thẳng nhà khách hàng (đường chim bay)
		vet_gps.points = [start_pos, target_pos]

func _input(event):
	# Kiểm tra nếu nhấn phím F khi đang ở đúng điểm giao
	if event.is_action_pressed("phim_f") and dang_o_trong_vung:
		_hoan_thanh_giao_hang()
# 2. Xử lý lúc bấm F xong: Lật sang frame 1
func _hoan_thanh_giao_hang():
	print("✔ Giao hàng thành công!")
	if hud:
		hud.run_mission_complete_effect(50000)
	dang_o_trong_vung = false

	GameManager.cong_tien(50000)
	# Ẩn ngay cái Icon trên bản đồ điện thoại
	var icon_vua_giao = diem_giao_hien_tai.get_node_or_null("IconBanDo")
	if icon_vua_giao:
		icon_vua_giao.visible = false
		
	# NPC đổi ảnh nhận hàng nhưng vẫn hiện thêm 10s
	var npc_vua_giao = diem_giao_hien_tai.get_node_or_null("NguoiNhan")
	if npc_vua_giao:
		npc_vua_giao.frame = 1 
		get_tree().create_timer(10.0).timeout.connect(func(): npc_vua_giao.visible = false)
	
	vet_gps.points = []
	diem_giao_hien_tai = null 
	
	await get_tree().create_timer(2.0).timeout
	chon_diem_giao_moi()

	

# --- TÍN HIỆU TỪ AREA2D ---
# THÊM THAM SỐ 'nha_cua_vung_nay' VÀO ĐÂY:
func _on_vung_giao_hang_body_entered(body, nha_cua_vung_nay):
	# Nếu đúng là xe Shipper VÀ nhà vừa chạm vào chính là điểm đang cần giao
	if body.is_in_group("Player") and diem_giao_hien_tai == nha_cua_vung_nay:
		dang_o_trong_vung = true
		print("Ấn F để giao hàng!")

func _on_vung_giao_hang_body_exited(body, nha_cua_vung_nay):
	if body.is_in_group("Player") and diem_giao_hien_tai == nha_cua_vung_nay:
		dang_o_trong_vung = false
