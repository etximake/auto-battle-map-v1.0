extends Node

var player_count: int = 4
var player_colors: Array[Color] = [
	Color("#E74C3C"),
	Color("#3498DB"),
	Color("#2ECC71"),
	Color("#F1C40F"),
	Color("#1ABC9C"),
	Color("#9B59B6"),
]

var round_duration: float = 75.0
var rounds_per_session: int = 10
var auto_restart: bool = true

var gold_per_second: float = 5.0
var gold_max: int = 50
var starting_gold: int = 10

var time_scale: float = 1.0

var ai_strategies: Array[String] = [
	"AGGRESSIVE",
	"BALANCED",
	"ECONOMY",
	"ADAPTIVE",
]


func get_player_color(player_id: int) -> Color:
	if player_id >= 0 and player_id < player_colors.size():
		return player_colors[player_id]

	return Color("#AAAAAA")
