extends EnvironmentEntity

@export var radius := 2;
@export var poison_scene := preload("res://scenes/poison.tscn");

func _ready() -> void:
	super._ready();
	interacted.connect(on_interact);

func on_interact(entity: Entity) -> void:
	spawn_poison();
	%PoisonGasAudio.play()
	entity.on_capture();
	visible = false;

func spawn_poison() -> void:
	for x in range(pos.x - radius, pos.x + radius + 1):
		for y in range(pos.y - radius, pos.y + radius + 1):
			var poison := poison_scene.instantiate();
			map.add_entity(poison);
			poison.pos = Vector2i(x, y);

			var entity := map.get_entity_at(Vector2i(x, y));
			if entity:
				poison.on_interact(entity);

func on_capture() -> void:
	pass;
