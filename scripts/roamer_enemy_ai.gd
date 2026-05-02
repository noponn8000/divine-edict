class_name RoamerEnemyAI extends EnemyAI

@export var initial_dir := Vector2i.RIGHT;
@export var full_rotation_on_wall := true;
var move_direction := Vector2i.RIGHT;

func get_move() -> MoveInstance:
	if parent.map.is_cell_wall(parent.pos + move_direction):
		if full_rotation_on_wall:
			move_direction = -move_direction;
		else:
			match move_direction:
				Vector2i.RIGHT: move_direction = Vector2i.DOWN;
				Vector2i.DOWN: move_direction = Vector2i.LEFT;
				Vector2i.LEFT: move_direction = Vector2i.UP;
				Vector2i.UP: move_direction = Vector2i.RIGHT;
	for move in parent.get_legal_moves():
		if move.get_offset() == move_direction:
			return move;

	return null;
