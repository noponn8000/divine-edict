extends EnvironmentEntity

@export var linger_time := 5;

var lifespan := 0;

func on_interact(entity: Entity) -> void:
	entity.pos = pos;
	entity.on_capture();

func _ready() -> void:
	interacted.connect(on_interact);

func on_tick() -> void:
	lifespan += 1;
	if lifespan >= linger_time:
		map.remove_entity(self);
		queue_free();
