class_name PathfindingAI extends EnemyAI

var astar := AStar2D.new();

@onready var map: Map = owner.map;

func _ready() -> void:
	await map.ready;
	construct_astar();

func construct_astar() -> void:
	print(len(map.astar_index_map));
	for point in map.astar_index_map.keys():
		astar.add_point(map.astar_index_map[point], point);
		if map.is_cell_wall(point):
			astar.set_point_disabled(map.astar_index_map[point], true);

	for point in map.astar_index_map.keys():
		connect_neighbours(point);

func connect_neighbours(point: Vector2i) -> void:
	var id: int = map.astar_index_map[point];
	for move: Move in owner.moves:
		if !move.sliding:
			var target_point := point + move.offset;
			if map.astar_index_map.has(target_point) and !map.is_cell_wall(target_point):
				astar.connect_points(id, map.astar_index_map[target_point]);

func get_move() -> MoveInstance:
	var path := astar.get_point_path(map.astar_index_map.get(owner.pos), map.astar_index_map.get(map.player.pos), true);
	var legal_moves: Array[MoveInstance] = owner.get_legal_moves();

	for move in legal_moves:
		if Vector2(move.end_position) in path:
			return move;

	return legal_moves[0];
