extends Node

var wanted_level: int = 0
var max_stars: int = 5
var current_player: Node2D = null

# Hàm này sẽ được gọi từ Cột đèn, Người đi đường bị tông, v.v.
func tang_sao_truy_na(so_sao: int, player_node: Node2D):
	current_player = player_node
	wanted_level += so_sao
	
	if wanted_level > max_stars:
		wanted_level = max_stars
		
	print("=== MỨC ĐỘ TRUY NÃ HIỆN TẠI: ", wanted_level, " SAO ===")
	_kich_hoat_canh_sat()

func xoa_truy_na():
	wanted_level = 0
	current_player = null
	print("=== ĐÃ XÓA TRUY NÃ, AN TOÀN! ===")
	# Báo cho toàn bộ cảnh sát quay về trạng thái tuần tra
	get_tree().call_group("CanhSat", "huy_truy_na")

func _kich_hoat_canh_sat():
	# Báo động toàn bộ cảnh sát đang có trên map
	get_tree().call_group("CanhSat", "nhan_lenh_truy_na", current_player, wanted_level)
	
	# Ở Bước 2, ta sẽ code thêm logic Đẻ cảnh sát mới ở đây dựa theo số sao
