# Blockside: Medieval Realms

A mobile-first, top-down medieval co-op adventure prototype for Android and iOS browsers.

## Play the browser prototype

Open [index.html](./index.html) directly, or enable GitHub Pages for the repository and open the `/blockside/` path on the published site.

## Multiplayer phase

The browser client now includes **Create Room** and **Join Friend** flows. The Node.js WebSocket server under `server/` provides:
- Five-character room codes.
- A hard four-player room capacity (host plus three friends).
- Server-ticked movement and shared player-position snapshots.
- Basic shared wood/berry inventory counters.
- A health endpoint at `/` and `/health`.

### Run the server

Use Node.js 20 or newer:

```sh
cd blockside/server
npm install
npm test
npm start
```

The server listens on port `2567` by default. Set `PORT` if your host assigns a different port. For a published HTTPS game, host the server somewhere that supports persistent WebSocket connections and TLS, then enter its `wss://` address in the game's online panel. **A server URL is not deployed or configured yet**, so online rooms will not work for friends until hosting is completed.

## Current status and limitations

- The local browser game remains playable without a server.
- Online client/server room protocol has been added, but it still needs automated checks and a real hosted-server test before it should be considered production-ready.
- Resource gathering is currently a prototype counter; it is not yet validated against server-side world resource locations.
- No persistent saves, combat, crafting, quests, accounts, moderation, or native Android/iOS packages yet.
- The project is currently in the `blockside/` folder inside `gmaker505-a11y/lifestories-game`; it is not a separate repository yet.

## Next milestones

1. Verify server protocol with automated tests and CI.
2. Deploy the WebSocket server and test four real devices/clients in one room.
3. Make gathering and world interactions server-validated; add reconnection handling.
4. Add crafting, quests, persistent saves, and better mobile feedback.
5. Package for Android and iOS after browser multiplayer is stable.


## Deploying the online server

A Render deployment blueprint is included at the repository root (`render.yaml`) with a Dockerfile in `blockside/server/`. To deploy it, open the repository's Render blueprint/import flow, connect this GitHub repository, and apply the blueprint. Hosting providers may require account setup and may sleep on free plans.

After the service is deployed:
1. Open the server's HTTPS base URL and check that it returns JSON with `"status":"ok"`.
2. In the game, open **Create / Join Online Room** and replace the example address with the secure WebSocket URL for that same service (`wss://...`).
3. Test room creation and joining from multiple devices. Do not share private credentials in the repository.

I cannot deploy the public service without authorization to a hosting account. The blueprint prepares the repository for deployment; it does not mean a live server already exists.
