# RepoHub for macOS

Native SwiftUI app plus two desktop widgets:

- **Pinned Repos**: opens the repository on GitHub when you click a name.
- **Pinned Sites**: opens the repo's deployed website. That's the repo's homepage URL when set, otherwise its GitHub Pages URL (custom domain included).

Both widgets come in small, medium, large and extra-large sizes and list repo names only. They use a Liquid Glass background on macOS 26 and later, with a translucent material on macOS 14–15.

Pin repos in the app window. Drag pins to reorder them. Clicking a widget row opens the link in your default browser.

## Build

```sh
brew install xcodegen
cd macos
xcodegen generate
open RepoHub.xcodeproj
```

Select your team under *Signing & Capabilities* for both targets, then run.

## Signing

The app and widget share pins through an App Group, and widgets only load from properly signed apps. CI builds are ad-hoc signed unless you add these repository secrets, in which case the DMG is Developer ID signed and notarized:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | Base64 of your *Developer ID Application* certificate (.p12) |
| `MACOS_CERTIFICATE_PASSWORD` | Password for that .p12 |
| `APPLE_TEAM_ID` | Your 10-character Team ID |
| `APPLE_ID` | Apple ID email used for notarization |
| `APPLE_APP_PASSWORD` | App-specific password for that Apple ID |

Ad-hoc builds run, but macOS will warn on first launch (right-click → Open), and the widgets may not appear or may not see your pins.
