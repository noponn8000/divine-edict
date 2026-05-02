extends AnimatedSprite2D

func _ready() -> void:
	open();
	
func open() -> void:
	%AudioStreamPlayer.play();
	play("open");
	await animation_finished;
	%AudioStreamPlayer.stop();
