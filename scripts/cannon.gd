@tool
extends Entity;

@export var cannonball_scene := preload("res://scenes/cannonball.tscn");
@export var fire_direction := Vector2i.LEFT;
@export var fire_rate := 5;

var ticks := 0;

func _ready() -> void:
	print(name);
	print(capturable)
	super._ready();

	rotation = Vector2.LEFT.angle_to(fire_direction);
	offset = Vector2(4, 4).rotated(rotation);

func on_tick() -> void:
	ticks += 1;

	if ticks >= fire_rate and not map.is_cell_wall(pos + fire_direction):
		ticks = 0;

		var entity := map.get_entity_at(pos + fire_direction);
		if entity:
			entity.on_capture();

		var ball := cannonball_scene.instantiate();
		map.add_entity(ball);
		ball.ai.move_direction = fire_direction;
		ball.pos = pos + fire_direction;
		ball.animate = true;
