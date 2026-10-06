# Selene

[English](README.md) | [简体中文](README_CN.md)

<p align="center"><img src="docs/branding/selene-icon-master.png" width="480" alt="Selene app icon"></p>

An open-source game streaming client for **Apple TV**, built on the Moonlight ecosystem. Stream your PC games and desktop through Sunshine, with a tvOS interface designed for the Siri Remote and native controller navigation.

**In development.** There is no public binary or TestFlight release yet. Build and sign the app using Xcode. See the [verification record](docs/SELENE_VERIFICATION.md) for actual test results.

![Selene settings](docs/verification/selene-settings.png)

## Features

- Native tvOS focus, a single host-to-app entry, and focus restoration after settings or streaming.
- Modern two-column settings; focusing a category immediately shows its contents.
- Resolution choices include 720p, 1080p, 2K (2560×1440), 3K (3200×1800), 4K, and custom even dimensions within device limits.
- English, Simplified Chinese, and Traditional Chinese, with an in-app language selector. Other system languages fall back to English.
- Configurable bitrate up to **800 Mbps**, including custom values above 150 Mbps. This is a configuration limit, **not guaranteed network throughput**.
- Remote-operated bitrate keypad; −/+ use 10 Mbps steps at or below 200 Mbps and 25 Mbps above 200 Mbps.
- H.264 and HEVC; HDR10 through HEVC Main10 when the host, decoder, and display support it.
- AV1 is always listed, but selectable only when hardware decoding is available. No software AV1 decoding.
- Stereo, 5.1, and 7.1 audio, subject to host and output-device capability.

The current stream path does **not support Dolby Vision or Dolby Atmos**. HDR10 is not Dolby Vision; Opus decoded to multichannel PCM is not Atmos. 2.1, 5.1.2, and 7.1.4 are not implemented as selectable output layouts. High-bitrate 4K60, sustained HDR playback, and physical audio output still require device validation.

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

Use the Siri Remote to navigate and select, and Back/Menu to return. A connected controller uses native tvOS focus in the interface and supplies game input during streaming. Open settings through the gear button.

## Origins and acknowledgements

The direct Apple-client code base is [VoidLink](https://github.com/The-Fried-Fish/VoidLink-previously-moonlight-zwm), itself derived from [Moonlight iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios). Original copyright notices and the [upstream README](docs/UPSTREAM_README.md) are retained.

Other references include [Moonlight Android](https://github.com/moonlight-stream/moonlight-android), [Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt), [Moonlight Embedded](https://github.com/moonlight-stream/moonlight-embedded), historical [Moonlight Chrome](https://github.com/moonlight-stream/moonlight-chrome), [Moonlight Common C](https://github.com/moonlight-stream/moonlight-common-c), and [Moonlight V+](https://github.com/qiin2333/moonlight-vplus). The pinned protocol submodule uses the upstream [VoidLink C fork](https://github.com/TrueZhuangJia/voidlink-c).

Selene is an independent community project. References do not imply official affiliation or endorsement.

## License and contributions

Distributed under [GPLv3](LICENSE.txt). Dependencies retain their own licenses. Contributions and reproducible bug reports are welcome; include device model, tvOS and host versions, stream settings, and reproduction steps. Remove private addresses and pairing codes from shared evidence.
