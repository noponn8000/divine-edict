class_name LevelLoader extends EnvironmentEntity;

@export var world_id := 1;
@export var level_id := 1;
@export var level: PackedScene;
@export var animation_player: AnimationPlayer;
@export var unlocked := false :
	set(is_unlocked):
		unlocked = is_unlocked;
		if is_unlocked:
			modulate.a = 1.0;
		else:
			modulate.a = 0.4;
var activated := false;

func _ready() -> void:
	unlocked = SaveFile.is_level_unlocked(world_id, level_id);
	pos = position / map.cell_size;

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("possess") and activated:
		get_tree().change_scene_to_packed(level);

func on_tick() -> void:
	if not unlocked: return;

	if map.player.pos == pos and not activated:
		activated = true;
		animation_player.play("activate");
	elif map.player.pos != pos and activated:
		activated = false;
		animation_player.play_backwards("activate");
