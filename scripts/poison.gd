extends EnvironmentEntity

func on_interact(entity: Entity) -> void:
	entity.pos = pos;
	entity.on_capture();

func _ready() -> void:
	interacted.connect(on_interact);
