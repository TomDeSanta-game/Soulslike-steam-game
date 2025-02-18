extends Node
class_name C_Layers

# Collision Layers (using 1-based layer numbers)
const LAYER_WORLD = 1 << 0       # Layer 1: World/Environment
const LAYER_ENEMY = 1 << 1       # Layer 2: Enemies
const LAYER_PROJECTILES = 1 << 2  # Layer 3: Projectiles
const LAYER_PLAYER = 1 << 3      # Layer 4: Player
const LAYER_NPC = 1 << 4         # Layer 5: NPCs
const LAYER_COLLECTIBLE = 1 << 5  # Layer 6: Collectibles
const LAYER_HITBOX = 1 << 6      # Layer 7: Hitboxes
const LAYER_HURTBOX = 1 << 7     # Layer 8: Hurtboxes

# Common Layer Combinations (Masks)
const MASK_PLAYER = LAYER_WORLD | LAYER_ENEMY | LAYER_PROJECTILES | LAYER_COLLECTIBLE
const MASK_ENEMY = LAYER_WORLD | LAYER_PLAYER | LAYER_PROJECTILES
const MASK_PROJECTILES = LAYER_WORLD | LAYER_ENEMY | LAYER_PLAYER
const MASK_NPC = LAYER_WORLD | LAYER_PLAYER
const MASK_COLLECTIBLE = LAYER_PLAYER
const MASK_HITBOX = LAYER_HURTBOX
const MASK_HURTBOX = LAYER_HITBOX 