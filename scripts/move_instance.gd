class_name MoveInstance extends Resource

@export var start_position: Vector2i;
@export var end_position: Vector2i;
@export var is_capture: bool;
@export var is_posession: bool;
@export var is_floating: bool;

func _init(s_pos: Vector2i, e_pos: Vector2i, capture: bool, posession: bool, floating: bool) -> void:
	start_position = s_pos;
	end_position = e_pos;
	is_capture = capture;
	is_posession = posession;
	is_floating = floating;

func get_offset() -> Vector2i:
	return end_position - start_position;
