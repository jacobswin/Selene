# Selene development handoff

Start with [building and signing](BUILDING.md) and [verification](SELENE_VERIFICATION.md). Open `Selene.xcodeproj`, scheme **Selene**. The inherited iOS and preview targets are not validated deliverables.

Use a 4K Apple TV simulator for interface checks. The physical development device was identified as second-generation Apple TV 4K (AppleTV11,1), tvOS 26.6; earlier third-generation assumptions were corrected. The host is Foundation Sunshine.

Keep bundle ID and persistent store keys unchanged when updating the existing installation. Choose your own signing team; no personal certificate or team is published. Preserve the pinned recursive submodules and Package.resolved.

Current work and remaining physical streaming checks are recorded in [SELENE_VERIFICATION.md](SELENE_VERIFICATION.md).
