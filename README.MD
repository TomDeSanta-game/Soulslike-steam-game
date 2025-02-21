# Soulslike Steam Game

A 2D action-platformer game developed in Godot 4.

## Features

### Souls and XP System
- Souls serve as both currency and experience points
- Souls can be gained from:
  - Defeating enemies
  - Collecting rare items
  - Finding celestial tears (50,000 souls)
- XP/Level System:
  - Souls can be spent to level up
  - Each level requires progressively more souls
  - Multiple stats can be improved:
    - Vigour (Health)
    - Endurance (Stamina)
    - Strength (Physical damage)
    - Dexterity (Attack speed)
    - Intelligence (Magic damage)
    - Faith (Healing power)
  - Press 'L' to open the level-up menu
  - Visual display of current souls and XP needed
  - Automatic level-up effects and sounds

### UI
- Health bar:
  - Red progress bar showing current health
  - Smooth visual feedback
  - Rounded corners for modern look
- Stamina bar:
  - Green progress bar showing current stamina
  - Updates dynamically with actions
  - Visual feedback for stamina consumption
- Game Over Screen:
  - Appears when player dies
  - Dark background with red "YOU DIED!" text
  - Press space to restart level
  - Smooth transition between scenes

### Movement
- Jump mechanics:
  - Coyote time (150ms to jump after leaving platform)
  - Jump buffering (150ms to press jump before landing)
  - Variable jump height
  - Full air control with proper animations
- Walk, run, and crouch
- Dash:
  - Quick burst of speed
  - Costs 50 stamina
  - 0.1 second duration
  - Instant activation
- Roll:
  - Short defensive maneuver
  - Costs 10 stamina
  - Smooth position transition
  - 0.5 second duration

### Combat
- Basic attacks (standing, running, jumping, crouching)
- Hitbox/Hurtbox system
- Lifesteal on hits
- Damage and knockback

### Character
- Health system with regeneration
- Stamina system:
  - Attack costs: Basic (10), Run (20)
  - Dash cost: 50 stamina
  - Roll cost: 10 stamina
  - Running drains stamina
  - Auto regeneration when not attacking/running

### Collectibles
- Celestial Tears:
  - Extremely rare and powerful items
  - Grants 50,000 souls when collected
  - Can be used from inventory to restore health and stamina
  - Features beautiful glow effects and animations
  - Provides visual and sound feedback on collection
  - Automatic cleanup after collection

### Save System
- Bonfire checkpoints
- Save/load game state
- Restore health/stamina at bonfires

### Technical Features
- Centralized signal bus for event handling
- Structured logging system with multiple levels:
  - Debug: Development information
  - Info: General game state updates
  - Warn: Potential issues
  - Error: Runtime errors
  - Fatal: Critical failures

## Inventory System
The game features an inventory system that allows players to collect and manage various items:

### Features
- Press 'I' to open/close the inventory
- Visual display of collected items with their quantities
- Support for various collectible items including Celestial Tears
- Grid-based inventory layout
- Automatic item stacking for multiple instances of the same item
- Item usage system with dedicated use functions
- Interactive item usage:
  - Hover over items to reveal usage options
  - "EAT" button appears next to consumable items
  - Button remains visible for 1.5 seconds after moving mouse away
  - Extended interaction window for easier item usage
  - Items are automatically removed when consumed
  - Quantity tracking for multiple items
  - Automatic UI cleanup after item usage
- Separation of collection and usage mechanics
- Pause system integration:
  - Game pauses when inventory is open
  - Automatically unpauses after item usage

### Items
- **Celestial Tear**: A rare crystallized tear from the heavens that can be used from inventory to restore full health and stamina.
  - Hover over the tear to reveal the "EAT" button
  - Button stays visible for 1.5 seconds after moving mouse away
  - Click "EAT" to consume and restore health/stamina
  - Provides visual and sound feedback when used
  - Automatically removed from inventory when consumed
  - Quantity decreases by one when used
  - Instantly restores full health and stamina
  - Triggers healing visual effects and sounds
  - Features animated shader effects in inventory
  - Displays full celestial tear animation while in inventory slots
  - Maintains consistent visual appearance between world and inventory

## Controls

### Movement
- **LEFT/RIGHT**: Arrow keys or A/D
- **UP**: Up arrow key (for wall climbing)
- **CROUCH**: Down arrow key
- **JUMP**: Spacebar
- **DASH**: D key (costs 50 stamina)
- **ROLL**: M key (costs 10 stamina)
- **GRAB**: G key (for wall hanging)

### Combat
- **ATTACK**: Left mouse button
- **SHOOT**: S key
- **HEAL**: R key

### Inventory
- **INVENTORY**: I key (toggle inventory)
- **LEFT CLICK**: Hover over items to show usage options
- **EAT BUTTON**: Click to consume selected item (remains visible while hovering)

### Debug/Testing
- **HEALTH_DOWN**: X key (decrease health)
- **DIE**: ` key (instant death)
- **BACK/QUIT**: ESC key or Q key

## Project Structure

### Asset Organization
- `assets/Player/Individual Sprites/`: Contains all player character animations
  - Includes sprite sheets for all player states (Attack, Idle, Run, Jump, etc.)
  - Organized by action type with consistent naming (_Attack.png, _Idle.png, etc.)
  - Used by the player scene for all animations

### Technical Details
- Built with Godot 4.x
- Uses custom state machine implementation
- Frame-perfect hit detection system
- Shader-based visual effects
- Sound management system

### Collision Layer System
- Layer 1: World/Environment
- Layer 2: Enemies
- Layer 3: Projectiles
- Layer 4: Player
- Layer 5: NPCs
- Layer 6: Collectibles
- Layer 7: Hitboxes
- Layer 8: Hurtboxes

### Death and Item Recovery System
- Dark Souls-like death mechanics:
  - On death, all inventory items are dropped in a bag
  - Bag spawns at player's death location and falls with gravity
  - Items can be recovered by touching the bag
  - Visual feedback when recovering items
  - Sound effects on item recovery
  - Automatic bag cleanup after recovery
  - Items are permanently lost if player dies before recovery
  - Advanced bag positioning system:
    - Uses 6 raycasts for precise ground detection
    - Raycasts positioned at -30, -20, -10, 10, 20, and 30 units from center
    - Automatically teleports to furthest valid position to prevent wall clipping
    - Smart gravity system with terminal velocity
    - Ensures bags always land in accessible locations
