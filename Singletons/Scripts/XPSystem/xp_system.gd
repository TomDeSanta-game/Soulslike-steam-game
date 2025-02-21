extends Node

signal level_up(new_level: int, available_points: int)
signal stat_increased(stat_name: String, new_value: int)

# Player Stats
var stats: Dictionary = {
	"level": 1,
	"vigour": 10,  # Health
	"endurance": 10,  # Stamina
	"strength": 10,  # Physical damage
	"dexterity": 10,  # Attack speed and some damage
	"intelligence": 10,  # Magic damage
	"faith": 10,  # Miracles and healing
}

# Stat costs and limits
const MAX_STAT_VALUE: int = 99
const MIN_STAT_VALUE: int = 1
const BASE_STAT_COST: int = 500

# XP/Level data
var current_level: int = 1
var available_points: int = 0

# Calculate souls needed for next level
func get_souls_for_next_level() -> int:
	# Formula: base_cost * (current_level ^ 1.5)
	return int(BASE_STAT_COST * pow(current_level, 1.5))

# Try to level up using current souls
func try_level_up() -> bool:
	var souls_system = get_node("/root/SoulsSystem")
	if not souls_system:
		return false
		
	var required_souls = get_souls_for_next_level()
	if souls_system.get_souls() >= required_souls:
		if souls_system.spend_souls(required_souls):
			current_level += 1
			available_points += 1
			level_up.emit(current_level, available_points)
			return true
	return false

# Increase a specific stat if we have points available
func increase_stat(stat_name: String) -> bool:
	if available_points <= 0:
		return false
		
	if not stats.has(stat_name):
		return false
		
	if stats[stat_name] >= MAX_STAT_VALUE:
		return false
		
	stats[stat_name] += 1
	available_points -= 1
	stat_increased.emit(stat_name, stats[stat_name])
	
	# Update player stats based on what was increased
	_update_player_stats(stat_name)
	
	return true

# Get current value of a stat
func get_stat(stat_name: String) -> int:
	return stats.get(stat_name, 0)

# Get all stats
func get_stats() -> Dictionary:
	return stats.duplicate()

# Update player's stats when they change
func _update_player_stats(stat_name: String) -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return
		
	var player = players[0]
	
	match stat_name:
		"vigour":
			if player.has_method("set_vigour"):
				player.set_vigour(stats.vigour)
		"endurance":
			# Update stamina
			if player.has_method("set_endurance"):
				player.set_endurance(stats.endurance)
		"strength":
			# Update physical damage
			if player.has_method("set_strength"):
				player.set_strength(stats.strength)
		"dexterity":
			# Update attack speed and damage
			if player.has_method("set_dexterity"):
				player.set_dexterity(stats.dexterity)
		"intelligence":
			# Update magic damage
			if player.has_method("set_intelligence"):
				player.set_intelligence(stats.intelligence)
		"faith":
			# Update healing and miracle power
			if player.has_method("set_faith"):
				player.set_faith(stats.faith)

# Save XP system state
func save() -> Dictionary:
	return {
		"stats": stats,
		"current_level": current_level,
		"available_points": available_points
	}

# Load XP system state
func load(data: Dictionary) -> void:
	if data.has("stats"):
		stats = data.stats.duplicate()
	if data.has("current_level"):
		current_level = data.current_level
	if data.has("available_points"):
		available_points = data.available_points 