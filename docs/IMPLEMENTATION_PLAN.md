# Selene implementation

The current product name, Xcode project, scheme and main tvOS target are Selene.
The development bundle ID, `com.jacob.moonlightplus.tvos`, and existing store keys remain unchanged for upgrade compatibility.

Implemented: persistent host picker; native focus restoration keyed by host/app identity; one paired-host entry; coordinated whole-card focus; no tvOS keyboard prewarm or touch-widget creation. Existing bitrate, HDR, codec, and audio paths remain in place.

The active Core Data model contents are byte-identical to the baseline; only its resource version filename is renamed. Copyright and upstream source information remain in the license and attribution docs.

See [building](BUILDING.md), [current test record](SELENE_VERIFICATION.md), and [English README](../README.md). Do not infer physical codec/HDR/audio support from a successful simulator run.
