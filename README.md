# Car Driving 2.5D

Car Driving 2.5D is an original 2.5D off-road vehicle game built with Godot 4.7.2 and GDScript. The game uses a side-view camera, procedural 3D terrain, custom raycast-based vehicle physics, and procedural geometry instead of external art assets.

## Features

- Custom `RigidBody3D` vehicle controller with:
  - Raycast wheel suspension.
  - Spring and damping forces.
  - Wheel traction and braking.
  - Airborne pitch control.
  - Flip and backflip tracking.
  - Nitro acceleration.
  - Fuel depletion lockout.
- Procedurally generated and streamed terrain.
- Progressive difficulty stages, including highland hills and rope bridges.
- Procedural trees, rocks, bushes, mountains, lighting, fog, and sky.
- Detailed procedural buggy with:
  - Driver, helmet, seat, harness, and steering wheel.
  - Roll cage, bumpers, engine details, exhaust, lights, alloys, tyres, tread, and suspension.
- Collectable coins with:
  - Rotation and bobbing animation.
  - Deterministic chunk-based spawning.
  - One-time Area3D collection.
  - Stunt rewards for flips and airtime.
- Collectable fuel cans with:
  - Deterministic terrain spawning.
  - Enlarged collection trigger.
  - Fuel restoration capped at 100%.
- Gameplay HUD with:
  - Distance, score, coins, fuel, and nitro.
  - Animated fuel bar and low-fuel warnings.
  - RPM and boost gauges.
  - Pressed-state brake and accelerator controls.
- Game-over overlay with final distance, coins, best distance, restart, and scene reload actions.
- Keyboard and responsive touch controls.
- Godot Compatibility renderer for Windows and Android-oriented performance.

## Requirements

- Godot `4.7.2.stable` or a compatible Godot 4.7 release.
- Windows PC for the desktop workflow.
- No external packages, plugins, Blender files, or downloaded assets are required.

The project is configured for:

- Main scene: `res://scenes/main.tscn`
- Renderer: Godot Compatibility
- Default viewport: `1280x720`
- Physics interpolation: enabled

## Running the game in Godot Editor

1. Install Godot 4.7.2.
2. Open Godot.
3. Select **Import**.
4. Choose this repository folder.
5. Open the project.
6. Press **F6** to run the current scene or **F5** to run the project.

The project starts from [scenes/main.tscn](scenes/main.tscn).

## Running from Windows PowerShell

From the repository directory, run:

```powershell
& "C:\Path\To\Godot_v4.7.2-stable_win64.exe" --path "." 
```

For a headless startup validation:

```powershell
& "C:\Path\To\Godot_v4.7.2-stable_win64.exe" --headless --path "." --quit-after 900
```

The repository path can also be supplied explicitly:

```powershell
& "C:\Path\To\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\pranay\OneDrive\Desktop\Hill Climb"
```

## Controls

### Keyboard

| Action | Keys |
|---|---|
| Accelerate | `W` or `Up Arrow` |
| Reverse | `S` or `Down Arrow` |
| Brake | `Space` |
| Rotate vehicle backward/forward in air | `A` / `D` |
| Nitro | `Shift` |
| Reset or restart | `R` |

### Touch

The HUD listens for screen touches and supports continuous press-and-hold:

- Hold the right accelerator pedal to drive.
- Hold the left brake pedal to brake.
- Release a pedal to immediately clear its input.
- Accelerator and brake can be pressed simultaneously.

Keyboard input remains available when running the desktop build.

## Gameplay systems

### Vehicle physics

The vehicle is not based on Godot's built-in `VehicleBody3D`. The custom controller in [scripts/vehicle_controller.gd](scripts/vehicle_controller.gd) performs wheel raycasts, suspension force calculation, tire traction, braking, airborne rotation, and nitro force application.

The visual wheels are separate from the physics calculations and follow the interpolated wheel state. This keeps the vehicle visuals detailed without changing the existing physics contract.

