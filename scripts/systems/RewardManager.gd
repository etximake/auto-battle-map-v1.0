extends Node


func _ready() -> void:
	EventBus.reward_generated.connect(_on_reward_generated)
	add_to_group("reward_managers")


func _on_reward_generated(player_id: int, reward_type: String) -> void:
	var castle := _find_castle(player_id)
	if castle == null:
		push_warning("No castle found for reward player %d." % player_id)
		return
	if not castle.has_method("queue_reward"):
		push_warning("Castle for player %d cannot queue rewards." % player_id)
		return

	var queued := bool(castle.call("queue_reward", reward_type))
	if queued:
		EventBus.reward_queued.emit(player_id, reward_type)


func _find_castle(player_id: int) -> Node:
	for castle in get_tree().get_nodes_in_group("castles"):
		if int(castle.get("player_id")) == player_id:
			return castle

	for base in get_tree().get_nodes_in_group("bases"):
		if int(base.get("player_id")) == player_id:
			return base

	return null
