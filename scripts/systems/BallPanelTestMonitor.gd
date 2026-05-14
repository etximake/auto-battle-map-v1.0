extends Node


func _ready() -> void:
	EventBus.reward_generated.connect(_on_reward_generated)


func _on_reward_generated(player_id: int, reward_type: String) -> void:
	print("reward_generated P%d %s" % [player_id, reward_type])
