class_name SpikeTrap extends EnvironmentEntity

@export var activation_time := 0;
@export var anim: AnimationPlayer;

var active := false:
	set(is_active): active = is_active; if active: anim.play("activate");
var activation_period_started := false;
var ticks_left := activation_time;

func _ready() -> void:
	super._ready();
	interacted.connect(on_interact);

func on_interact(entity: Entity) -> void:
	if active:
		entity.on_capture();
	elif not activation_period_started:
		if activation_time > 0:
			activation_period_started = true;
			ticks_left = activation_time;
		else:
			active = true;
			entity.on_capture();

func on_tick() -> void:
	if activation_period_started:
		ticks_left -= 1;
		if ticks_left <= 0:
			active = true;
			activation_period_started = false;
