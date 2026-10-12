# Living World — Design and Implementation Roadmap

**Motto:** “We create the conditions. The people create the world.”

## Vision

Living World is an Android-first, naturalistic 3D world simulation. The player generates a world, begins with exactly 100 human founders, then observes what happens. Human lives, family lines, wildlife, ecosystems, settlements, cultures, economies and histories should emerge from interacting rules rather than a fixed campaign or guaranteed civilization progression.

The game should aim for consistent, understandable cause and effect—not claim perfect real-world accuracy.

## Non-negotiable rules

- Every standard new world begins with exactly 100 human founders.
- Every future human must descend from those founders. Never spawn unrelated humans to refill a population.
- If every human descendant dies, human extinction is final for that world.
- Pure Observation is the default: the player observes and investigates, not directly commands people, societies or nature.
- New worlds use a random, displayed seed. The same seed and generation version should reproduce the world.
- World scale target: vast. Climate: varied. Resources: naturally distributed. Environmental challenges: natural. Current intervention mode: Pure Observation.
- Tools and materials must be physically appropriate. **A stick cannot break a rock.** Need does not create ability.
- People cannot know information they have not observed, learned, been told or reasonably inferred.
- Wildlife must not respawn artificially. Extinct species return only if surviving populations can naturally recolonise the area; global extinction is final.
- Ecosystem recovery, settlement growth and technological advancement are never guaranteed.
- Save/load must preserve identities, genealogy, locations, resources, history and ecological state without duplication or resurrecting the dead.
- Offline progression is not enabled by default.
- The current prototype is only a foundation. A feature is complete only after implementation and testing.

## World generation and environment

Generate varied terrain with coherent regions: hills, valleys, plains, mountains, rivers, lakes, forests, grasslands, wetlands, deserts and colder regions where supported. Terrain influences water, temperature, vegetation, resources and travel. Geology and ecosystems have a history before the founders arrive.

Resource distribution must reflect environmental conditions. Timber requires trees; fresh water must exist in reachable sources; fertile soil, stone, plants and prey vary by region. Disasters should affect only areas and organisms that could plausibly be affected. Drought influences water and food over time; fire requires suitable fuel and conditions; floods affect exposed lowlands.

The first playable version may use a smaller test map. The intended destination remains a vast, reproducible world.

## Human lives and survival

Each person should have a permanent unique ID, name, age, life stage, health, needs, skills, knowledge, personality tendencies, goals, possessions, location, family links, relationships and memories of important events.

People decide based on needs, ability, knowledge, risk, personality, relationships and local conditions. Actions require suitable tools, materials, time and skill. People can fail, learn, disagree, migrate, cooperate or make poor decisions.

Needs include food, water, rest, health, shelter and environmental comfort. Children depend on caregivers; families influence support, inheritance, migration and conflict. Births require valid parent identities. Ageing and death are permanent. Family lines can end and knowledge can be lost when its last holders die.

Relationships are mutual but not necessarily equal. Trust, affection, resentment, rivalry and obligation change through behaviour and shared experiences; proximity alone does not create a relationship.

## Wildlife and ecology

Species differ in diet, habitat, activity, senses, movement, territory, social structure, migration and reproduction. Plants depend on climate, soil, water, light and season. Populations change through births, deaths, movement and resource limits—not artificial respawning.

Food webs, competition, disease, habitat loss, resource depletion, regeneration and human land use should affect each other. Damage may be irreversible. Plant regrowth is natural growth, not instant resource refilling.

## Tools, knowledge and technology

Crafting requires appropriate materials, tools, knowledge, effort, time and conditions. Stone cannot be obtained by hitting it with any random object. Construction needs suitable materials and structural know-how. Fire, food preservation, metalworking and other techniques require their actual prerequisites.

Knowledge spreads through teaching, apprenticeship, observation, migration, trade and contact. It can be forgotten. Inventions emerge from circumstances and experimentation; no technology is guaranteed by the passage of time. There is no mandatory technology tree forcing every society along the same path.

## Society, settlement and history

Settlements emerge where people have reasons and means to stay. They may grow, remain small, split, move or disappear. Shared customs, leadership, rules, trade, language, beliefs, specialisation and institutions should emerge from social interactions and can differ between communities.

Migration can be driven by scarcity, danger, opportunity, climate, family ties, trade or conflict. Contact may lead to cooperation, exchange, intermarriage, avoidance, tension or violence. Conflict has costs and causes; it is not an arbitrary excitement generator.

Record births, deaths, family milestones, migration, disasters, discoveries, ecological changes, settlement changes, trade, conflict and cultural shifts. History should explain causes and consequences where the simulation has enough evidence. Every world should produce its own history, including stagnation, collapse or extinction where those outcomes arise.

## Simulation scale and performance

Use detail tiers:
- Local: nearby people, movement, interactions and immediate environmental effects.
- Regional: settlements, resource balances, travel, migration, births/deaths and trade.
- Distant: simplified but causally consistent updates.
- Deep time: summarise routine activity while retaining major events and their causes.

Do not update every distant entity every rendered frame. Profile memory, CPU, battery and thermal behaviour on Android. Prefer coherent, stable simulation over expensive visual effects. Fast-forward must not silently skip major life events.

## Interface

Primary sections should eventually be World, People, History, World Insights, Map and Settings/Save. Allow inspection of people, families, settlements, species, regions and events. Show population trends, genealogy, resource changes, migration and historical causes. Use readable touch controls, clear labels, accessible contrast and naturalistic 3D art rather than pixel art.

## Technical direction

- Engine: Godot 4.x.
- Language: GDScript.
- Target: Android first.
- Renderer: Compatibility unless device testing justifies a change.
- Source control and automated builds: GitHub.
- Systems should be modular and testable: generation, time, people, ecology, settlements, history, UI and persistence.
- Use data-driven definitions for materials, tools, species, needs and events.
- Keep save versions and diagnostic logs.
- Never claim an APK is ready until the latest build succeeds and the artifact is verified on a real device.

## Roadmap

1. **Foundation:** openable Godot project, 3D world, camera controls, time controls, save/load and verified Android APK.
2. **People:** 100 founders, unique IDs, movement, needs, health, personality and basic decision-making.
3. **Survival and ecology:** food, water, shelter, weather, plants, wildlife, resources, tools and natural hazards.
4. **Generations:** parentage, relationships, childhood, reproduction, family trees, ageing, death and knowledge transfer.
5. **Society:** households, settlements, construction, exchange, trade, culture, leadership, migration and conflict.
6. **Vast world:** regional/distant simulation, deep-time summaries, large-scale ecology and performance optimisation.
7. **History and polish:** searchable event timeline, causal explanations, charts, accessibility, save recovery and device testing.

## First genuinely playable milestone

1. Generate a seed-based landscape with several environmental regions.
2. Start exactly 100 founders.
3. Pause, resume and change simulation speed.
4. Let people move and respond to a small set of needs.
5. Record meaningful events and inspect a person.
6. Save and reload without duplicating people or losing state.
7. Export and test the Android APK.

A small reliable simulation is better than many nonfunctional systems. The first milestone is not the complete civilization simulator; it is a robust Android foundation on which the world can grow.

## Current implementation status

The repository currently contains a generated 3D landscape, a lake, tree and wild-food visuals, 100 founder agents, basic hunger/thirst behaviour, health consequences, plant regrowth, time controls, a person-inspection panel, touch pan/zoom and local save/load controls. These changes still require Godot CI validation and real-device testing. Family systems, descendants, wildlife simulation, settlements, culture, trade and deep-time history are future work.
