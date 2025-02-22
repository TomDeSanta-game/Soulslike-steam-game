# Soulslike Steam Game

A challenging 2D soulslike game built in Godot 4, featuring precise combat mechanics, RPG elements, and beautiful visual effects.

## Features

### Core Mechanics
- Souls-like combat system with precise hitboxes and hurtboxes
- Stamina management for attacks and special moves
- Health system with healing mechanics
- Inventory system for items and equipment
- Experience and leveling system
- Souls collection and management
  - Collect souls from defeating enemies
  - Celestial Tears grant exactly 50,000 souls and 100,000 XP
  - Souls can be spent on leveling up and items
  - Lost souls can be recovered after death
- Trading system with merchants
  - Buy rare items like Celestial Tears
  - Sell collected items for souls
  - Dynamic pricing system
  - Interactive merchant NPCs throughout the world

### Visual Effects & Aesthetics
- Dynamic shader effects for collectibles:
  - **Lore Fragments**: Mystical golden shader featuring:
    - Rotating light rays
    - Dynamic wave distortion
    - Pulsing glow effect
    - Edge highlighting
  - **Celestial Tears**: Ethereal blue glow with smooth pulsing
- Enhanced UI Elements:
  - Dynamic health bar with:
    - Color transitions based on health level
    - Smooth value transitions
    - Impact flash effects
    - Screen shake on major hits
  - Responsive stamina bar featuring:
    - Color changes reflecting stamina state
    - Pulsing effect at low stamina
    - Smooth regeneration animation
    - Usage feedback effects
- Smooth character animations
- Visual feedback for all actions
- Particle effects for impacts and interactions

### Combat System
- Frame-perfect attack animations
- Multiple attack types and combos
- Dodge rolling with i-frames
- Parrying system
- Enemy AI with varied attack patterns
- Lifesteal mechanics
- Stamina management

### RPG Elements
- Character stats:
  - Vigor (Health)
  - Endurance (Stamina)
  - Strength
  - Dexterity
  - Intelligence
  - Faith
- Level up system with stat allocation
- Item collection and management
- Lore discovery through collectible fragments
- Trading and economy system
  - Multiple merchants with unique inventories
  - Buy and sell items using souls as currency
  - Rare items available for purchase
  - Lore fragments can be traded

### Movement & Exploration
- Precise platforming controls
- Wall climbing mechanics
- Dash ability with afterimages
- Double jump capability
- Environmental hazards
- Secret areas

## Installation

1. Install Godot 4.x
2. Clone this repository
3. Open the project in Godot
4. Run the game

## Controls

- WASD/Arrow Keys: Movement
- Space: Jump
- Shift: Dash
- Left Click: Attack
- Right Click: Block/Parry
- E: Interact
- I: Inventory
- ESC: Menu

## Development

Built using:
- Godot 4.x
- GDScript
- Custom shader system for visual effects
- Custom frame data system for precise combat
- State machine for character control
- Signal system for event handling

## Contributing

Feel free to contribute to this project by:
1. Forking the repository
2. Creating a feature branch
3. Submitting a pull request

## License

[Your license information here]

## Credits

[Your credits information here]
