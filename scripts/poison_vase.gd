@tool
extends EnvironmentEntity

@export var radius := 2;
@export var poison_scene := preload("res://scenes/poison.tscn");
@export var audio: AudioStreamPlayer;

func _ready() -> void:
	super._ready();
	interacted.connect(on_interact);

func on_interact(entity: Entity) -> void:
	if not visible: return;

	spawn_poison();
	visible = false;

	if audio:
		audio.play();
		await audio.finished;

	map.remove_entity(self);
	queue_free();

func spawn_poison() -> void:
	var poisons := [];

	for x in range(pos.x - radius, pos.x + radius + 1):
		for y in range(pos.y - radius, pos.y + radius + 1):
			if map.is_cell_wall(Vector2i(x, y)): continue;

			var poison := poison_scene.instantiate();
			poisons.append(poison);
			map.add_entity(poison);
			poison.pos = Vector2i(x, y);

			var entity := map.get_entity_at(pos);
			if entity:
				poison.on_interact(entity);

	for poison in poisons:
		poison.initialised = true;

func on_capture() -> void:
	pass;
