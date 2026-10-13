# WILDBOUND — Find Your Own Way

An original, mobile-first 2D open-world survival prototype. This project is separate from Blockside and Living World.

## Play locally
Open `index.html` in a browser, or serve the repository root and visit `/wildbound/`. GitHub Pages path after deployment: `https://gmaker505-a11y.github.io/lifestories-game/wildbound/`.

## Current playable systems
- Procedurally placed woodland resources, pond, paths, day/night tint and a scrolling world.
- Keyboard movement (WASD / arrows) and touchscreen joystick.
- Gather wood, berries, stone and fibre.
- Hunger and health survival loops; eat berries to recover hunger.
- Craft a stone hatchet, campfire and lean-to shelter.
- Local autosave state for inventory, world clock, gathered resources and crafted structures.
- Small-screen HUD and controls designed for phones.

## Co-op status
The separate `server/` folder contains a WebSocket room server with room codes, up to four players, position broadcasts and chat. It has automated tests. The browser prototype is currently single-player and is not yet connected to a hosted server. To enable live co-op, deploy `server/` as a Node web service (start command `npm start`, health endpoint `/health`), then wire the returned WebSocket URL into the browser client. Do not treat local tests as proof that a server is publicly hosted.

## Run server locally
```sh
cd wildbound/server
npm install
npm test
npm start
```

## No purchases
Designed for private play with friends and free/open-source tooling. A public always-on server may have hosting limits or charges depending on the provider; no paid service is required to play the current solo prototype locally.

## Roadmap
1. Browser and mobile layout QA.
2. Connect browser clients to the room server; synchronize movement, chat, gathering and world state.
3. Expand building, tools, crafting, wildlife, weather and survival options.
4. Add private rooms, reconnect handling and persistence.
5. Package Android/iOS builds only after the browser prototype is stable and verified.
