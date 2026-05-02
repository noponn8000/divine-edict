class_name Save extends Node;

@export var auto_save := true;

var file : ConfigFile;

func load_game() -> void:
	file = ConfigFile.new();
	if FileAccess.file_exists("user://save.cfg"):
		file.load("user://save.cfg");
	else:
		print_debug("Save file does not exist. Loading default save.")
		file.load("res://resources/default_save.cfg");

	set_level_unlocked(1, 0, true);

func save_game() -> void:
	print_debug("Saving...")
	file.set_value("meta", "first_run", false);
	file.save("user://save.cfg");

func _ready() -> void:
	load_game();

func is_level_unlocked(world_id: int, level_id: int) -> bool:
	if file.has_section_key("world_" + str(world_id), "level_" + str(level_id) + "_unlocked"):
		return file.get_value("world_" + str(world_id), "level_" + str(level_id) + "_unlocked");

	return false;

func set_level_unlocked(world_id: int, level_id: int, is_unlocked: bool) -> void:
	file.set_value("world_" + str(world_id), "level_" + str(level_id) + "_unlocked", is_unlocked);
	if auto_save:
		save_game();

func get_player_worldmap_pos(world_id: int) -> Vector2i:
	if file.has_section_key("player", "world_" + str(world_id) + "_pos"):
		return file.get_value("player", "world_" + str(world_id) + "_pos");
	return Vector2i(4, 4);

func set_player_worldmap_pos(world_id: int, pos: Vector2i) -> void:
	file.set_value("player", "world_" + str(world_id) + "_pos", pos);
	
func is_first_run() -> bool:
	# Testing only!
	file.set_value("meta", "first_run", true);
	if file.has_section_key("meta", "first_run"):
		return file.get_value("meta", "first_run");
	else:
		return true;
