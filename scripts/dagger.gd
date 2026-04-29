extends Sprite2D

var animating := false;

signal animation_finished;

func animate_stab() -> void:
	if not animating:
		animating = true;
		
		%AnimationPlayer.play("stab");
		await %AnimationPlayer.animation_finished;
		animation_finished.emit();

func reset() -> void:
	%AnimationPlayer.play("RESET");
	animating = false;
