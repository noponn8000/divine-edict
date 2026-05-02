class_name SpikeTrap extends EnvironmentEntity

@export var activation_time := 2;
@export var deactivation_time := 2;
@export var anim: AnimationPlayer;

var active := false:
	set(is_active):
		active = is_active;
		if is_active:
			deactivation_ticks_left = deactivation_time;
			anim.play("activate");
		else:
			anim.play_backwards("activate");
		intercept = active;
var activation_period_started := false;
var activation_ticks_left := activation_time;
var deactivation_ticks_left := deactivation_time;

func _ready() -> void:
	super._ready();
	active = active;
	interacted.connect(on_interact);

func on_interact(entity: Entity) -> void:
	if active:
		entity.pos = pos;
		entity.on_capture();
	elif not activation_period_started:
		if activation_time > 0:
			activation_period_started = true;
			activation_ticks_left = activation_time;
		else:
			entity.pos = pos;
			active = true;
			entity.on_capture();

func on_tick() -> void:
	if is_player: return;
	
	if activation_period_started:
		activation_ticks_left -= 1;
		if activation_ticks_left <= 0:
			active = true;
			activation_period_started = false;

	if active:
		deactivation_ticks_left -= 1;
		if deactivation_ticks_left <= 0:
			active = false;
