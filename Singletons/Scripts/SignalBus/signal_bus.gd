extends Node

# Character Signals
@warning_ignore("unused_signal")
signal health_changed(new_health: float, max_health: float)
@warning_ignore("unused_signal")
signal character_died(character: Node)

# Combat Signals
@warning_ignore("unused_signal")
signal hit_landed(hitbox: Node, hurtbox: Node)
@warning_ignore("unused_signal")
signal hit_taken(hitbox: Node, hurtbox: Node)
@warning_ignore("unused_signal")
signal attack_started(attacker: Node)
@warning_ignore("unused_signal")
signal attack_ended(attacker: Node)

# Player Signals
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal player_respawned
@warning_ignore("unused_signal")
signal player_state_changed(new_state: String)

# Enemy Signals
@warning_ignore("unused_signal")
signal enemy_died(enemy: Node)
@warning_ignore("unused_signal")
signal player_detected(enemy: Node, player: Node)
@warning_ignore("unused_signal")
signal player_lost(enemy: Node, player: Node)

# Projectile Signals
@warning_ignore("unused_signal")
signal projectile_expired(projectile: Node)
@warning_ignore("unused_signal")
signal projectile_hit(projectile: Node, target: Node)

# Trap Signals
@warning_ignore("unused_signal")
signal trap_expired(trap: Node)
@warning_ignore("unused_signal")
signal trap_hit(trap: Node, target: Node)

# NPC Signals
@warning_ignore("unused_signal")
signal chat_started(npc: Node, player: Node)
@warning_ignore("unused_signal")
signal chat_ended(npc: Node, player: Node)

# Game State Signals
@warning_ignore("unused_signal")
signal bonfire_activated(bonfire: Node)
@warning_ignore("unused_signal")
signal game_saved
@warning_ignore("unused_signal")
signal game_loaded

# Combat Status Signals
@warning_ignore("unused_signal")
signal invincibility_started(entity: Node)
@warning_ignore("unused_signal")
signal invincibility_ended(entity: Node)

# Collectible Signals
@warning_ignore("unused_signal")
signal collectible_collected(collectible: Node)

func _ready() -> void:
	Log.info("SignalBus initialized and ready to handle game signals")
