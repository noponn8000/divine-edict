class_name Map extends Node2D

@export var entity_parent_node: Node2D;
@export var hud: CanvasLayer;
@export var cell_size = 8;
@export var highlights: TileMapLayer;
@export var inbetween_highlights: TileMapLayer;
@export var walls: TileMapLayer;
@export var target_edge := Edge.TOP;
@export var is_world_map := false;
@export var world_id := 1;
@export var level_id := 1;
@export var next_level_id := 2;

@export var bounds_min := Vector2(1, 1);
@export var bounds_max := Vector2(15, 15);

var astar_index_map := {};

# Data
var entities: Array[Entity];
var environment_entities: Array[EnvironmentEntity];
var selected_entity: Entity;

# The entity currently controlled by the player.
var player: Entity;
# The king entity - the game is over when this is captured.
var king: Entity;

# Flags
var move_choice_active := false;
var posession_choice_active := false;
var game_over := false;
var turn_in_progress := false;

enum Edge {TOP, BOTTOM, LEFT, RIGHT};

signal edge_reached(Edge);

func _ready() -> void:
	var astar_index := 0;
	for x in range(bounds_min.x, bounds_max.x):
		for y in range(bounds_min.y, bounds_max.y):
			astar_index_map[Vector2i(x, y)] = astar_index;
			astar_index += 1;

	on_game_start();
	for child in entity_parent_node.get_children():
		if child is Entity:
			add_entity(child);

	edge_reached.connect(on_edge_reached);

func get_chebyshev_distance(posi: Vector2i, posf: Vector2i) -> int:
	return abs(posi.x - posf.x) + abs(posi.y - posf.y);

func is_sightline_clear(posi: Vector2i, posf: Vector2i) -> bool:
	if posi.x > posf.x and posi.y < posf.y:
		var temp = posi;
		posi = posf;
		posf = temp;

	for tile in get_inbetween_tiles(posi, posf):
		if is_cell_wall(tile):
			return false;

	return true;

func add_entity(entity: Entity) -> void:
	if not entity.get_parent():
		entity_parent_node.add_child(entity);

	if entity is EnvironmentEntity:
		environment_entities.append(entity);
	else:
		entities.append(entity);
		entity.entity_moved.connect(on_entity_moved);
		entity.entity_captured.connect(on_entity_captured);
		entity.entity_possessed.connect(on_entity_possessed);

	entity.map = self;

func on_entity_moved(entity: Entity) -> void:
	%StepAudio.play();
	if entity == player:
		advance_simulation();

	if entity.is_king:
		if entity.pos.y == 1:
			edge_reached.emit(Edge.TOP);
		elif entity.pos.y == 14:
			edge_reached.emit(Edge.BOTTOM);
		elif entity.pos.x == 1:
			edge_reached.emit(Edge.LEFT);
		elif entity.pos.x == 14:
			edge_reached.emit(Edge.RIGHT);

	var env_entity := get_entity_at(entity.pos, true);
	if env_entity:
		env_entity.on_pass(entity);

func on_entity_captured(entity: Entity) -> void:
	%CaptureAudio.play();

	if entity.is_king:
		on_game_over();

	remove_entity(entity);

func on_entity_possessed(entity: Entity, no_turn_trigger) -> void:
	%CaptureAudio.play();
	if not no_turn_trigger:
		advance_simulation();

func advance_simulation() -> void:
	for entity in entities + environment_entities:
		entity.on_tick();

func remove_entity(entity: Entity) -> void:
	if entity is EnvironmentEntity:
		environment_entities.erase(entity);
	else:
		entities.erase(entity);

func get_entity_at(pos: Vector2i, env_entities_only: bool = false) -> Entity:
	var entity: Entity = null;
	if env_entities_only:
		for e in environment_entities:
			if e.pos == pos:
				entity = e;
	else:
		for e in entities:
			if e.pos == pos:
				entity = e;

	return entity;

func is_cell_occupied(pos: Vector2i, include_walls: bool = false, include_env_entities: bool = false) -> bool:
	if get_entity_at(pos) or (include_env_entities and get_entity_at(pos, true)):
		return true;

	if include_walls and is_cell_wall(pos):
		return true;

	return false;

func is_cell_wall(pos: Vector2i) -> bool:
	var entity := get_entity_at(pos);
	return walls.get_cell_source_id(pos) != -1 or (entity and !entity.capturable);

func show_highlights(entity: Entity) -> void:
	for e in entities:
		if e != entity:
			e.modulate.a = 0.5;

	for move in entity.get_legal_moves():
		if move.is_capture:
			highlights.set_cell(move.end_position, 0, Vector2i(7, 0));
		else:
			highlights.set_cell(move.end_position, 0, Vector2i(4, 0));

		if not move.is_floating:
			for inb in get_inbetween_tiles(move.start_position, move.end_position):
				inbetween_highlights.set_cell(inb, 0, Vector2i(6, 0));

