extends Area2D
class_name PlayerBase

@export var player_id: int = 0
@export var max_hp: float = 500.0
@export var spawn_cooldown: float = 1.0
@export var queue_limit: int = 40

var current_hp: float = 100.0
var reward_queue: Array[String] = []
var spawn_timer: float = 0.0
var is_destroyed: bool = false
var last_attacker_player: int = -1

@onready var body: Polygon2D = $Body
@onready var hp_bar: ProgressBar = $HPBar
@onready var label: Label = $Label
@onready var queue_label: Label = $QueueLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("bases")
	add_to_group("castles")
	EventBus.round_reset_requested.connect(reset_base)
	EventBus.unit_reached_castle.connect(_on_unit_reached_castle)
	max_hp = GameConfig.castle_max_hp
	spawn_cooldown = GameConfig.castle_spawn_cooldown
	queue_limit = GameConfig.castle_queue_limit
	current_hp = max_hp
	_setup_visual()
	_update_display()


func _process(delta: float) -> void:
	if is_destroyed:
		return
	spawn_timer = maxf(spawn_timer - delta, 0.0)
	if spawn_timer > 0.0 or reward_queue.is_empty():
		return

	_spawn_next_reward()


func queue_reward(reward_type: String) -> bool:
	if is_destroyed:
		return false
	if reward_queue.size() >= queue_limit:
		return false
	if not _is_unit_reward(reward_type):
		return false

	reward_queue.append(reward_type)
	_update_display()
	return true


func take_damage(amount: float, attacker_player: int) -> void:
	if is_destroyed:
		return
	last_attacker_player = attacker_player
	current_hp = maxf(current_hp - amount, 0.0)
	_update_display()
	EventBus.castle_damaged.emit(self, amount, attacker_player)
	EventBus.base_damaged.emit(self, amount, attacker_player)

	if current_hp <= 0.0:
		is_destroyed = true
		EventBus.castle_destroyed.emit(self)
		EventBus.base_destroyed.emit(self)


func reset_base() -> void:
	current_hp = max_hp
	is_destroyed = false
	last_attacker_player = -1
	reward_queue.clear()
	spawn_timer = 0.0
	_update_display()


func _on_unit_reached_castle(unit: Node, target_base: Node) -> void:
	if target_base != self:
		return

	var unit_damage := float(unit.get("damage"))
	var attacker_id := int(unit.get("player_id"))
	var multiplier := GameConfig.get_auto_battle_value("castle_unit_damage_multiplier", 1.0)
	take_damage(unit_damage * multiplier, attacker_id)


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
	if queue_label != null:
		queue_label.text = "Q:%d" % reward_queue.size()


func _spawn_next_reward() -> void:
	var unit_type: String = reward_queue.pop_front()
	spawn_timer = spawn_cooldown
	_update_display()

	var spawn_manager := _get_spawn_manager()
	if spawn_manager == null or not spawn_manager.has_method("spawn_unit"):
		push_warning("No SpawnManager available for castle P%d." % player_id)
		return

	EventBus.reward_consumed.emit(player_id, unit_type)
	EventBus.castle_spawn_requested.emit(player_id, unit_type)
	if GameConfig.is_open_field_movement():
		var empty_route: Array[Vector2] = []
		spawn_manager.call("spawn_unit", player_id, unit_type, empty_route, _get_objective_player_id(unit_type))
	else:
		spawn_manager.call("spawn_unit", player_id, unit_type, _get_route_for_unit(unit_type))


func _get_spawn_manager() -> Node:
	var managers := get_tree().get_nodes_in_group("spawn_managers")
	if managers.is_empty():
		return null
	return managers[0]


func _get_route_for_unit(unit_type: String) -> Array[Vector2]:
	var ai := _get_ai_controller()
	if ai != null and ai.has_method("choose_target_player") and ai.has_method("choose_route"):
		var target_id := int(ai.call("choose_target_player", unit_type))
		var route: Array[Vector2] = []
		route.assign(ai.call("choose_route", unit_type, target_id))
		if not route.is_empty():
			return route

	var game_map := get_tree().get_first_node_in_group("game_maps")
	if game_map != null and game_map.has_method("get_march_path"):
		var fallback: Array[Vector2] = []
		fallback.assign(game_map.call("get_march_path", player_id))
		return fallback

	return []


func _get_objective_player_id(unit_type: String) -> int:
	var ai := _get_ai_controller()
	if ai != null and ai.has_method("choose_objective_player"):
		return int(ai.call("choose_objective_player", unit_type))
	if ai != null and ai.has_method("choose_target_player"):
		return int(ai.call("choose_target_player", unit_type))
	return -1


func _get_ai_controller() -> Node:
	for ai in get_tree().get_nodes_in_group("ai_controllers"):
		if int(ai.get("player_id")) == player_id:
			return ai
	return null


func _is_unit_reward(reward_type: String) -> bool:
	return GameConfig.is_unit_type(reward_type)


func _make_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in point_count:
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	return points
