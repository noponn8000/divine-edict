class_name Entity extends Sprite2D

@export_category("Movement")
@export var moves: Array[Move];
@export var possession_range := 3;

@export_category("Visuals")
@export var animate := true;
@export var tile_by_tile := false;

@export_category("References")
@export var map: Map = owner;

@export_category("Gameplay")
@export var is_player := false;
@export var is_king := false;
@export var is_ai_controlled := false;
@export var ai: EnemyAI;

var pos: Vector2i:
	set(new_pos):  set_pos(new_pos); pos = new_pos;

signal entity_moved(Entity);
signal entity_captured(Entity);
signal entity_possessed(Entity);

func _ready() -> void:
	pos = position / map.cell_size;
	if is_player:
		map.player = self;
	if is_king:
		map.king = self;

func move(move: MoveInstance) -> bool:
	if move.is_capture:
		return capture(move.end_position);
	elif move.is_posession:
		return possess(move.end_position);
	else:
		pos = move.end_position;
		entity_moved.emit(self);

	return true;

func set_pos(new_pos: Vector2i) -> void:
	if animate:
		if tile_by_tile:
			for tile in map.get_inbetween_tiles(pos, new_pos) + [new_pos]:
				var tween := get_tree().create_tween();
				tween.tween_property(self, "position", Vector2(tile * map.cell_size), 0.25);
				tween.set_trans(Tween.TRANS_QUAD);
				await tween.finished;
		else:
			var tween := get_tree().create_tween();
			tween.tween_property(self, "position", Vector2(new_pos * map.cell_size), 0.25);
	else:
		position = Vector2(new_pos * map.cell_size);

func capture(target_pos: Vector2i) -> bool:
	if not map.is_cell_occupied(target_pos):
		return false;

	var target := map.get_entity_at(target_pos);
	target.on_capture();

	pos = target_pos;
	entity_moved.emit(self);
	return true;

func possess(target_pos: Vector2i) -> bool:
	# If there's nothing to possess, get outta here with this target position!
	if not map.is_cell_occupied(target_pos):
		return false;

	# Get the target of the possession.
	var target := map.get_entity_at(target_pos);
	target.on_possess();

	# The player is now a different entity.
	is_player = false;

	# If the current entity is not a king and has an AI, then we restore AI control to it.
	if not is_king and ai:
		is_ai_controlled = true;

	return true;

func get_legal_moves() -> Array[MoveInstance]:
	var move_instances: Array[MoveInstance] = [];

	for move in moves:
		if move.sliding:
			for cell in map.get_ray_cells(pos, move.slide_direction):
				move_instances.append(
					MoveInstance.new(pos, cell, map.is_cell_occupied(cell), false, move.floating)
				);
		else:
			if move.floating:
				var obstructed := false;
				for cell in map.get_inbetween_tiles(pos, pos + move.offset):
					if map.is_cell_occupied(cell, true):
						obstructed = true;
						break;

				if not obstructed:
					move_instances.append(
						MoveInstance.new(pos, pos + move.offset, map.is_cell_occupied(pos + move.offset), false, move.floating)
					);
			else:
				move_instances.append(
					MoveInstance.new(pos, pos + move.offset, map.is_cell_occupied(pos + move.offset), false, move.floating)
				);

	return move_instances;

func get_possessions() -> Array[MoveInstance]:
	var possessions: Array[MoveInstance] = [];
	if not is_player: return possessions;

	for entity in map.entities:
		if entity == self:
			continue;

		var manhattan_dist: int = abs(pos.x - entity.pos.x) + abs(pos.y - entity.pos.y);
		if manhattan_dist <= possession_range:
			possessions.append(
				MoveInstance.new(pos, entity.pos, false, true, true)
			);

	return possessions;

func on_capture() -> void:
	entity_captured.emit(self);
	queue_free();

func on_possess() -> void:
	map.player = self;
	is_player = true;
	is_ai_controlled = false;

	entity_possessed.emit(self);

func on_tick() -> void:
	if is_ai_controlled:
		var target_move = ai.get_move();
		if target_move:
			move(target_move);

#func _input(event: InputEvent) -> void:
	#if is_player and is_king:
		#if event.is_action_pressed("ui_up"):
			#move(moves[0]);
		#elif event.is_action_pressed("ui_down"):
			#move(moves[1]);
		#elif event.is_action_pressed("ui_left"):
			#move(moves[2]);
		#elif event.is_action_pressed("ui_right"):
			#move(moves[3]);
