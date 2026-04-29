extends Control

@export var dagger_offset := 16;

enum ButtonType { RETURN, RESTART, WORLDMAP, QUIT };

func reset_menu() -> void:
	%Dagger.reset();
	%Dagger.global_position.x = 23;
	
func _on_return_button_mouse_entered() -> void:
	if !%Dagger.animating:
		%Dagger.global_position.x = %ReturnButton.global_position.x + dagger_offset

func _on_restart_button_mouse_entered() -> void:
	if !%Dagger.animating:
		%Dagger.global_position.x = %RestartButton.global_position.x + dagger_offset;
	
func _on_world_map_button_mouse_entered() -> void:
	if !%Dagger.animating:
		%Dagger.global_position.x = %WorldMapButton.global_position.x + dagger_offset

func _on_quit_button_mouse_entered() -> void:
	if !%Dagger.animating:
		%Dagger.global_position.x = %QuitButton.global_position.x + dagger_offset

func _on_return_button_button_down() -> void:
	on_button(ButtonType.RETURN);
	
func _on_restart_button_button_down() -> void:
	on_button(ButtonType.RESTART);
	
func _on_world_map_button_button_down() -> void:
	on_button(ButtonType.WORLDMAP);

func _on_quit_button_button_down() -> void:
	on_button(ButtonType.QUIT);

func on_button(button_type: ButtonType) -> void:
	if !%Dagger.animating:
		%Dagger.animate_stab();
		await %Dagger.animation_finished;
	
	match button_type:
		ButtonType.WORLDMAP:
			get_tree().paused = false;
			get_tree().change_scene_to_file("res://scenes/levels/world_map_1.tscn");
		ButtonType.QUIT:
			SaveFile.save_game();
			get_tree().quit();
		ButtonType.RESTART:
			get_tree().paused = false;
			get_tree().reload_current_scene();
		ButtonType.RETURN:
			owner.toggle_pause_menu();
