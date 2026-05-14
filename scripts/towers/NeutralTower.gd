extends StaticBody2D
class_name NeutralTower

@export var damage: float = 20.0
@export var attack_range: float = 110.0
@export var attack_cooldown: float = 1.5

var attack_timer: float = 0.0
var current_target: Unit = null

@onready var body: Polygon2D = $Body
@onready var label: Label = $Label
@onready var range_shape: CollisionShape2D = $RangeArea/RangeShape


func _ready() -> void:
	_setup_visual()


func _process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	current_target = _find_target()

	if current_target == null or attack_timer > 0.0:
		return

	attack_timer = attack_cooldown
	current_target.take_damage(damage, -1)
	EventBus.tower_attacked.emit(self, current_target)


func _setup_visual() -> void:
	body.polygon = PackedVector2Array([
		Vector2(-10, -10),
		Vector2(10, -10),
		Vector2(10, 10),
		Vector2(-10, 10),
	])
	body.color = Color("#777777")
	label.text = "T"

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = attack_range
	range_shape.shape = circle_shape


func _find_target() -> Unit:
	var nearest_unit: Unit = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit.is_dead:
			continue

		var distance := global_position.distance_to(unit.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest_distance = distance
			nearest_unit = unit

	return nearest_unit