### Terrain streaming

[scripts/procedural_terrain.gd](scripts/procedural_terrain.gd) generates terrain in deterministic chunks. Active chunks create their own collision, decorations, obstacles, coins, and fuel cans. Chunks ahead of the vehicle are created and old chunks are removed to limit memory and rendering cost.

Terrain collision is generated from the same surface data used by the visible terrain mesh.

### Coins and fuel

- [scenes/coin.tscn](scenes/coin.tscn) and [scripts/coin.gd](scripts/coin.gd) implement rotating, bobbing coin pickups.
- [scenes/fuel_can.tscn](scenes/fuel_can.tscn) and [scripts/fuel_can.gd](scripts/fuel_can.gd) implement fuel pickups.
- Collection uses `Area3D` signals and is protected against duplicate collection.
- Pickups belong to their terrain chunk and are removed with that chunk.

### HUD and game state

[scripts/game_hud.gd](scripts/game_hud.gd) draws the procedural dashboard and emits touch-control signals. [scripts/main.gd](scripts/main.gd) owns run state, fuel consumption, coin totals, elimination, restart, game-over presentation, and HUD values.

Fuel consumption is calculated in the main controller and is not changed by the HUD. Nitro consumption and recharge remain in the vehicle controller.

## Project structure

```text
.
├── project.godot
├── scenes
│   ├── main.tscn
│   ├── coin.tscn
│   ├── fuel_can.tscn
│   └── vehicle
│       └── placeholder_vehicle.tscn
├── scripts
│   ├── main.gd
│   ├── game_hud.gd
│   ├── vehicle_controller.gd
│   ├── vehicle_visuals.gd
│   ├── procedural_terrain.gd
│   ├── environment_visuals.gd
│   ├── difficulty_manager.gd
│   ├── obstacle_generator.gd
│   ├── coin.gd
│   └── fuel_can.gd
└── archive
    └── legacy-javascript
```

The archived JavaScript project is retained as a design and recovery reference. It is not loaded by the Godot game.

## Exporting

### Windows

1. Open the project in Godot.
2. Select **Project > Export**.
3. Add a Windows Desktop preset.
4. Choose an output `.exe` path.
5. Export the project.

### Android

1. Install the Android SDK, OpenJDK, and Godot Android export templates.
2. Configure the SDK and Java paths in Godot Editor Settings.
3. Select **Project > Export**.
4. Add an Android preset.
5. Configure the package identifier and signing settings.
6. Export an APK for testing or an AAB for store distribution.

Android performance should be tested on physical target devices. The game uses the Compatibility renderer and procedural geometry, but scene complexity, shadows, terrain streaming, and draw calls still need device-specific profiling.

## Validation

A useful local validation command is:

```powershell
& "C:\Path\To\Godot_v4.7.2-stable_win64.exe" --headless --path "." --quit-after 900
```

Successful startup should exit with code `0` and should not report script parse errors or runtime errors.

Manual gameplay checks should cover:

- Acceleration, reverse, braking, and reset.
- Touch pedal press, hold, simultaneous press, and release.
- Nitro drain and recharge.
- RPM and boost gauge movement.
- Coin and fuel collection.
- Fuel warnings at 25% and 10%.
- Jumps, flips, backflips, and landings.
- Crash and fuel game-over flows.
- Restart and main-scene reload actions.
- Terrain chunk creation and cleanup.

## Current limitations

- The main-menu action currently reloads the main scene; a separate menu scene has not been added.
- Android export configuration and signed release packaging must be completed on the target development machine.
- Touch controls are implemented in code but should be verified on physical Android hardware.
- Procedural geometry is intentionally used in place of final art assets.
- Persistent account progression and cloud saves are not currently part of the prototype.

## License and assets

This repository uses original project code and procedural geometry. No external art, audio, plugin, or runtime dependency is required by the current prototype. Any future third-party assets should be reviewed for commercial redistribution and platform licensing before inclusion.
