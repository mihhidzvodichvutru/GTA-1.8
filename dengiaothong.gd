extends Node2D

enum State {XANH, VANG, DO}
var current_state = State.DO 

@export var xanh_time = 10.0
@export var vang_time = 3.0
@export var do_time = 10.0
@export var do_tre_ban_dau: float = 0.0 

@onready var timer = $Timer
@onready var sprite = $Sprite2D
@onready var label = $Label

func _ready():
	if do_tre_ban_dau > 0:
		current_state = State.DO
		sprite.frame = 2 
		timer.start(do_tre_ban_dau)
	else:
		_chuyen_trang_thai(State.XANH)

func _process(_delta):
	label.text = str(ceil(timer.time_left))
	if current_state == State.XANH: label.modulate = Color.GREEN
	elif current_state == State.VANG: label.modulate = Color.YELLOW
	else: label.modulate = Color.RED

func _chuyen_trang_thai(new_state):
	current_state = new_state
	match current_state:
		State.XANH:
			timer.start(xanh_time)
			sprite.frame = 0 
		State.VANG:
			timer.start(vang_time)
			sprite.frame = 1 
		State.DO:
			timer.start(do_time)
			sprite.frame = 2 

func _on_timer_timeout():
	if current_state == State.XANH: _chuyen_trang_thai(State.VANG)
	elif current_state == State.VANG: _chuyen_trang_thai(State.DO)
	else: _chuyen_trang_thai(State.XANH)

func _on_area_2d_body_entered(body):
	if current_state == State.DO and body.is_in_group("Player"):
		if body.has_method("bi_bat_loi_vuot_den"):
			body.bi_bat_loi_vuot_den()
