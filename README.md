# MConfPoC - CVE-2026-112706

A SwiftUI-based proof-of-concept harness for reproducing a File-Descriptor (FD) leak in Apple's CoreMedia framework.

## Overview
MConfPoC is a lightweight security harness designed to trigger a file-descriptor leak within Apple's CoreMedia and AVFoundation pipelines. By rapidly opening, reading, and discarding media assets without explicit teardown, the PoC forces the underlying framework to leak file descriptors, which can eventually lead to application crashes or resource exhaustion.

Note: The underlying vulnerability (CVE-2026-112706) has been patched in current iOS releases. This tool is intended strictly for regression testing, security analysis, and patched-device verification.

## How It Works
The application runs a 200-iteration loop that performs the following sequence:

1. Materialize: Copies a bundled sample.mov into a temporary directory.
2. Initialize: Creates an AVURLAsset and asynchronously loads its tracks and duration.
3. Pipeline Setup: Builds an AVAssetReader and attaches AVAssetReaderTrackOutput to the video/audio tracks.
4. Drain and Drop: Reads a few sample buffers to force CoreMedia to map the file into memory, cancels reading, and drops all references without an explicit teardown.
5. Measure: Uses the low-level fcntl API to count active file descriptors, comparing the baseline against the final count to detect anomalies.

Why fcntl? The traditional /dev/fd directory listing is restricted by the iOS sandbox. MConfPoC uses F_GETFD via fcntl to safely and accurately count active descriptors.

## Features

- Minimalist SwiftUI Interface: Clean, native iOS design with real-time FD tracking and colored logs.
- Asynchronous Execution: Heavy media lifting is pushed to Task.detached to prevent the iOS Watchdog from killing the app due to main-thread blocking.
- Cloud-Native Builds: Fully automated, unsigned .ipa generation via GitHub Actions using XcodeGen and ffmpeg. No signing certificates required.
- Dynamic Asset Generation: The CI pipeline dynamically generates a 2-second sample.mov on the fly, meaning no heavy binary files pollute the repository.

## Build and Run

### Local Build (Xcode)
1. Clone the repository.
2. Ensure you have a sample.mov in the Resources/ folder.
3. Open the project (generated via xcodegen generate if needed) and run on an iOS device or simulator.

### Cloud Build (GitHub Actions)
MConfPoC is designed to be built entirely in the cloud. 
1. Push your code to the main branch.
2. Navigate to the Actions tab and select "Build MConfPoC Unsigned IPA".
3. Once complete, download the MConfPoC-unsigned-IPA artifact.

Note: Because the IPA is unsigned, you will need to sign it yourself using tools like Sideloadly, AltStore, or a developer certificate before installing it on a physical device.

## Disclaimer
This project is provided "as-is" for security analysis and regression testing. Do not use this to target systems you do not own. The vulnerability is patched; this harness serves as a historical regression test and a demonstration of modern iOS media pipeline resource management.