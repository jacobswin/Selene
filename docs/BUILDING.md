# Building Selene

Use macOS with full Xcode 26 or later. Current verification uses Xcode 27; deployment target is tvOS 16.

## Source and dependencies

Clone with `--recurse-submodules`, or run `git submodule update --init --recursive` after cloning. Keep the pinned commits, including the protocol fork. Swift packages use the committed `Package.resolved`.

## Xcode and signing

Open `Selene.xcodeproj` and select the **Selene** scheme and tvOS target. Inherited iOS and preview targets remain in the source but are outside this release's validation.

Choose your own team in Signing & Capabilities. No signing certificate or personal team is included. The existing development bundle identifier is retained for upgrade compatibility; new contributors may choose their own identifier. Changing it installs a separate app without automatic data migration.

Run `bash BuildScripts/build-tvos.sh Debug` (or `Release`) for an unsigned device compile. This does not install the app.

## Physical Apple TV

Keep Mac and Apple TV on the same local network. On Apple TV, open **Settings → Remotes and Devices → Remote App and Devices**. Open **Window → Devices and Simulators** in Xcode, select Apple TV and follow pairing prompts. Keep devices nearby when proximity is requested. Select the paired device as the run destination and run Selene.

Developer Mode prompts vary with the device and toolchain. Follow actual Xcode and Apple TV prompts instead of assuming a missing switch proves pairing failed.

Run Sunshine on the PC, pair using Selene's PIN, and select an application. Development uses Foundation Sunshine, with no host protocol changes. Validate resolution, HDR, network, and audio equipment on the physical stream.

## Simulator and checks

Use a 4K Apple TV simulator with 3840×2160 screenshots for UI checks. Simulator codec detection does not establish physical decoder or HDR support.

```sh
python3 Tests/test_tv_bitrate.py
python3 Tests/test_tv_localization.py
python3 Tests/test_tv_resolution.py
```

See [verification status](SELENE_VERIFICATION.md) for results and remaining physical-device checks.
