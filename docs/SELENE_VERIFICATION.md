# Selene verification

Updated: 2026-10-06. Implementation, simulator checks, user feedback and physical streaming measurements are distinguished below.

| Check | Result and evidence |
| --- | --- |
| Project, scheme, target and app rename | Passed: Xcode 27 Debug simulator and signed-device builds, plus unsigned-device Release build; current app is Selene |
| Existing pairing/settings compatibility | Bundle ID and store keys retained; active Core Data model byte-identical to baseline; saved simulator bitrate and language retained after relaunch |
| Startup keyboard prewarm | Disabled on tvOS; 5 simulator launches completed. Transient launch captures alone do not prove absence of every keyboard flash |
| Touch control menu | tvOS creation and old-configuration restoration disabled; physical streaming observation pending |
| Host list persistence and focus restoration | 10 simulator settings round trips retained the discovered host and restored gear focus. User reported the installed host/app flow was working well; independent physical stream-return capture pending |
| Host-to-app entry and app-card focus | Single paired-host entry and whole-card animation implemented. User feedback was positive; app-grid/controller edge cases still need physical checks |
| Resolution policy | Passed: 720p/1080p/2560×1440/3200×1800/4K, custom even dimensions, device limits and invalid-input checks. Fullscreen removed from tvOS choices |
| Bitrate policy | Passed: 150/160/200/300/800 Mbps, exact values, bounds and non-finite values; no 150 Mbps cap in tested policy |
| Bitrate editor focus and input | Passed in 3840×2160 simulator: visible −/+, down-navigation to exact entry and Done, replacing values, Cancel, invalid 0 feedback and Apply |
| Bitrate step sizes | Passed: 200→190, 190→200→210→235 and 235→210→185; 10 Mbps when current value ≤200 Mbps, 25 Mbps above it |
| Localization | Passed: stored preference, system selection, invalid preferences, 16 region/fallback cases and English/Simplified/Traditional Chinese coverage |
| Current icon | Accepted minimalist illustration subtly polished; inspected at 400×240, compiled and installed. Earlier rabbit/textured/vector drafts are superseded |
| Physical install | Passed: signed Debug build and update installation on Apple TV 4K, tvOS 26.6 |
| 160/200 Mbps 4K60 throughput, loss and latency | Not validated |
| 30-minute HDR10 and SDR retry | Not validated on a physical stream |
| Hardware-positive AV1 device | Not validated; no software decoding is enabled |
| Host rejection, decoder failure, display failure and network interruption | Handling implemented where recorded in source; end-to-end acceptance pending |
| Game-controller input and physical surround output | Not validated |
| Dolby Vision / Atmos / height-channel layouts | Not supported by the current stream path |

## Devices and evidence

The actual connected device is a **second-generation Apple TV 4K (AppleTV11,1)** running tvOS 26.6, not the third-generation device initially requested. The simulator is Apple TV 4K at 3840×2160 on tvOS 27. Simulator display size does not establish a 4K stream or physical decoder capability.

The English settings screenshot below has a saved 1080p stream setting. Simulator hardware detection can disable 4K/HDR choices; this is not evidence of the physical device's capabilities. Saved 220 Mbps survived the rename and relaunch checks.

![Settings in the 4K simulator](verification/selene-settings.png)

![Exact bitrate keypad in the 4K simulator](verification/selene-bitrate-input.png)

Private host addresses, pairing screenshots, signing details and local device logs are excluded from publication. An earlier physical screenshot showed the system screensaver; installation and process launch are not treated as proof of streaming behavior.

## Acceptance still required

Measure real 4K60 streams at 160 and 200 Mbps, with receive bitrate, loss, latency and decode time; run HDR10 for 30 minutes and exercise SDR retry. Test host refusal, decoder initialization failure, unsupported display output and network interruption. Verify offline/WOL behavior, deleting the focused host/app, custom-resolution remote input, stream-return focus, controller input and actual stereo/5.1/7.1 output.

800 Mbps is a configuration ceiling, not a stable-throughput promise. HDR10 is not Dolby Vision, and Opus-to-PCM surround audio is not Dolby Atmos.

## GitHub publication and clean checkout

Public repository: [jacobswin/Selene](https://github.com/jacobswin/Selene), default branch `main`. Original Git history and recursive submodule pins are retained.

A fresh recursive clone from GitHub succeeded. In that clone, all three production-policy suites passed, README images and local document links resolved, and the documented `bash BuildScripts/build-tvos.sh Debug` command built successfully under Xcode 27 without sharing the original checkout's build or package caches.

GitHub-hosted unsigned Debug and Release builds passed under Xcode 26 after tvOS platform support was provisioned: [successful CI run](https://github.com/jacobswin/Selene/actions/runs/37487413024). The earlier missing-platform failure was an environment setup issue and is retained in Actions history.

The publishable tree was checked for local device identifiers, pairing evidence, signing files and credential patterns; no such material was found. This build verification does not change the physical-stream acceptance limits above.

## 2026-10-07: audio cleanup and stream menu

- Implemented one tvOS Stereo choice, 5.1 and 7.1; removed unsupported placeholder layouts. Legacy system/SDL stereo values resolve to Stereo, existing surround values remain valid.
- Added the Back/Menu stream dialog with Continue, Stream settings, Disconnect, and confirmed Disconnect and close app. Existing quit request/error handling is reused. Settings presentation uses the visible stream controller and tracks streaming state.
- Unsigned tvOS Debug, simulator Debug and signed device Debug builds passed. Production audio preference compatibility, bitrate, resolution and localization checks passed.
- On the 3840×2160 simulator, remote navigation opened Audio Configuration and showed exactly Stereo / 5.1-channel / 7.1-channel plus Cancel. Existing 5.1 preference remained selected. This is UI evidence, not physical surround-output validation.
- Actual live-stream menu dismissal, settings return, both exit actions, host rejection, keyboard/controller interaction and application focus restoration remain unverified on the Apple TV. Track them separately from implemented code.
- Reviewed the user-provided Android stream-menu photo and all 14 settings photos. Matching English/Chinese README checklists and the Android feasibility review record client tasks, host/platform investigations and excluded touch/Android-only features. Personal reference photos are not published.
