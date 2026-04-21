extends Node

signal wanted_level_changed(level, dang_lan_tron)

var wanted_level: int = 0
var max_stars: int = 5
var police_scene: PackedScene

func _ready():
	police_scene = preload("res://police.tscn") 
	# Thả tất cả cảnh sát ra chốt lúc vừa vào game
	call_deferred("tha_canh_sat_ra_chot")

func tha_canh_sat_ra_chot():
	var root_node = get_tree().current_scene
	var spawn_points = get_tree().get_nodes_in_group("PoliceSpawn")
	
	for point in spawn_points:
		var cop = police_scene.instantiate()
		cop.add_to_group("Police") 
		cop.global_position = point.global_position
		root_node.add_child(cop)
	print("🚓 Đã rải xong toàn bộ cảnh sát lên bản đồ!")

func tang_sao():
	if wanted_level < max_stars:
		wanted_level += 1
		wanted_level_changed.emit(wanted_level, false)
		
	dieu_phoi_truy_duoi()

func xoa_het_sao():
	wanted_level = 0
	wanted_level_changed.emit(0, false)
	dieu_phoi_truy_duoi() # Gọi hàm này để báo cảnh sát quay về

func dieu_phoi_truy_duoi():
	var cops = get_tree().get_nodes_in_group("Police")
	var player = get_tree().get_first_node_in_group("Player")
	if not player or cops.is_empty(): return
	
	# Sắp xếp danh sách cảnh sát từ GẦN nhất đến XA nhất
	cops.sort_custom(func(a, b):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	
	# Chỉ định: N xe gần nhất sẽ đuổi, số còn lại quay về đi tuần
	for i in range(cops.size()):
		if i < wanted_level:
			cops[i].trang_thai = "CHASE"
		else:
			cops[i].trang_thai = "PATROL"
