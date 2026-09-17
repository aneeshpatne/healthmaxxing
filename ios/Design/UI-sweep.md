# Forma UI refresh

Crisp neutral canvas with clean white cards and a near-black primary action color. Teal, blue, green, amber, rose, and gold remain distinct semantic and chart accents. Tinted cards use only a restrained wash and hairline so color adds hierarchy without overwhelming the content. Dark mode uses true charcoal surfaces with pure white primary accents. Primary buttons invert cleanly: white on near-black in light mode and near-black on white in dark mode.

All segmented gauges share a deliberate coral → amber → green → teal → blue progression, independent of the monochrome interaction accent. The Forma mark renders in its original cyan–green–lime gradient. Typography is unified on the native SF Pro system family, including the wordmark, for consistent proportions and Dynamic Type behavior.

The app no longer waits behind a timed launch overlay or report-success interstitial. Recording has a static action disc and immediate success mark. Removed idle rings, glow, label movement, spring celebrations, skeleton pulsing, gauge entrance sweeps, animated background washes, and the WebView report animation. Kept brief direct state feedback, system navigation, and progress indicators for actual work. Scale measurement staging remains intact so readings stay understandable.

48 original SVG icons cover 55 semantic names across navigation, food, settings, profiles, recording, and report callouts. Artwork is stored as template vector assets, preserving tint and resolution. See `icon-contact-sheet.svg` for the full set. System-owned controls, the authentication provider interface, and the existing app/brand identity remain platform or brand assets; the in-app brand mark uses the new accent tint.

Verification: unsigned generic iOS device build, asset XML/JSON validation, light/dark semantic color contrast audit, and diff whitespace checks. No simulator was opened; screen layout and gestures were not visually exercised on a device.
