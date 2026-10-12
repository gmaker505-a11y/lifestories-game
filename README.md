# Living World

**“We create the conditions. The people create the world.”**

Living World is an Android-first Godot 4 project for a naturalistic, autonomous world simulation. The design target is a vast world where human lives, families, ecosystems and societies emerge through cause and effect rather than a fixed story.

## Current playable-foundation work

The current prototype includes:
- Seed-driven, procedurally generated 3D terrain.
- A lake, tree cover and wild-food plants.
- Exactly 100 original founder agents in a new standard world.
- Basic autonomous hunger/thirst decisions, movement, eating and drinking.
- Health consequences when survival needs remain unmet.
- Slow natural regrowth of plant food; no artificial human or animal respawning.
- Simulation pause and three time speeds.
- A person-inspection panel showing age, health, hunger, thirst and current action.
- Touchscreen drag-to-pan and pinch-to-zoom controls.
- Save/load controls using the device's local user://living_world.save file.
- A GitHub Actions workflow intended to validate the Godot project and export an Android debug APK.

This is an early foundation, not the completed game. Births and descendants, family relationships, wildlife populations, deep ecology, settlements, culture, trade and long-term history remain future milestones.

## Core rules

- Every standard new world starts with exactly 100 founders.
- Future humans must descend from those founders; unrelated humans must never spawn.
- If all human descendants die, extinction is final.
- Pure Observation is the default: the player watches and investigates rather than directly commanding people.
- Tools and materials must be physically appropriate. **A stick cannot break a rock.**
- Outcomes should have understandable causes; the simulation must not guarantee that every society advances or every ecosystem recovers.
- New worlds use a displayed seed so terrain and initial resource placement can be reproduced by the same project version.

## Open the project

Open project.godot with Godot 4.x. The main scene is scenes/main.tscn, and the current world prototype is in scripts/living_world.gd.

## Build status

Android APK creation is automated through .github/workflows/build-android.yml. An APK should only be considered ready when the latest workflow run succeeds and the uploaded artifact is verified. A successful GitHub commit alone does not prove that the APK builds or that the game has been tested on a phone.

## Roadmap

1. Verify Godot project parsing and Android APK export.
2. Stabilise the generated world, camera and save/load foundation.
3. Add needs, skills, memory, age and robust individual decision-making.
4. Add parentage, family trees, births, descendants and permanent death.
5. Add species-specific wildlife, ecological food webs and natural hazards.
6. Add tools, construction, settlement, knowledge and trade systems.
7. Add autonomous cultures, social systems, migration and conflict.
8. Add regional/distant simulation, deep-time history, performance and accessibility.

The full design plan remains broader than the current implementation. Features are complete only after they are implemented and tested.
