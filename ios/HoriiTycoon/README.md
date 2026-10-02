# H0RII Tycoon

A playable SwiftUI + SceneKit 3D tycoon vertical slice for iOS.

## Current game loop

- Run H0RII Labs from a 3D HQ or Downtown map.
- Track cash, likes, followers and daily revenue.
- Publish creator posts, ship projects, hire creators and advance the day.
- Edit the digital creator profile name.
- Local save data uses `UserDefaults`.
- The 3D scene uses procedural geometry, so the prototype runs without a network or asset download.

## Asset direction

The first slice deliberately uses original procedural geometry. For authored 3D content, use sources with clear licenses:

- Kenney City Kit Commercial / Industrial / Roads: CC0 — https://kenney.nl/assets
- Quaternius Universal Base Characters: CC0/QAL — https://quaternius.com/packs/universalbasecharacters.html
- Poly Haven models and materials: CC0 — https://polyhaven.com/license

Do not bundle an asset until its specific license is checked and recorded. Later passes can import `.usdz`/`.scn` character, office, city and vehicle assets into `Assets.xcassets` or a RealityKit/SceneKit asset folder.

## Run

Open `HoriiTycoon.xcodeproj` in Xcode 15+ on macOS, choose an iPhone simulator or device, select your Apple Development Team, and Run. This Linux host can verify source/project structure but cannot compile or sign an iOS app.
