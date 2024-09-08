class_name DumbEnemyAI extends EnemyAI

@export var move_direction := Vector2i.LEFT;

func get_move() -> MoveInstance:
	if parent.map.is_cell_wall(parent.pos + move_direction):
		parent.on_capture();

	for move in parent.get_legal_moves():
		if move.get_offset() == move_direction:
			return move;

	return null;
