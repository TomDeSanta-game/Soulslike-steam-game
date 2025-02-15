# Soulslike Steam Game

A 2D action-platformer game developed in Godot 4, inspired by the Soulslike genre. This project implements advanced game mechanics, combat systems, and state management to create an engaging player experience.

## 🎮 Features

### Player Mechanics
- **Advanced Movement System**
  - Smooth acceleration and deceleration
  - Precise jump mechanics with jump-cutting
  - Multiple movement states (walk, run, crouch)
  - State-based animations

### Combat System
- **Frame-Perfect Combat**
  - Hitbox/Hurtbox system with frame data
  - Multiple attack types (standing, running, jumping, crouching)
  - Visual debugging for hitboxes and hurtboxes
  - Damage system with knockback
  - Advanced lifesteal mechanics
    - Percentage-based health recovery
    - Configurable min/max healing amounts
    - Visual feedback effects

### Character States
- **Robust State Machine**
  - Idle, Run, Jump, Attack, Crouch states
  - Smooth state transitions
  - State-specific behaviors and animations

### Technical Features
- **Advanced Animation System**
  - Frame-by-frame animation control
  - Animation state management
  - Sprite flipping with hitbox adjustments

- **Health System**
  - Health regeneration
  - Damage handling
  - Visual feedback (shaders, UI)
  - Death sequence with fade effect

- **Visual Effects**
  - Screen shake on impacts
  - Shader-based damage effects
  - Death fade effect
  - Debug visualization for hitboxes/hurtboxes

## 🏗️ Project Structure

```
.
├── Entities/           # Game entities (Player, Enemies, etc.)
│   └── scripts/       # Entity-specific scripts
├── FrameData/         # Frame data system implementation
├── FrameDataResources/# Frame data resources for animations
├── Components/        # Reusable game components
├── Globals/          # Global configurations and constants
├── Shaders/          # Visual effect shaders
├── Singletons/       # Global singleton managers
├── assets/           # Game assets (sprites, sounds, etc.)
├── camera/           # Camera system implementation
├── character_base/   # Base character functionality
├── levels/           # Game levels and scenes
└── main/            # Main game setup and initialization
```

## 🔧 Technical Implementation

### Frame Data System
The game uses a sophisticated frame data system for combat, allowing precise control over:
- Hitbox positioning and timing
- Hurtbox definitions
- Attack frames and damage values
- Visual debugging tools

### State Machine
The player controller uses a state machine pattern for:
- Clean state transitions
- Isolated state behavior
- Easy addition of new states
- Maintainable codebase

### Movement System
Features a physics-based movement system with:
- Frame-based acceleration/deceleration
- Configurable movement speeds
- State-specific movement behaviors
- Jump mechanics with variable height control

## 🎯 Core Systems

### Combat
- Frame-perfect hit detection
- Multiple attack types
- State-based combat animations
- Visual feedback systems
- **Lifesteal System**
  - Percentage-based health recovery on successful hits
  - Configurable minimum and maximum healing thresholds
  - Visual shader effects for healing feedback
  - Sound effects for successful lifesteal
  - Strategic combat healing mechanics

### Animation
- Sprite-based animation system
- State-driven animation changes
- Frame-by-frame control
- Debug visualization tools

### Health Management
- Health regeneration system
- Damage handling with visual feedback
- Lifesteal-based health recovery
- Death sequence management
- UI health display

## 🚀 Getting Started

1. Clone the repository
2. Open the project in Godot 4
3. Run the main scene to start the game

## 🛠️ Development

### Prerequisites
- Godot 4.x
- Basic understanding of GDScript
- Knowledge of 2D game development concepts

### Setup
1. Install Godot 4.x
2. Clone this repository
3. Open project.godot in Godot
4. Start developing!

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 🎨 Credits
- Game Engine: Godot 4
- Development: [Your Name/Team]
- Assets: [List asset credits here]
