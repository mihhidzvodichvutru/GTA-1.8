extends Node2D

# ==========================================
# PHẦN 1: CÁC BIẾN CỦA HỆ THỐNG
# ==========================================
@onready var tile_map: TileMapLayer = $NavigationRegion2D/TileMapLayer
var astar_grid: AStarGrid2D

# Nếu bạn chưa làm kịp giao diện hội thoại (DialogueUI), 
# hãy tạm thời để biến này thành comment (thêm dấu # ở đầu) để tránh lỗi đỏ
# @onready var dialogue_ui = $DialogueUI 

# ==========================================
# PHẦN 2: KHỞI CHẠY KHI MỞ MAP
# ==========================================
func _ready():
	PauseMenu.can_pause = true
	# 1. Chạy thuật toán quét bản đồ A*
	setup_astar_grid()
	
	# 2. Tự động tìm tất cả các Area2D chặn rìa map và bật cảm biến va chạm
	for child in get_children():
		if child is Area2D and child.name.begins_with("Boundary"):
			# Kết nối tín hiệu body_entered vào hàm xử lý bên dưới
			child.body_entered.connect(_on_boundary_entered)

# ==========================================
# PHẦN 3: LOGIC CHẠM RÌA MAP (SHIIPER VÀ NPC)
# ==========================================
func _on_boundary_entered(body: Node2D):
	# Kiểm tra xem ai vừa đi vào rìa map
	if body.name == "Shipper": 
		trigger_boundary_turn_around(body)
		
	elif body.is_in_group("NPC"):
		# Xóa sổ NPC (Cảnh sát, Boy phố) khỏi bộ nhớ máy tính
		body.queue_free()
		print("Đã xóa 1 NPC đi quá giới hạn bản đồ!")

func trigger_boundary_turn_around(shipper_node: Node2D):
	print("Shipper đã chạm rìa map! Đang xử lý quay đầu...")
	
	# 1. Khóa điều khiển (Kiểm tra xem file code của bạn kia đã có biến này chưa)
	if "is_input_locked" in shipper_node:
		shipper_node.is_input_locked = true
	
	# 2. Hiển thị UI hội thoại (Nếu đã làm UI thì bỏ dấu # đi)
	# dialogue_ui.show_dialogue("hmm, mình chưa thể rời khỏi khu vực giao hàng")
	
	# 3. Đợi 1.5 giây
	await get_tree().create_timer(1.5).timeout
	
	# 4. Quay đầu xe 180 độ (PI = 180 độ trong GDScript)
	shipper_node.rotation += PI 
	
	# 5. Tắt UI và mở lại điều khiển
	# dialogue_ui.hide_dialogue()
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
