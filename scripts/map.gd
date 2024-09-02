class_name Map extends Node2D

@export var entity_parent_node: Node2D;
@export var cell_size = 8;
@export var highlights: TileMapLayer;
@export var inbetween_highlights: TileMapLayer;
@export var walls: TileMapLayer;

# Data
var entities: Array[Entity];
var selected_entity: Entity;

# The entity currently controlled by the player.
var player: Entity;
# The king entity - the game is over when this is captured.
var king: Entity;

# Flags
var move_choice_active := false;
var posession_choice_active := false;

func _ready() -> void:
	for child in entity_parent_node.get_children():
		if child is Entity:
			add_entity(child);

func add_entity(entity: Entity) -> void:
	entities.append(entity);
	entity.entity_moved.connect(on_entity_moved);
	entity.entity_captured.connect(on_entity_captured);
	entity.entity_possessed.connect(on_entity_possessed);

func on_entity_moved(entity: Entity) -> void:
	%StepAudio.play();
	if entity.is_player:
		advance_simulation();

func on_entity_captured(entity: Entity) -> void:
	%CaptureAudio.play();
	remove_entity(entity);

func on_entity_possessed(entity: Entity) -> void:
	%CaptureAudio.play();
	advance_simulation();

func advance_simulation() -> void:
	for entity in entities:
		entity.on_tick();

func remove_entity(entity: Entity) -> void:
	entities.erase(entity);

func get_entity_at(pos: Vector2i) -> Entity:
	var entity: Entity = null;
	for e in entities:
		if e.pos == pos:
			entity = e;

	return entity;

func is_cell_occupied(pos: Vector2i, include_walls: bool = false) -> bool:
	for e in entities:
		if e.pos == pos:
			return true;

	if include_walls and is_cell_wall(pos):
		return true;

	return false;

func is_cell_wall(pos: Vector2i) -> bool:
	return walls.get_cell_source_id(pos) != -1;

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
				selected_entity.move(target_move);
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

		clear_highlights();
		if is_cell_occupied(mouse_pos, true) and get_entity_at(mouse_pos).is_player:
			move_choice_active = true;
			selected_entity = get_entity_at(mouse_pos);
			show_highlights(selected_entity);
		else:
			move_choice_active = false;
	elif Input.is_action_pressed("possess"):
		if posession_choice_active:
			posession_choice_active = false;
			clear_highlights();
		else:
			posession_choice_active = true;

			move_choice_active = false;
			selected_entity = null;

			show_posession_higlights(player, 3);

func get_inbetween_tiles(posi: Vector2i, posf: Vector2i) -> Array[Vector2i]:
	var inbetweens: Array[Vector2i] = [];

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
			for y in range(posi.y + 1, posf.y):
				inbetweens.append(Vector2i(posi.x, y));
		elif posf.y < posi.y:
			for y in range(posf.y + 1, posi.y):
				inbetweens.append(Vector2i(posi.x, y));

	return inbetweens;

func get_ray_cells(pos: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var collided := false;
	var iterations := 0;
	var cells: Array[Vector2i] = [];
	while not collided and iterations < 16:
		print(iterations);
		iterations += 1;
		cells.append(pos + iterations * dir);
		if is_cell_occupied(pos + iterations * dir):
			collided = true;
		elif is_cell_occupied(pos + iterations * dir, true):
			collided = true;
			cells.remove_at(cells.size() - 1);

	return cells;
