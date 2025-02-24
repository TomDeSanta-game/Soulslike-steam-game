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

### Trading System
- Interactive merchant NPCs throughout the world
- Streamlined merchant interface with:
  - Clear item displays with descriptions
  - Easy-to-use buy and sell buttons
  - Visual feedback for affordable items
  - Automatic price calculations
- Special item handling:
  - Lore Fragments are premium collectibles:
    - Merchants sell them for 250,000 souls
    - Players can sell them for 100,000 souls
    - Valuable ancient knowledge with no readable content
  - Celestial Tears have fixed value (50,000 souls)
  - Regular items sell for half their purchase price
  - Dynamic quantity tracking for merchant items
- Trading features:
  - Buy rare items with collected souls
  - Sell items for appropriate value based on type
  - Special fixed prices for unique items
  - Automatic inventory management
  - Sound effects for transactions

### Visual Effects & Aesthetics
- Dynamic shader effects for collectibles:
  - **Lore Fragments**: Mystical golden shader featuring:
    - Rotating light rays
    - Dynamic wave distortion
    - Pulsing glow effect
    - Edge highlighting
    - Camera focus effect on first encounter (2-second dramatic zoom)
    - Optional teleport effect with dissolve shader
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
  - Improved item buttons:
    - Stylish EAT button with green gradient
    - Smooth hover and click effects
    - Clear visual feedback
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

### Boss System
- Advanced boss AI behavior system using LimboAI
- Dynamic phase transitions with visual effects
- Customizable attack patterns and movement strategies

### Frost Guardian Boss
- Ice-themed boss with unique frost abilities
- Dynamic shader system:
  - Base frost shader for constant ice effects
  - Powered-up shader during phase transition
  - Enhanced visual effects at 50% health threshold
- Strategic AI behavior:
  - Intelligent target tracking
  - Phase-based combat patterns
  - Responsive movement system
- Combat mechanics:
  - Frost-based attacks with slowing effects
  - Power-up system at 50% health
  - Enhanced damage and speed in powered state

## Technical Details

### Shaders
- Custom frost shader implementation
- Dynamic power-up transition effects
- Real-time shader parameter updates

### AI System
- LimboAI integration for boss behavior
- Phase-based difficulty scaling
- Strategic target acquisition and tracking

## Installation

1. Install Godot 4.x
2. Clone this repository
3. Open the project in Godot
4. Run the game

## Controls

Movement & Combat:
- A/D or Left/Right Arrow: Move left/right
- Space: Jump
- Left Mouse Button: Attack
- R: Heal
- P: Dash
- M: Roll
- N: Slide
- G: Grab
- S: Shoot

Character Management:
- E: Open/Close Inventory
- L: Level Up Menu
- I: Interact

System Controls:
- ESC: Back/Pause
- Q: Quit
- \: Toggle Console
- X: Debug: Reduce Health
- `: Debug: Die Instantly

## Development

Built using:
- Godot 4.x
- GDScript
- Custom shader system for visual effects
- Custom frame data system for precise combat
- State machine for character control
- Signal system for event handling
- Modular boss system for easy expansion
- Extensible shader framework

## Contributing

Feel free to contribute to this project by:
1. Forking the repository
2. Creating a feature branch
3. Submitting a pull request

## License

[Your license information here]

## Credits

[Your credits information here]
