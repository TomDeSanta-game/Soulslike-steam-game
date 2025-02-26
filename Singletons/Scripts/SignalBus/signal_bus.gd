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
@warning_ignore("unused_signal")
signal on_create_projectile(position: Vector2, direction: Vector2, life_span: float, speed: float, bullet_key: String)

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

# Inventory Signals
@warning_ignore("unused_signal")
signal item_used(item_data: Dictionary)

# Souls Signals
@warning_ignore("unused_signal")
signal souls_changed(new_amount: int)
@warning_ignore("unused_signal")
signal souls_lost(amount_lost: int)
@warning_ignore("unused_signal")
signal souls_recovered(amount_recovered: int)

# Trade Signals
@warning_ignore("unused_signal")
signal trade_completed(item_id: String, souls_gained: int)

# XP System Signals
@warning_ignore("unused_signal")
signal level_up_started
@warning_ignore("unused_signal")
signal level_up_completed(new_level: int)
@warning_ignore("unused_signal")
signal stat_point_gained
@warning_ignore("unused_signal")
signal stat_increased(stat_name: String, new_value: int)

# Boss Signals
@warning_ignore("unused_signal")
signal boss_damaged(boss: Node, current_health: float, max_health: float)
@warning_ignore("unused_signal")
signal boss_defeated(boss: Node)
@warning_ignore("unused_signal")
signal boss_phase_changed(boss: Node, phase: int)
@warning_ignore("unused_signal")
signal boss_attack_started(boss: Node, attack_name: String)
@warning_ignore("unused_signal")
signal boss_spawned(boss: Node)
@warning_ignore("unused_signal")
signal boss_died(boss: Node) 
