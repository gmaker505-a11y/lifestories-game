# Living World

**“We create the conditions. The people create the world.”**

Living World is a Godot 4 project for a naturalistic, autonomous world simulation on Android and iOS. The design target is a vast world where human lives, families, ecosystems and societies emerge through cause and effect rather than a fixed story.

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
- Save/load controls using the device's local `user://living_world.save` file.
- GitHub Actions workflows intended to validate the project and export Android and iOS builds.

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

Open `project.godot` with Godot 4.3. The main scene is `scenes/main.tscn`, and the current world prototype is in `scripts/living_world.gd`.

## Build status

- Android: `.github/workflows/build-android.yml` is intended to validate the project and export a debug APK.
- iOS: `.github/workflows/build-ios.yml` is intended to validate the project and export an iOS Xcode project archive on a macOS runner.

These workflows must finish successfully before their outputs can be treated as build-ready. The iOS export is not the same as an App Store-ready signed app: publishing to a physical iPhone or the App Store requires Apple signing credentials, provisioning and the usual Apple developer workflow. A GitHub commit alone does not prove the game builds or works on a device.

## Roadmap

1. Verify Godot project parsing and Android/iOS exports.
2. Stabilise the generated world, camera and save/load foundation.
3. Add needs, skills, memory, age and robust individual decision-making.
4. Add parentage, family trees, births, descendants and permanent death.
5. Add species-specific wildlife, ecological food webs and natural hazards.
6. Add tools, construction, settlement, knowledge and trade systems.
7. Add autonomous cultures, social systems, migration and conflict.
8. Add regional/distant simulation, deep-time history, performance and accessibility.

The full design plan remains broader than the current implementation. Features are complete only after they are implemented and tested.
