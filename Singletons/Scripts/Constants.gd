class_name Constants

# Collision Layers
const LAYER_WORLD = 1 << 0    # Layer 1
const LAYER_ENEMY = 1 << 1    # Layer 2
const LAYER_ITEM = 1 << 2     # Layer 3
const LAYER_PLAYER = 1 << 3   # Layer 4
const LAYER_HITBOX = 1 << 4   # Layer 5
const LAYER_HURTBOX = 1 << 5  # Layer 6

# Common Layer Combinations
const MASK_PLAYER = LAYER_WORLD | LAYER_ENEMY | LAYER_ITEM  # Player collides with these
const MASK_ENEMY = LAYER_WORLD | LAYER_PLAYER  # Enemy collides with these 