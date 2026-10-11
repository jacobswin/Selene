# Selene

[English](README.md) | [简体中文](README_CN.md)

<p align="center"><img src="docs/branding/selene-tvos-icon-master.png" width="480" alt="Selene app icon"></p>

An open-source game streaming client for **Apple TV**, built on the Moonlight ecosystem. Stream your PC games and desktop through Sunshine, with a tvOS interface designed for the Siri Remote and native controller navigation.

**In development.** There is no public binary or TestFlight release yet. Build and sign the app using Xcode. See the [verification record](docs/SELENE_VERIFICATION.md) for actual test results.

![Selene settings](docs/verification/selene-settings.png)

## Features

- Optional compact app covers, configurable menu shortcuts, local controller input testing and independent stick deadzones.
- In-app remote guide and diagnostics; PC locking is opt-in and disabled by default.
- Native tvOS focus, a single host-to-app entry, and focus restoration after settings or streaming.
- Modern two-column settings; focusing a category immediately shows its contents.
- Resolution choices include 360p, 480p, 720p, 1080p, 2K (2560×1440), 3K (3200×1800), 4K, and custom even dimensions within device limits.
- English, Simplified Chinese, and Traditional Chinese, with an in-app language selector. Other system languages fall back to English.
- Configurable bitrate up to **800 Mbps**, including custom values above 150 Mbps. This is a configuration limit, **not guaranteed network throughput**.
- Remote-operated bitrate keypad; −/+ use 10 Mbps steps at or below 200 Mbps and 25 Mbps above 200 Mbps.
- H.264 and HEVC; HDR10 through HEVC Main10 when the host, decoder, and display support it.
- AV1 is always listed, but selectable only when hardware decoding is available. No software AV1 decoding.
- Stereo, 5.1, and 7.1 audio, subject to host and output-device capability.
- Dark in-stream menu with live bitrate, statistics, keyboard shortcuts and explicit text entry.
- Shared device/requested/negotiated capability report, plus persistent picture fitting, alignment and offsets.
- Optional adaptive bitrate with explicit bounds, network frame-loss/RTT feedback, manual override and host-rejection handling. It starts disabled and keeps saved manual bitrate unchanged.

The current stream path does **not support Dolby Vision or Dolby Atmos**. HDR10 is not Dolby Vision; Opus decoded to multichannel PCM is not Atmos. 2.1, 5.1.2, and 7.1.4 are not implemented as selectable output layouts. High-bitrate 4K60, sustained HDR playback, and physical audio output still require device validation.

## TODO

This checklist tracks feature implementation and bug fixes. Cleanup and feature removals are recorded in the verification notes. 🟢 Implemented · 🔴 Pending. Green items are implemented; physical streaming validation is tracked separately. Android reference features are reviewed for tvOS and the existing Sunshine protocol before being added here.

- 🟢 Back/Menu opens a stream dialog instead of immediately leaving; offer Continue, Stream settings, Disconnect, and Disconnect and close app (with confirmation).
- 🔴 Validate the new dialog on Apple TV: repeated Back, settings round trips, controller/keyboard input, both exit actions, and restored app focus.
- 🟢 Bring live bitrate and performance statistics directly into the stream menu, with host rejection feedback and safe focus navigation.
- 🟢 Add menu shortcuts for Alt+Tab, Windows, special keys, and explicit tvOS text input; release all pressed keys when dismissed or disconnected.
- 🔴 Investigate in-session resolution and HDR changes with Foundation Sunshine; expose only negotiated support, otherwise clearly require reconnecting.
- 🔴 Investigate host keyboard and Windows DPI controls; add only if the existing host protocol provides a reliable supported operation.
- 🟢 Add a video capability report with actual display mode, decoder support, HDR status, and negotiated stream format.
- 🟢 Add client-side adaptive bitrate with explicit bounds, network-frame-loss/latency feedback, manual override, and host capability checks.
- 🟢 Add display fitting, alignment and horizontal/vertical offset controls, with reset and no change to requested stream dimensions.
- 🟢 Add optional compact app covers and configurable menu shortcut visibility, retaining clear native focus.
- 🟢 Add optional low-bandwidth resolution choices and explain requested FPS versus actual display refresh rate.
- 🟢 Explain frame pacing, client buffering and full color range, guard unsupported/live pacing changes, and confirm color-range edits; physical default validation remains pending.
- 🟢 Add controller shortcut testing, independent stick dead zones and mouse-mode controls where GameController permits.
- 🟢 Add an optional lock-PC action after disconnecting, using balanced Win+L events and clear host failure feedback.
- 🟢 Disconnect on background while leaving the PC app running; optionally offer reconnect on return (off by default).
- 🟢 Export versioned settings as a QR backup code and restore validated codes with confirmation; pairing, PC addresses and accounts are excluded.
- 🟢 Add an in-app remote-operation guide, diagnostics and project/license links; do not show unavailable downloads or paid unlocks.
- 🔴 Investigate host render scaling, monitor selection and input-only sessions against existing Foundation Sunshine negotiation.
- 🔴 Investigate microphone forwarding using supported tvOS capture routes and the existing host extension; keep unavailable until verified.
- 🔴 Validate the existing native interpolation path for supported Apple hardware; do not load Windows Lossless Scaling DLLs or claim Android parity.
- 🔴 Evaluate additional Moonlight V+ Android screenshots and add feasible features individually; update each status after implementation and relevant verification.
- 🔴 Complete physical 160/200 Mbps 4K60, sustained HDR10, and stereo/5.1/7.1 output validation.

### Current five additions

