@tool
class_name Entity extends Sprite2D

@export_category("Movement")
@export var moves: Array[Move];
@export var possession_range := 3;

@export_category("Visuals")
@export var animate := true;
@export var tile_by_tile := false;
@export var capture_anim_scene: PackedScene = preload("res://scenes/capture_animation.tscn");

@export_category("References")
@export var map: Map = owner;

@export_category("Gameplay")
@export var capturable := true;
@export var is_player := false:
	set(b): is_player = b;
@export var is_king := false;
@export var is_ai_controlled := false;
@export var ai: EnemyAI;

@export_category("Visuals")
## Blinking speed in cycles per second
@export var blinking_speed := 0.5;
## Minimum alpha value when oscillating
@export var alpha_min := 0.3;

var pos: Vector2i:
	set(new_pos):  set_pos(new_pos); pos = new_pos;
var is_animating := false;
var blinking := false;
var blink_accumulator := 0.0;

signal entity_moved(Entity);
signal entity_captured(Entity);
signal entity_possessed(Entity, bool);
signal move_animation_finished();

func _ready() -> void:
	# Set the number of frames in the spritesheet automatically
	hframes = texture.get_width() / 8;

	if Engine.is_editor_hint():
		return;

	if not map: await get_tree().create_timer(0.2).timeout;

	pos = position / map.cell_size;
	if is_player:
		map.player = self;
	if is_king:
		map.king = self;

func move(move: MoveInstance) -> bool:
	if not move.is_floating:
		for cell in map.get_inbetween_tiles(move.start_position, move.end_position):
			var env_entity := map.get_entity_at(cell, true);
			if env_entity and env_entity.on_pass(self):
				return true;

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
		is_animating = true;
		if tile_by_tile:
			for tile in map.get_inbetween_tiles(pos, new_pos) + [new_pos]:
				var tween := get_tree().create_tween();
				tween.tween_property(self, "position", Vector2(tile * map.cell_size), 0.25);
				tween.set_trans(Tween.TRANS_QUAD);
				await tween.finished;
		else:
			var tween := get_tree().create_tween();
			tween.tween_property(self, "position", Vector2(new_pos * map.cell_size), 0.25);

			await tween.finished;
			is_animating = false;
			move_animation_finished.emit();
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

	# The player is now a different entity.
	is_player = false;

	# If the current entity is not a king and has an AI, then we restore AI control to it.
	if not is_king and ai:
		is_ai_controlled = true;

	# Get the target of the possession.
	var target := map.get_entity_at(target_pos);
	target.on_possess();

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
			if is_offset_move_legal(move, pos):
				move_instances.append(
					MoveInstance.new(pos, pos + move.offset, map.is_cell_occupied(pos + move.offset), false, move.floating)
				);

	return move_instances;

func is_offset_move_legal(move: Move, s_pos: Vector2i) -> bool:
	if map.is_cell_wall(s_pos + move.offset):
		return false;

	if not move.floating:
		var obstructed := false;
		for cell in map.get_inbetween_tiles(s_pos, s_pos + move.offset):
			if map.is_cell_occupied(cell, true):
				obstructed = true;
				break;

		return not obstructed;

	return true;

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
	var king_reposess := is_player and not is_king;

	# Disable AI and player control
	is_ai_controlled = false;
	is_player = false;

	entity_captured.emit(self);

	var anim := capture_anim_scene.instantiate();
	anim.position = pos * map.cell_size;
	get_tree().root.add_child(anim);

	if king_reposess:
		map.king.on_possess(true);

	if is_animating:
		await move_animation_finished;
	queue_free();

func on_possess(no_turn_trigger: bool = false) -> void:
	map.player = self;
	is_player = true;
	is_ai_controlled = false;

	entity_possessed.emit(self, no_turn_trigger);

func on_tick() -> void:
	if is_ai_controlled:
		var target_move = ai.get_move();
		if target_move:
			move(target_move);

func _process(delta: float) -> void:
	if (is_player):
		blink_accumulator = wrapf(blink_accumulator + delta, 0, blinking_speed);
		modulate.a = alpha_min + (1 - alpha_min) * 0.5 * (1 + sin(blink_accumulator * TAU / blinking_speed));
	else:
		modulate.a = 1.0;
