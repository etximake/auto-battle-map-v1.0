extends Node2D
class_name BallPanel

const REWARD_TYPES: Array[String] = ["Scout", "Soldier", "Tank", "Mage", "x2"]
const PLAYER_COLORS := {
	0: Color("#E74C3C"),
	1: Color("#3498DB"),
	2: Color("#2ECC71"),
	3: Color("#F1C40F"),
}

@export var player_id: int = 0
@export var panel_size: Vector2 = Vector2(192, 360)
@export var spawn_interval: float = 0.7
@export var ball_speed: float = 165.0
@export var max_live_balls: int = 8
@export var ball_scene: PackedScene
@export var reward_slot_scene: PackedScene

var spawn_timer: float = 0.0
var spawn_index: int = 0
var reward_counts: Dictionary = {}

@onready var background: Polygon2D = $Background
@onready var title_label: Label = $TitleLabel
@onready var counter_label: Label = $CounterLabel
@onready var reward_slots: Node2D = $RewardSlots
@onready var ball_container: Node2D = $BallContainer


func _ready() -> void:
	add_to_group("ball_panels")
	EventBus.reward_generated.connect(_on_reward_generated)
	_setup_visual()
	_create_reward_slots()
	_update_counter_label()


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	if ball_container.get_child_count() >= max_live_balls:
		return

	spawn_timer = spawn_interval
	_spawn_ball()


func _setup_visual() -> void:
	var color := _get_player_color()
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(panel_size.x, 0),
		panel_size,
		Vector2(0, panel_size.y),
	])
	background.color = Color(color.r, color.g, color.b, 0.42)

	title_label.text = "P%d" % player_id
	title_label.position = Vector2(12, 8)
	title_label.size = Vector2(panel_size.x - 24, 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	counter_label.position = Vector2(8, panel_size.y - 72)
	counter_label.size = Vector2(panel_size.x - 16, 24)


func _create_reward_slots() -> void:
	for child in reward_slots.get_children():
		child.queue_free()

	var spacing := panel_size.x / float(REWARD_TYPES.size() + 1)
	for index in REWARD_TYPES.size():
		var slot := reward_slot_scene.instantiate() as Node2D
		reward_slots.add_child(slot)
		slot.position = Vector2(spacing * float(index + 1), panel_size.y - 34)
		if slot.has_method("configure"):
			slot.call("configure", player_id, REWARD_TYPES[index], _get_player_color())


func _spawn_ball() -> void:
	if ball_scene == null:
		return

	var slot_count: int = maxi(1, reward_slots.get_child_count())
	var target_slot := reward_slots.get_child(spawn_index % slot_count) as Node2D
	var start_position := Vector2(target_slot.position.x, 48)
	var start_velocity := Vector2(randf_range(-18.0, 18.0), ball_speed)
	var ball := ball_scene.instantiate() as Node2D
	ball_container.add_child(ball)
	if ball.has_method("setup"):
		ball.call("setup", player_id, Rect2(Vector2.ZERO, panel_size), start_position, start_velocity, _get_ball_color())
	spawn_index += 1


func _on_reward_generated(event_player_id: int, reward_type: String) -> void:
	if event_player_id != player_id:
		return

	reward_counts[reward_type] = int(reward_counts.get(reward_type, 0)) + 1
	_update_counter_label()


func _update_counter_label() -> void:
	if counter_label == null:
		return

	var parts: Array[String] = []
	for reward_type in REWARD_TYPES:
		var count := int(reward_counts.get(reward_type, 0))
		parts.append("%s:%d" % [reward_type.left(1), count])
	counter_label.text = " ".join(parts)


func _get_player_color() -> Color:
	return PLAYER_COLORS.get(player_id, Color("#AAAAAA"))


func _get_ball_color() -> Color:
	return _get_player_color().lightened(0.35)
