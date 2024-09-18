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
