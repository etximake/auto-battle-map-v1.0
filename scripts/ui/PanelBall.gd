extends Area2D
class_name PanelBall

@export var radius: float = 7.0
@export var ball_color: Color = Color.WHITE
@export var anchor_radius: float = 11.0

var player_id: int = 0
var velocity: Vector2 = Vector2.ZERO
var panel_bounds: Rect2 = Rect2(0, 0, 192, 360)
var anchor_points: Array[Vector2] = []
var anchor_cooldown: float = 0.0
var is_consumed: bool = false

@onready var body: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 5
	_setup_visual()
	add_to_group("panel_balls")


func _physics_process(delta: float) -> void:
	if is_consumed:
		return

	anchor_cooldown = maxf(anchor_cooldown - delta, 0.0)
	position += velocity * delta
	_redirect_from_anchor()
	_bounce_inside_panel()


func setup(new_player_id: int, new_bounds: Rect2, start_position: Vector2, start_velocity: Vector2, new_color: Color, new_anchor_points: Array[Vector2] = [], new_anchor_radius: float = 11.0) -> void:
	player_id = new_player_id
	panel_bounds = new_bounds
	position = start_position
	velocity = start_velocity
	ball_color = new_color
	anchor_points = new_anchor_points.duplicate()
	anchor_radius = new_anchor_radius
	anchor_cooldown = 0.0
	is_consumed = false
	_setup_visual()


func consume() -> bool:
	if is_consumed:
		return false

	is_consumed = true
	return true


func despawn() -> void:
	queue_free()


func _redirect_from_anchor() -> void:
	if anchor_cooldown > 0.0:
		return

	for anchor_position in anchor_points:
		var distance := position.distance_to(anchor_position)
		if distance > anchor_radius + radius:
			continue

		var away := position - anchor_position
		if away.length_squared() < 0.01:
			away = Vector2(randf_range(-1.0, 1.0), 1.0)
		away = away.normalized()

		var speed := maxf(velocity.length(), 120.0)
		position = anchor_position + away * (anchor_radius + radius + 1.0)
		velocity = Vector2(
			away.x * speed + randf_range(-45.0, 45.0),
			absf(away.y) * speed + speed * 0.35
		).limit_length(speed * 1.25)
		anchor_cooldown = 0.12
		return


func _bounce_inside_panel() -> void:
	var min_x := panel_bounds.position.x + radius
	var max_x := panel_bounds.end.x - radius
	var min_y := panel_bounds.position.y + radius
	var max_y := panel_bounds.end.y + radius

	if position.x < min_x:
		position.x = min_x
		velocity.x = absf(velocity.x)
	elif position.x > max_x:
		position.x = max_x
		velocity.x = -absf(velocity.x)

	if position.y < min_y:
		position.y = min_y
		velocity.y = absf(velocity.y)
	elif position.y > max_y:
		despawn()


func _setup_visual() -> void:
	if body == null or collision_shape == null:
		return

	body.polygon = _make_circle_polygon(radius, 18)
	body.color = ball_color

	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape


func _make_circle_polygon(poly_radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * poly_radius)

	return points
