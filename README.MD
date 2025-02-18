# Soulslike Steam Game

A 2D action-platformer game developed in Godot 4.

## Features

### UI
- Health bar:
  - Red progress bar showing current health
  - Smooth visual feedback
  - Rounded corners for modern look
- Stamina bar:
  - Green progress bar showing current stamina
  - Updates dynamically with actions
  - Visual feedback for stamina consumption

### Movement
- Jump mechanics:
  - Coyote time (150ms to jump after leaving platform)
  - Jump buffering (150ms to press jump before landing)
  - Variable jump height
- Walk, run, and crouch

### Combat
- Basic attacks (standing, running, jumping, crouching)
- Hitbox/Hurtbox system
- Lifesteal on hits
- Damage and knockback

### Character
- Health system with regeneration
- Stamina system:
  - Attack costs: Basic (10), Run (20), Jump (40)
  - Running drains stamina
  - Auto regeneration when not attacking/running

### Collectibles
- Celestial Tears:
  - Restore health and stamina on collection
  - Visual and sound effects on pickup
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

## Project Structure

## Controls

## Technical Details
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
