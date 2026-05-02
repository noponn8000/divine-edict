extends CanvasLayer

@export var game_over_anim: AnimationPlayer;

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN;
	
	if SaveFile.is_first_run():
		%TutorialOverlay.visible = true;
		get_tree().create_timer(10.0).timeout.connect(func(): %TutorialOverlay.visible = false);

func toggle_pause_menu() -> void:
	%PauseMenu.reset_menu();
	%PauseMenu.visible = not %PauseMenu.visible;

	get_tree().paused = !get_tree().paused;

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position();
	%Cursor.position = mouse_pos;
