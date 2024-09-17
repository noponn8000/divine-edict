class_name LevelLib extends Node

@export var levels := {
	1: [
		preload("res://scenes/levels/level_0.tscn"),
		preload("res://scenes/levels/level1.tscn"),
		preload("res://scenes/levels/level2.tscn"),
		preload("res://scenes/levels/level3.tscn"),
		preload("res://scenes/levels/level4.tscn")
	]
};

@export var world_maps := {
	1: preload("res://scenes/levels/world_map_1.tscn")
};

func get_level(world_id: int, level_id: int) -> PackedScene:
	var world = levels.get(world_id);
	if world and len(world) > level_id:
		return world[level_id];

	return null;

func get_world_map(world_id: int) -> PackedScene:
	return world_maps.get(world_id);
