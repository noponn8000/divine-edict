class_name LevelLoader extends EnvironmentEntity;

@export var level: PackedScene;

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("possess") and map.player.pos == pos:
		get_tree().change_scene_to_packed(level);
