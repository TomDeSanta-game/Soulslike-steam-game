# Soulslike Steam Game

A 2D action-platformer game developed in Godot 4.

## Features

### Movement
- Jump mechanics:
  - Coyote time (150ms to jump after leaving platform)
  - Jump buffering (150ms to press jump before landing)
  - Variable jump height
- Walk, run, and crouch
- Direction changes with turn animation

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
