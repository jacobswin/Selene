# Android reference feature assessment

The user-provided streaming-menu and 14 settings photos were reviewed as references. The 14 specified local temporary attachments were deleted earlier; no reference photos are tracked or published. Menu labels are not proof that a host, client or output route supports a format.

## Client implementation

| Reference area | Selene implementation | Boundary |
| --- | --- | --- |
| Stream menu | Dark native TV overlay, Back/resume, bitrate, statistics, shortcuts, settings and separate exit actions | Host acceptance is separate from actual output; menu suspends ordinary remote input |
| Quality | Resolution presets/custom dimensions, FPS, 0.5–800 Mbps and bounded optional adaptive bitrate | Live resolution changes require reconnect; no throughput guarantee |
| Codec/HDR | H.264, HEVC, hardware-gated AV1, HDR10 and device/request/result reports | No software AV1 or unverified Dolby support; no live HDR toggle |
| Host | Optional Win+L, background disconnect/foreground prompt, confirmed Windows display scaling and published commands | Win+L/commands report delivery or acceptance, not host completion |
| Monitor/input-only | Opt-in Foundation monitor-topology requests and control-only RTSP sessions | Foundation prerequisite and actual handshake required; not capture-monitor selection |
| Display/layout | Fit/stretch, nine-point alignment, offsets and reset; mouse-coordinate conversion | No mobile orientation/external-display picker or TV picture-in-picture promise |
| Performance | Pacing and client-buffer explanations, capability guards and network statistics | Decode/render drops are not treated as network loss |
| Frame generation | Existing native Apple interpolation with sustained-overrun degradation and actual generation/time diagnostics | Supported hardware/tvOS 26+ required; no Windows DLL loading; artifacts/latency unverified on device |
| Audio | Stereo, 5.1 and 7.1 | No height layouts, Atmos branding or Android passthrough implementation |
| Microphone | Experimental tvOS 17+ Continuity picker, permission, selected input, negotiated forwarding, muted start and 48 kHz mono/20 ms Opus | Requires iPhone/iPad and compatible host; no Siri Remote capture; output-route/device acceptance pending |
| Controller | Local test, radial deadzones, connection-scoped calibration and mouse tuning | Uses GameController; no Android USB-driver assumptions |
| Touch/keyboard | Explicit TV text input and balanced special-key shortcuts; host-published commands | No automatic host touch keyboard, mobile touch gestures or fabricated keyboard command |
| Crown/interface | Optional compact covers, shortcut visibility, three languages, statistics position and quality reminders | No touch-widget profiles/floating bubble; failures stay visible |
| Backup/help | Versioned local QR/code settings backup, restore validation, guides, privacy-safe diagnostic QR and license/project links | No pairing-secret export, automatic upload, paid unlock or nonexistent distribution channel |

## Protocol findings

Audited Foundation Sunshine revision: `46525886181bae9bab1dc9711093d1997f578b7d`. Selene's existing pinned protocol submodules were not changed.

- [Display scale API](https://github.com/AlkaidLab/foundation-sunshine/blob/46525886181bae9bab1dc9711093d1997f578b7d/src/nvhttp/display_scale.cpp): paired HTTPS GET `/display-scale-options` and POST `/display-scale`. Selene accepts only validated advertised presets, requires confirmation and performs independent read-back. Missing/failed/malformed responses do not enable arbitrary values.
- [Host launch options](https://github.com/AlkaidLab/foundation-sunshine/blob/46525886181bae9bab1dc9711093d1997f578b7d/src/nvhttp.cpp): `customScreenMode` supports following host or topology requests. Selene requires advertised Foundation extension prerequisites. This does not identify a captured physical monitor or confirm resulting topology.
- [Control-only RTSP](https://github.com/AlkaidLab/foundation-sunshine/blob/46525886181bae9bab1dc9711093d1997f578b7d/src/rtsp.cpp): the pinned client core already supports control-only setup, which skips video/audio. Successful control SETUP/session negotiation remains required. Selene shows an explicit no-video/audio message and disables session bitrate automation.
- [Host commands](https://github.com/AlkaidLab/foundation-sunshine/blob/46525886181bae9bab1dc9711093d1997f578b7d/src/nvhttp/apps.cpp): application `SuperCmds` lists IDs/names and `/supercmd` accepts a selected ID. Selene keeps a bounded validated list only in memory and requires confirmation. A keyboard command appears only if the host publishes one; there is no generic keyboard-toggle assumption.
- [Dynamic parameters](https://github.com/AlkaidLab/foundation-sunshine/blob/46525886181bae9bab1dc9711093d1997f578b7d/src/nvhttp/dynamic_params.cpp): HTTP rejects live-resolution requests in favor of a control-stream extension; the current client exposes no outgoing operation for that extension. No equivalent live HDR operation was established. Saved settings apply through explicit reconnect, leaving the app running.
- Host render-scale and capture-monitor-selection controls have no established usable path in this client/host combination. Sending Android-only launch parameters without proof of handling would be misleading; these controls are not exposed.

## Platform and acceptance

[Apple's tvOS Continuity capture guidance](https://developer.apple.com/videos/play/wwdc2023/10256/) establishes iPhone/iPad microphone selection on supported tvOS devices, not continuous Siri Remote microphone access. The client requires explicit permission and selection, renegotiation, and manual unmute; interruption, route loss, transport failure and session end stop capture.

Physical Apple TV acceptance is deferred at the user's request. New host controls, control-only mode, microphone/output-route compatibility, interpolation quality and sustained high-bitrate/HDR/multichannel behavior remain unverified. Simulator streaming is not used as device evidence. See [the verification record](SELENE_VERIFICATION.md).
