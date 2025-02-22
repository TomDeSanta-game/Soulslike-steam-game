extends Node

signal level_up(new_level: int, available_points: int)
signal stat_increased(stat_name: String, new_value: int)
signal xp_gained(amount: int)

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
var current_xp: int = 0
var total_xp_gained: int = 0
var available_points: int = 0

# Calculate XP needed for next level
func get_xp_for_next_level() -> int:
	return int(BASE_STAT_COST * pow(current_level, 1.5))

# Add XP directly and level up if possible
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	
	# First emit the signal for the full amount
	xp_gained.emit(amount)
	
	# Add to total XP first
	total_xp_gained += amount
	
	# Add to current XP
	current_xp += amount
	
	# Handle level ups
	var levels_gained = 0
	while true:
		var required_xp = get_xp_for_next_level()
		if current_xp >= required_xp:
			current_xp -= required_xp
			current_level += 1
			available_points += 1
			levels_gained += 1
		else:
			break
	
	# If we gained levels, emit signals
	if levels_gained > 0:
		level_up.emit(current_level, available_points)

# Get total XP gained
func get_total_xp() -> int:
	return total_xp_gained

# Format XP amount for display
func format_xp(amount: int) -> String:
	var str_amount = str(amount)
	var length = str_amount.length()
	var formatted = ""
	var count = 0
	
	for i in range(length - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_amount[i] + formatted
		count += 1
	
	return formatted

# Reset XP (for testing/debugging)
func reset_xp() -> void:
	current_xp = 0
	total_xp_gained = 0
	current_level = 1
	available_points = 0

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
			if player.has_method("set_endurance"):
				player.set_endurance(stats.endurance)
		"strength":
			if player.has_method("set_strength"):
				player.set_strength(stats.strength)
		"dexterity":
			if player.has_method("set_dexterity"):
				player.set_dexterity(stats.dexterity)
		"intelligence":
			if player.has_method("set_intelligence"):
				player.set_intelligence(stats.intelligence)
		"faith":
			if player.has_method("set_faith"):
				player.set_faith(stats.faith)

# Save XP system state
func save() -> Dictionary:
	var save_data = {
		"stats": stats.duplicate(),
		"current_level": current_level,
		"current_xp": current_xp,
		"total_xp_gained": total_xp_gained,
		"available_points": available_points
	}
	return save_data

# Load XP system state
func load(data: Dictionary) -> void:
	if data.has("stats"):
		stats = data.stats.duplicate()
	if data.has("current_level"):
		current_level = data.current_level
	if data.has("current_xp"):
		current_xp = data.current_xp
	if data.has("total_xp_gained"):
		total_xp_gained = data.total_xp_gained
	if data.has("available_points"):
		available_points = data.available_points 