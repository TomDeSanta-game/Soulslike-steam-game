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
  - Simplified and robust Hitbox/Hurtbox system
    - Always-active base hitboxes and hurtboxes
    - Proper collision layer management
    - Automatic activation on component creation
    - Streamlined damage and knockback handling
  - Advanced Frame Data Integration
    - Base hitboxes remain active for consistent collision
    - Frame data controls hitbox positioning and properties
    - Smooth transitions between attack animations
    - Automatic frame updates and position management
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

### Stamina System
- Dynamic stamina management (100 points max)
- Different stamina costs for actions:
  - Basic Attack: 10 stamina
  - Run Attack: 20 stamina
  - Jump Attack: 40 stamina
  - Running: Gradually drains stamina (30 seconds to empty)
- Automatic stamina regeneration when not attacking or running
- Actions blocked when insufficient stamina

### Checkpoint System
- Dark Souls inspired bonfire checkpoints
- Save and load system using both Resource and JSON formats
- Automatic state saving at bonfires
- Player spawns 5 units left of the last activated bonfire
- Full health/stamina/magic restoration at bonfires

## ��️ Project Structure

``