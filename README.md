# MConfPoC

SwiftUI wrapper around the CVE-2026-112706 CoreMedia FD-leak PoC.

## Build via GitHub Actions
Push to `main` or trigger the workflow manually. Required secrets:

| Secret | Value |
| --- | --- |
| `P12_BASE64` | base64 of your distribution `.p12` |
| `P12_PASSWORD` | password of that `.p12` |
| `PROVISIONING_PROFILE_BASE64` | base64 of your `.mobileprovision` |
| `KEYCHAIN_PASSWORD` | any random string |
| `APPLE_TEAM_ID` | your Apple Developer Team ID |

The IPA lands as the `MConfPoC-IPA` artifact. `sample.mov` is generated
on the runner via ffmpeg, so nothing binary lives in this repo.

## Notes
The underlying bug is patched on current iOS. This harness is for
regression testing and reproduction only — don't ship it.