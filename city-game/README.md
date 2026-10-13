# Blockside — Online City

A mobile-first 2D top-down city sandbox prototype, built as a static web game.

## Play locally
Open `city-game/index.html` in a modern browser with internet access. The canvas city and movement controls work without joining a room. Online rooms use PeerJS's public cloud signaling service; the service and network path must be reachable for multiplayer to connect.

## Controls
- Mobile: drag the on-screen joystick.
- Desktop: WASD or arrow keys.
- Create room: generates a room/peer code; share it with a friend.
- Join: enter the other player's room code.
- Chat and wave: available after connecting.

## Current prototype scope
- Scrollable procedural-looking city grid, buildings, trees, player markers and minimap.
- Touch joystick, keyboard input, chat, wave and respawn.
- Peer-to-peer player position and chat sync through PeerJS.
- GitHub Actions checks and a Pages deployment workflow.

## Important limitations
This is an early networking prototype, not a finished MMO. Peer-to-peer state is not authoritative, so cheating and desynchronisation are possible. PeerJS public cloud signaling and browser WebRTC connectivity are external dependencies. A reliable public game needs a dedicated authoritative server, moderation, identity, persistence, rate limits and abuse controls. GitHub Pages hosts only the static client; it does not host the multiplayer server.

## Deploy
The workflow `.github/workflows/city-game-pages.yml` deploys the `city-game/` directory from branch `city-online-mvp` using GitHub Pages Actions. In repository Settings → Pages, select **GitHub Actions** as the source if it is not already configured. See [GitHub's deployment guide](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).

## Roadmap
1. Validate the playable prototype and peer connection on two devices.
2. Add vehicles, enterable buildings, jobs, money and persistent character customisation.
3. Replace peer-hosted state with an authoritative multiplayer server.
4. Add account-safe player identity, moderation, server persistence and Android packaging (PWA/TWA or WebView wrapper).
