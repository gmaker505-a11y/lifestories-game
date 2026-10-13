# Blockside: Medieval Realms

A mobile-first, top-down medieval co-op adventure prototype for Android and iOS browsers.

## Play the prototype

Open `index.html` in a browser, or enable GitHub Pages for this repository and open the `/blockside/` path on the published site.

## Design target

- Small private party: **maximum 4 players total** (host plus up to 3 friends).
- Medieval village, forests, dirt roads, villagers and countryside.
- Touchscreen movement controls, with keyboard controls for desktop testing.
- Gather wood and berries, explore and talk to villagers.
- Cozy role-playing/adventure tone, designed for mobile screens.
- Future native app route: package the web prototype with a mobile wrapper after the gameplay and networking are stable.

## Current status

The current build is an early playable local prototype. It has a procedural-feeling village map, movement, gathering and basic interaction. It does **not yet have real online multiplayer**, persistent saves, combat, crafting, quests, or installable Android/iOS packages.

## Multiplayer architecture (next milestone)

The game must use server-authoritative rooms with a hard capacity of four connected players. A practical next step is a small WebSocket game server (for example, Node.js with Colyseus) deployed to a reachable host, with:
- room creation/join codes;
- maximum room capacity set to 4 on the server, not just the UI;
- server-validated movement and interactions;
- reconnect/disconnect handling;
- no public matchmaking by default.

GitHub Pages only hosts static files; it cannot run the real-time game server. A hosted multiplayer service/server must be deployed before online play works.

## Project location

This prototype currently lives in the `blockside/` folder of the connected `lifestories-game` repository because the GitHub connection available here can edit existing repositories but does not expose repository creation. It is kept separate from the Living World project files, but it is not yet a separate GitHub repository.
