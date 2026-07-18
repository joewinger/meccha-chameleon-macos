# Meccha Chameleon on macOS

A verified recipe for running the Windows Steam release of **Meccha
Chameleon** on an Apple Silicon Mac with
[Sikarugir](https://github.com/Sikarugir-App/Sikarugir) and Apple D3DMetal.

This is not a Wine distribution or a CrossOver replacement. Sikarugir, Wine,
Rosetta 2, and D3DMetal do the runtime work; this repository records the exact
working configuration and creates a normal macOS app launcher.

## Verified configuration

Last verified 2026-07-13 on an M3 Pro Mac running macOS 26:

- Sikarugir Creator 1.0.1
- Sikarugir Template 1.0.11
- `WS12WineSikarugir10.0_6` (`wine sikarugir 10.0`, revision 6)
- Apple D3DMetal 3.0
- Steam build 1782866176
- Meccha Chameleon, Steam app 4704690

The running game was inspected and confirmed to load D3DMetal's `d3d12.dll`,
`dxgi.dll`, Metal shader caches, and Apple's Metal IR converter.

## Why this configuration works

The game's "A D3D11-compatible GPU ... is required" dialog is misleading in
this environment. Meccha Chameleon actually starts its Unreal renderer through
Direct3D 12 and Shader Model 6.

- DXMT and DXVK target Direct3D 10/11, so neither fixed this failure.
- D3DMetal provides the required 64-bit Direct3D 12 to Metal path.
- Steam's normal launch target is a 222 KB Unreal bootstrapper. Under Wine it
  can incorrectly report that Visual C++ is missing even after Steam installs
  both VC++ 2022 redistributables successfully.
- The native launcher starts Steam, waits until the current session is logged
  on, then runs the real shipping executable with Steam app ID 4704690. This
  bypasses the faulty prerequisite check while preserving Steam authentication,
  Steamworks, and D3DMetal.

## Install

### 1. Install Sikarugir

Follow the current instructions in the
[official repository](https://github.com/Sikarugir-App/Sikarugir). Apple
Silicon Macs also require Rosetta 2.

### 2. Create the wrapper

In Sikarugir Creator:

1. Install engine `WS12WineSikarugir10.0_6`.
2. Update to Template 1.0.11.
3. Create a wrapper named `Meccha Chameleon Test`.
4. Enable **D3DMetal**.
5. Leave **DXVK** and **DXMT** disabled.

The scripts default to:

```text
~/Applications/Sikarugir/Meccha Chameleon Test.app
```

Set `SIKARUGIR_WRAPPER` when running a script if you chose another name.

### 3. Install Steam and the game

Use Sikarugir's Install Software flow with Valve's official `SteamSetup.exe`.
Open the wrapper, sign in normally, and install Meccha Chameleon. This project
does not copy or store Steam credentials.

### 4. Install the native launcher

Run:

```sh
./install-launcher.sh
```

The installer creates:

```text
~/Applications/Meccha Chameleon.app
```

It also restores the main Sikarugir wrapper's target to plain `steam.exe` with
no game flags. That wrapper remains useful for signing in, updates, and other
Windows Steam games.

Double-click that app or place it in the Dock. Bun, Node, TypeScript, and a
Terminal window are not required to play. On a cold launch, it opens Windows
Steam first and waits for Steam to finish logging in before starting Meccha.
If Steam was left running after its server session was replaced, the launcher
restarts that dead wrapper session automatically instead of timing out.

## Diagnose the installation

```sh
./doctor.sh
```

The doctor is read-only. It checks the wrapper, engine, renderer selection,
Apple's D3DMetal signature, Steam, the game, and the native launcher.

## Known Sikarugir issue

Before creating or refreshing a wrapper, quit other Wine, CrossOver, and Steam
sessions. Template 1.0.11 checks for any process named `wineserver`, not only
the server belonging to the wrapper being created, and can otherwise appear to
hang indefinitely.

## Security and licensing

- Nothing in this repository downloads or redistributes Sikarugir, Wine,
  D3DMetal, Steam, or game files.
- The generated launcher is ad-hoc signed locally. It has no Apple Developer ID
  signature and makes no claim of one.
- Sikarugir currently creates wrappers with mode `0777`. On a Mac shared with
  other local accounts, those accounts could modify the wrapper. The doctor
  reports this without silently changing permissions that Creator may expect.
- D3DMetal is closed source and has restrictive terms, including restrictions
  on commercial ports. Review the license linked by the
  [Sikarugir project](https://github.com/Sikarugir-App/Sikarugir#directx-support).
- The MIT license in this repository applies only to this documentation and
  these scripts.
