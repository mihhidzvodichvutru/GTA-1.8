extends Node

# Khai báo tín hiệu phát sóng
signal tien_thay_doi(so_tien_moi) 

var money: int = 0

func cong_tien(so_tien: int):
	money += so_tien
	tien_thay_doi.emit(money) # Bắn tín hiệu kèm số tiền mới nhất
	print("💰 Tài khoản hiện tại: ", money)