1. 🟢 **Stick center calibration:** samples two seconds of untouched input, rejects unstable/large drift and remaps each axis while preserving full travel. Calibration is scoped to a controller instance, resettable and cleared on disconnect; it is not exported.
2. 🟢 **Controller mouse tuning:** independent 25–300% pointer and scroll speed with optional inverted scrolling; 100% preserves the original speed and gamepad mode is unchanged.
3. 🟢 **Statistics placement:** top center or any corner, bounded by the TV safe area and independent of video layout.
4. 🟢 **Network quality reminders:** enabled by default, optionally hidden without suppressing connection, decode or other failure alerts.
5. 🟢 **Diagnostic QR:** a locally generated, allowlisted numeric stream snapshot and known format labels; no host names/addresses, pairing material or automatic upload.

Find calibration, mouse tuning, placement and reminders under Settings → Others → TV experience. Diagnostic QR is under Help and diagnostics. New persistent preferences are included in backups; older backup codes remain readable.

🔴 Physical controller/calibration feel, corner placement, quality reminders and phone QR scanning remain pending.

### Second batch five additions

1. 🟢 **Reconnect notice:** saved resolution, FPS, codec, HDR or range changes are compared with the connection's original request; the menu/report explains when reconnecting is needed.
2. 🟢 **Performance guidance:** explains pacing/output-path limits, the client frame queue and full range; unsupported pacing changes are guarded and range changes require confirmation.
3. 🟢 **Background return:** disconnects without quitting or locking the PC app; the optional reconnect prompt is off by default.
4. 🟢 **Settings backup:** scan a locally generated QR code, copy its `SELENE1:` code and paste it with the iPhone Apple TV Remote keyboard into Settings → Others → Settings backup. Preview and confirm before restoring. Only allowlisted settings are included; unavailable codec/HDR/interpolation choices are adjusted.
5. 🟢 **Host extension report:** Help and diagnostics separates observed live-bitrate request results from unknown or unimplemented host operations. It does not enable unverified resolution, HDR, DPI or microphone controls.

🔴 Physical acceptance of these five additions remains pending. Previous pending device checks also remain open.

### Previous five implementation stages

1. 🟢 **Stream menu reliability:** shared duplicate-Back protection and restored menu focus. The user confirmed streaming was retained; repeated Back/settings/controller acceptance remains pending.
2. 🟢 **Compact covers and menu customization:** optional compact app cards and six independent shortcut visibility preferences.
3. 🟢 **Lock PC after disconnect:** disabled-by-default Win+L before explicit ordinary disconnect; reports transport delivery, not confirmed host lock.
4. 🟢 **Controller controls:** local input test, independent 0–30% radial stick deadzones and session-only mouse mode.
5. 🟢 **In-app guide and diagnostics:** three-language remote/pairing/troubleshooting help, live capability report and QR links to the project, feedback and GPLv3 license.

🔴 Physical acceptance of the new grid, shortcut visibility, Windows lock, controller mouse and three-language help remains pending; see the verification record.

See the [Android menu feasibility review](docs/ANDROID_MENU_ROADMAP.md). Touch-only controls are not copied to tvOS; Dolby Vision, Atmos, and height-channel layouts remain unsupported.

## Build and install

Requirements: macOS, **Xcode 26 or later**, and **tvOS 16 or later**. Current development uses Xcode 27.

```sh
git clone --recurse-submodules https://github.com/jacobswin/Selene.git
cd Selene
open Selene.xcodeproj
```

1. Select the **Selene** scheme and the main Selene tvOS target.
2. In **Signing & Capabilities**, enable automatic signing and select your own development team. Choose your own unique bundle identifier if required.
3. Pair the Apple TV in Xcode's **Devices and Simulators**, select it as the run destination, and run. A 4K simulator supports UI checks, but cannot establish physical decoder or HDR capability.

Unsigned compile check:

```sh
bash BuildScripts/build-tvos.sh Debug
```

See [building and pairing](docs/BUILDING.md). When upgrading an existing development installation, keep its bundle identifier to retain pairing and settings.

## Connect and play

Run Sunshine on the PC. Development currently uses [Foundation Sunshine](https://github.com/AlkaidLab/foundation-sunshine); compatibility with every Sunshine version has not been established.

Select a discovered computer or use **+** to enter its address. Select the computer to pair, then enter the PIN shown by Selene in Sunshine's pairing page. Selecting a paired computer opens its applications; **Desktop** remains an ordinary app in that list.

Use the Siri Remote to navigate and select. During streaming, Back/Menu opens the stream dialog; disconnecting keeps the PC app running, while Disconnect and close app also requests that the host close it. A connected controller uses native tvOS focus in the interface and supplies game input during streaming. Open settings through the gear button.

## Origins and acknowledgements

The direct Apple-client code base is [VoidLink](https://github.com/The-Fried-Fish/VoidLink-previously-moonlight-zwm), itself derived from [Moonlight iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios). Original copyright notices and the [upstream README](docs/UPSTREAM_README.md) are retained.

Other references include [Moonlight Android](https://github.com/moonlight-stream/moonlight-android), [Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt), [Moonlight Embedded](https://github.com/moonlight-stream/moonlight-embedded), historical [Moonlight Chrome](https://github.com/moonlight-stream/moonlight-chrome), [Moonlight Common C](https://github.com/moonlight-stream/moonlight-common-c), and [Moonlight V+](https://github.com/qiin2333/moonlight-vplus). The pinned protocol submodule uses the upstream [VoidLink C fork](https://github.com/TrueZhuangJia/voidlink-c).

Selene is an independent community project. References do not imply official affiliation or endorsement.

## License and contributions

Distributed under [GPLv3](LICENSE.txt). Dependencies retain their own licenses. Contributions and reproducible bug reports are welcome; include device model, tvOS and host versions, stream settings, and reproduction steps. Remove private addresses and pairing codes from shared evidence.
