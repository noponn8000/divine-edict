@tool
class_name EnvironmentEntity extends Entity

signal interacted(Entity);

# Does this entity intercept entities moving through it?
@export var intercept := true;

func _ready() -> void:
	set_player_visual();
	if texture:
		hframes = texture.get_width() / 8;
	pos = position / map.cell_size;

func on_pass(entity: Entity) -> bool:
	interacted.emit(entity);
	return intercept;
