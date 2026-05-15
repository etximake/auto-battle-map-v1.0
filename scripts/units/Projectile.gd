extends Node2D
class_name Projectile

@export var radius: float = 5.0
@export var hit_distance: float = 10.0

var shooter_player_id: int = -1
var target: Node2D
var damage: float = 0.0
var speed: float = 300.0
var projectile_color: Color = Color.WHITE

@onready var body: Polygon2D = $Body


func _ready() -> void:
	add_to_group("projectiles")
	EventBus.round_reset_requested.connect(queue_free)
	_setup_visual()


func _physics_process(delta: float) -> void:
	if not _is_target_valid():
		queue_free()
		return

	var to_target := target.global_position - global_position
	if to_target.length() <= hit_distance:
		_hit_target()
		return

	global_position += to_target.normalized() * speed * delta
	rotation = to_target.angle()


func setup(new_player_id: int, new_target: Node, new_damage: float, new_speed: float, new_color: Color) -> void:
	shooter_player_id = new_player_id
	target = new_target as Node2D
	damage = new_damage
	speed = new_speed
	projectile_color = new_color
	_setup_visual()


func _hit_target() -> void:
	if _is_target_valid() and target.has_method("take_damage"):
		target.call("take_damage", damage, shooter_player_id)
	queue_free()


func _is_target_valid() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if int(target.get("player_id")) == shooter_player_id:
		return false
	return not bool(target.get("is_dead"))


func _setup_visual() -> void:
	if body == null:
		return
	body.polygon = _make_diamond_polygon(radius)
	body.color = projectile_color


func _make_diamond_polygon(poly_radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(poly_radius, 0.0),
		Vector2(0.0, poly_radius * 0.65),
		Vector2(-poly_radius, 0.0),
		Vector2(0.0, -poly_radius * 0.65),
	])
