extends Area2D
class_name PlayerBase

@export var player_id: int = 0
@export var max_hp: float = 100.0

var current_hp: float = 100.0

@onready var body: Polygon2D = $Body
@onready var hp_bar: ProgressBar = $HPBar
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("bases")
	EventBus.round_reset_requested.connect(reset_base)
	EventBus.unit_reached_base.connect(_on_unit_reached_base)
	current_hp = max_hp
	_setup_visual()
	_update_display()


func take_damage(amount: float, attacker_player: int) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	_update_display()
	EventBus.base_damaged.emit(self, amount, attacker_player)

	if current_hp <= 0.0:
		EventBus.base_destroyed.emit(self)


func reset_base() -> void:
	current_hp = max_hp
	_update_display()


func _on_unit_reached_base(unit: Node, target_base: Node) -> void:
	if target_base != self:
		return

	var unit_damage := float(unit.get("damage"))
	var attacker_id := int(unit.get("player_id"))
	take_damage(unit_damage * 3.0, attacker_id)


func _setup_visual() -> void:
	body.polygon = _make_circle_polygon(30.0, 32)
	body.color = GameConfig.get_player_color(player_id)

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 34.0
	collision_shape.shape = circle_shape

	label.text = "P%d Base" % player_id


func _update_display() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp


func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	return points
