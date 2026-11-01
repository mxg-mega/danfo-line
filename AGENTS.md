
# AGENTS.md — Danfo Line

Instructions for AI coding agents (agy, Claude Code, Cursor, Codex, etc.) working on this project.  
Read this file before making any changes.

## What this is
Danfo Line is a competitive neon line-art game for the “Hometown Hustle” theme.  
You are a danfo driver racing rival bus drivers to pick up roadside passengers and earn the most fare before the day ends.  
Core loop: steer across lanes → grab passengers before rivals → use boosts.  
Every bus leaves a glowing colored trail. Crashing costs fare. Highest fare when the day timer ends wins.  
Player vs bots only (no online multiplayer). Target: Web + Android for itch.io.  
Look: minimal neon on black, abstract line traffic, rhythmic engine/horn sounds.

## Engine & language
- Godot **4.6** (exact version in project.godot). Never use Godot 3 APIs or outdated 4.x patterns.
- Pure GDScript (no C#).
- Always use modern Godot 4 syntax:
  - `@export`, `@onready`, typed variables, `await`, `signal.emit()`, `signal.connect(callable)`
  - `CharacterBody2D` + `velocity` + `move_and_slide()` (no arguments)
  - `instantiate()` instead of `instance()`
  - Never `yield`, `export` (old), `onready` (old), `KinematicBody2D`, old `connect()`

## Project conventions
- Prefer composition over deep inheritance.
- Use signals for communication between systems (player, bots, passengers, UI, game manager).
- Static typing on every variable, parameter, and return type.
- Use `%UniqueName` or `@export` NodePath references instead of fragile `$Deep/Path` strings when possible.
- Keep scenes self-contained and reusable.
- Autoloads only for true globals (e.g. GameManager, AudioManager, FareTracker).
- One focused change per request. Explain what you changed and why.

## Architecture notes (current intent)
- Player bus and rival buses share similar base behavior (movement, trail, passenger pickup).
- Trails are visual (Line2D or similar) that persist and create the neon tangle.
- Passengers spawn roadside; first bus to reach them claims the fare.
- Bots have simple personalities (greedy, aggressive, cautious) that affect target selection and risk-taking.
- Day timer controls the match length. Highest fare at timer end wins.
- Crash → fare penalty (repairs).

## Style & art direction (do not deviate)
- Minimal neon on pure black background.
- Abstract line-art traffic / buses / passengers.
- Bright distinct colors per bus for trails and identity.
- No detailed sprites or photorealism. Keep everything clean, graphic, and readable at a glance.
- Sound: rhythmic engine loops, short horn stabs, pickup chimes, crash hits. Music should feel like a Lagos hustle / street pulse (but keep placeholder if assets are missing).

## Rules that must not break
1. Stay on Godot 4.6 APIs only. If unsure, check the official 4.6 docs or mark the code as **unverified**.
2. Never invent node types, methods, or properties.
3. Do not rename existing `@export` vars, signals, unique names, or scene files without explicit permission.
4. Prefer small, testable changes. After editing scripts, run a headless check when possible.
5. Do not add online multiplayer, heavy 3D, or systems outside the current day plan.
6. Keep performance in mind for Web export (simple drawing, limited particles, no expensive per-frame work).

## Common commands (adjust path to your Godot binary)
```bash
# Parse / syntax check a script
godot --headless --check-only --script res://path/to/script.gd

# Run the project headless (if useful for smoke tests)
godot --headless --path . --quit-after 5
```

## Current development plan (respect the day order)
- Day 1: Driving + trail (done or in progress)
- Day 2: Passengers + first rival bot
- Day 3: More bots, crash penalties, checkpoints, basic sound
- Day 4: Polish + export + submission (at least 2 h before 2 Nov deadline)

When implementing a feature, stick to the current day’s scope unless asked otherwise.

## How to work
1. Read `project.godot` and the relevant existing scenes/scripts first.
2. State assumptions about the scene tree if you cannot see it.
3. Implement the smallest complete change that solves the request.
4. Prefer typed GDScript + signals.
5. After changes, summarize:
   - What files were created/modified
   - How to test the change in the editor
   - Any remaining TODOs or open questions

## Help areas the team still needs
- Sound design & music direction
- Funny local bot names + personality tuning
- Visual polish (trail feel, neon glow, UI readability)

If a request touches these, propose options but do not invent final art/audio assets.

---
Update this file when architecture or conventions change so every agent session stays consistent.

