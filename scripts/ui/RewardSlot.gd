extends Area2D
class_name RewardSlot

@export var player_id: int = 0
@export var reward_type: String = "Scout"
@export var slot_size: Vector2 = Vector2(30, 26)
@export var slot_color: Color = Color("#FFFFFF")

@onready var background: Polygon2D = $Background
@onready var border: Line2D = $Border
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label


func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = 1 << 4
	area_entered.connect(_on_area_entered)
	_setup_visual()
	add_to_group("reward_slots")


func configure(new_player_id: int, new_reward_type: String, new_color: Color) -> void:
	player_id = new_player_id
	reward_type = new_reward_type
	slot_color = new_color
	_setup_visual()


func _setup_visual() -> void:
	if background == null or border == null or collision_shape == null or label == null:
		return

	var half_size := slot_size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	background.polygon = corners
	background.color = slot_color
	border.points = corners
	border.default_color = slot_color.darkened(0.45)

	var shape := RectangleShape2D.new()
	shape.size = slot_size
	collision_shape.shape = shape

	label.text = _get_short_label()
	label.position = Vector2(-half_size.x, -half_size.y)
	label.size = slot_size


func _get_short_label() -> String:
	if reward_type == "x2":
		return "x2"

	var label_text := ""
	for index in reward_type.length():
		var character := reward_type.substr(index, 1)
		if index == 0 or character == character.to_upper():
			label_text += character.to_upper()
		if label_text.length() >= 2:
			return label_text
	return reward_type.left(2).to_upper()


func _on_area_entered(area: Area2D) -> void:
	if area == null or not area.has_method("consume"):
		return
	if int(area.get("player_id")) != player_id:
		return

	var did_consume := bool(area.call("consume"))
	if not did_consume:
		return

	EventBus.reward_generated.emit(player_id, reward_type)
	if area.has_method("despawn"):
		area.call("despawn")