func show_posession_higlights(entity: Entity, range: int) -> void:
	for x in range(entity.pos.x - range + 1, entity.pos.x + range):
		for y in range(entity.pos.y - range + 1, entity.pos.y + range):
			var c_pos = Vector2i(x, y);
			var manhattan_dist: int = abs(x - entity.pos.x) + abs(y - entity.pos.y);
			if c_pos != entity.pos and not is_cell_wall(c_pos) and manhattan_dist <= range:
				if is_cell_occupied(c_pos):
					highlights.set_cell(c_pos, 0, Vector2i(7, 0));
				else:
					highlights.set_cell(c_pos, 0, Vector2i(6, 0));

func clear_highlights() -> void:
	for entity in entities:
		entity.modulate.a = 1.0;

	highlights.clear();
	inbetween_highlights.clear();

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("select"):
		var mouse_pos: Vector2i = get_local_mouse_position() / cell_size;
		if move_choice_active:
			var target_move: MoveInstance;
			for move in selected_entity.get_legal_moves():
				if move.end_position == mouse_pos:
					target_move = move;

			if target_move:
				if selected_entity.move(target_move):
					show_move_select(selected_entity.pos);
				else:
					move_choice_active = false;
					selected_entity = null;

					clear_highlights();

				return;
		elif posession_choice_active:
			for possession in player.get_possessions():
				if possession.end_position == mouse_pos and player.move(possession):
					posession_choice_active = false;
					clear_highlights();

					return;

			posession_choice_active = false;
			clear_highlights();

		show_move_select(mouse_pos);
	elif Input.is_action_pressed("possess"):
		if not is_world_map:
			posession_choice_active = true;

			move_choice_active = false;
			selected_entity = null;

			show_posession_higlights(player, 3);
	elif Input.is_action_pressed("ui_cancel"):
		hide_all_select();
	elif Input.is_action_pressed("restart"):
		get_tree().reload_current_scene();

func show_move_select(pos: Vector2i) -> void:
		clear_highlights();
		var entity := get_entity_at(pos)
		if is_cell_occupied(pos, true) and entity and entity.is_player:
			move_choice_active = true;
			selected_entity = get_entity_at(pos);
			show_highlights(selected_entity);
		else:
			move_choice_active = false;

func hide_all_select() -> void:
	move_choice_active = false;
	posession_choice_active = false;
	clear_highlights();

func get_inbetween_tiles(posi: Vector2i, posf: Vector2i) -> Array[Vector2i]:
	var inbetweens: Array[Vector2i] = [];

	if abs(posi.x - posf.x) >= abs(posi.y - posf.y):
		if posf.x > posi.x:
			var gradient: float = (float) (posf.y - posi.y) / (posf.x - posi.x);
			var intercept := posi.y - gradient * posi.x;
			var y = posi.y;
			for x in range(posi.x + 1, posf.x):
				y = roundi(x * gradient + intercept);
				inbetweens.append(Vector2i(x, y));
		elif posf.x < posi.x:
			var gradient: float = (float) (posf.y - posi.y) / (posf.x - posi.x);
			var intercept := posi.y - gradient * posi.x;
			var y = posi.y;
			for x in range(posf.x + 1, posi.x):
				y = roundi(x * gradient + intercept);
				inbetweens.append(Vector2i(x, y));
	else:
		if posf.y > posi.y:
			var gradient: float = (float) (posf.x - posi.x) / (posf.y - posi.y);
			var intercept := posi.x - gradient * posi.y;
			var x = posi.x;
			for y in range(posi.y + 1, posf.y):
				x = roundi(y * gradient + intercept);
				inbetweens.append(Vector2i(x, y));
		elif posf.y < posi.y:
			var gradient: float = (float) (posf.x - posi.x) / (posf.y - posi.y);
			var intercept := posi.x - gradient * posi.y;
			var x = posi.x;
			for y in range(posf.y + 1, posi.y):
				x = roundi(y * gradient + intercept);
				inbetweens.append(Vector2i(x, y));
		#if posf.y > posi.y:
			#for y in range(posi.y + 1, posf.y):
				#inbetweens.append(Vector2i(posi.x, y));
		#elif posf.y < posi.y:
			#for y in range(posf.y + 1, posi.y):
				#inbetweens.append(Vector2i(posi.x, y));

	return inbetweens;

func get_ray_cells(pos: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var collided := false;
	var iterations := 0;
	var cells: Array[Vector2i] = [];
	while not collided and iterations < 16:
		iterations += 1;
		cells.append(pos + iterations * dir);
		if is_cell_occupied(pos + iterations * dir):
			collided = true;
		elif is_cell_occupied(pos + iterations * dir, true):
			collided = true;
			cells.remove_at(cells.size() - 1);

	return cells;

func on_game_over() -> void:
	var tree := get_tree();
	await tree.create_timer(0.48).timeout;
	var tween := tree.create_tween();

	tween.tween_property(
		self,
		"modulate:v",
		0.25,
		1.0
	);
	hud.game_over_anim.play("appear");
	await hud.game_over_anim.animation_finished;

	tree.reload_current_scene();

func on_game_start() -> void:
	modulate.v = 0.25;
	var tween := get_tree().create_tween();
	tween.tween_property(
		self,
		"modulate:v",
		1.0,
		0.5
	);

func on_edge_reached(edge: Edge) -> void:
	if edge == target_edge:
		if next_level_id != -1:
			SaveFile.set_level_unlocked(world_id, next_level_id, true);
		get_tree().change_scene_to_packed(LevelLibrary.get_world_map(world_id));
