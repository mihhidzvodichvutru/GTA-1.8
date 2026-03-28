extends Node2D

# Kéo thả node TileMapLayer của bạn vào biến này
@onready var tile_map: TileMapLayer = $TileMapLayer 
var astar_grid: AStarGrid2D

func _ready():
	setup_astar_grid()

func setup_astar_grid():
	astar_grid = AStarGrid2D.new()
	
	# 1. Tự động lấy vùng biên (Bounding Box) của tất cả các viên gạch bạn đã vẽ
	var map_rect = tile_map.get_used_rect()
	astar_grid.region = map_rect
	
	# Đặt kích thước ô lưới trùng với kích thước Tile bạn chọn (Ví dụ: 16x16)
	astar_grid.cell_size = Vector2(16, 16) 
	
	# Cho phép đi chéo (đỡ bị zíc zắc) nhưng không được đi chéo xuyên qua góc tường
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	
	# 2. Vòng lặp quét qua từng ô trong bản đồ
	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			var cell_pos = Vector2i(x, y)
			
			# Lấy ID của viên gạch tại vị trí này. 
			# Nếu ID khác -1 (tức là có gạch / có nhà / có tường)
			if tile_map.get_cell_source_id(cell_pos) != -1:
				# Báo cho AI biết ô này là vật cản cứng, không thể đi qua
				astar_grid.set_point_solid(cell_pos, true)
				
	print("Đã khởi tạo xong lưới A*! Kích thước: ", map_rect.size)

# Hàm này dùng để test: Truyền vào tọa độ lưới điểm A và B, nó sẽ trả về mảng đường đi
func get_path_on_grid(start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	if astar_grid.is_in_boundsv(start_cell) and astar_grid.is_in_boundsv(target_cell):
		return astar_grid.get_id_path(start_cell, target_cell)
	return []