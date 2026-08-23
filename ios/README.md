<div align="center">
  <img src="Forma/Assets.xcassets/AppIcon.appiconset/Frame%2055(3).png" width="112" alt="Forma app icon">

  # Forma

  **Your body, understood over time.**

  A polished iOS body-composition companion that records smart-scale measurements and turns them into clear, personal fitness insights.

  [![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat-square)](https://www.swift.org)
  [![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS-111111.svg?style=flat-square)](https://developer.apple.com/ios/)
  [![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF.svg?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
  [![License: AGPL v3](https://img.shields.io/badge/license-AGPL--3.0-663399.svg?style=flat-square)](LICENSE)
</div>

---

## Overview

Forma connects to a supported Bluetooth Low Energy scale, captures weight, impedance, and heart rate, and securely submits the reading for analysis. The resulting report is presented through gauges, trend lines, composition maps, and focused recommendations designed to make long-term progress easier to understand.

The interface is built entirely in SwiftUI, uses Swift Charts for data visualization, and follows a dark, glass-inspired visual system with accessible motion handling and a custom Cormorant Garamond wordmark.

## Features

| Area | What Forma provides |
| --- | --- |
| **Smart-scale recording** | Discovers a BLE scale, streams weight → impedance → heart rate, validates packets, and presents each stage in a focused recording flow. |
| **Personal insights** | Displays an overview, foundation, progress, recommended focus, physique archetype, and a 0–100 effort score from the latest report. |
| **Performance analytics** | Includes FFMI and excess-fat gauges, an FMI-vs-FFMI quadrant, body-composition flow, composition trends, and recomp vectors. |
| **Fat analytics** | Tracks body-fat ratio, visceral and subcutaneous fat, total fat mass, and changes over time with gauges, donut charts, and trend charts. |
| **Muscle analytics** | Surfaces muscle mass, muscle ratio, skeletal muscle, and bone-mass trends when available in the report. |
| **Profiles** | Creates and edits client profiles, stores the primary profile locally, and supports profile-specific goals and measurements. |
| **Authentication** | Uses Clerk for sign-in, session-backed API authorization, and account management. |
| **Resilient reports** | Polls asynchronous report jobs, supports pull-to-refresh, remembers pending jobs, and caches the latest completed report on-device. |
| **Native experience** | Uses SwiftUI navigation, Swift Charts, adaptive system colors, Liquid Glass controls, Reduce Motion support, and iPhone/iPad layouts. |

> [!NOTE]
> Metrics, recording, authentication, profiles, and settings are implemented.

## From scale to insight

```mermaid
flowchart LR
    U([User]) --> A[Clerk sign-in]
    A --> P[Primary profile]
    P --> R[Start a reading]
    R --> B{BLE scale}
    B --> W[Weight]
    W --> I[Impedance]
    I --> H[Heart rate]
    H --> API[Authenticated measurement API]
    API --> J[Asynchronous report job]
    J -->|pending / running| J
    J -->|completed| C[(Protected local cache)]
    C --> D[Insights dashboard]

    classDef accent fill:#0f766e,color:#fff,stroke:#2dd4bf;
    classDef data fill:#172554,color:#fff,stroke:#60a5fa;
    class B,API,J accent;
    class C,D data;
```

The recording screen keeps metrics readable even when the scale sends values almost simultaneously. Each stage remains visible briefly, the device idle timer is leased during a reading, and failed submissions can be retried without repeating the measurement.

## Analytics at a glance

```mermaid
graph TD
    M[Metrics report] --> IN[Insights]
    M --> PE[Performance]
    M --> FA[Fat]
    M --> MU[Muscle]

    IN --> IN1[Progress trends]
    IN --> IN2[Effort score]
    IN --> IN3[Personal recommendations]

    PE --> PE1[FFMI and FMI]
    PE --> PE2[Composition flow]
    PE --> PE3[Recomp vector]

    FA --> FA1[Body-fat ratio]
    FA --> FA2[Visceral vs subcutaneous]
    FA --> FA3[Fat-mass history]

    MU --> MU1[Muscle mass and ratio]
    MU --> MU2[Skeletal muscle]
    MU --> MU3[Bone-mass trends]
```

## Architecture

```mermaid
graph TB
    subgraph App[SwiftUI application]
        ENTRY[FormaApp] --> AUTH{Authenticated?}
        AUTH -->|No| SIGNIN[ClerkSignInView]
        AUTH -->|Yes| GATE[PrimaryProfileGate]
        GATE --> ROOT[TabView]
        ROOT --> METRICS[MetricsView]
        ROOT --> RECORD[RecordView]
        ROOT --> SETTINGS[Settings]
    end

    subgraph Services
        BLE[ScaleBLEManager]
        CLIENT[APIClient]
        TOKEN[ClerkTokenProvider]
        STORE[MetricsReportStore]
    end

    subgraph Data
        BACKEND[Forma API]
        PROFILE[(Primary profile ID)]
        REPORT[(Report cache)]
    end

    RECORD --> BLE
    RECORD --> CLIENT
    METRICS --> STORE
    STORE --> CLIENT
    CLIENT --> TOKEN
    CLIENT --> BACKEND
    GATE --> PROFILE
    STORE --> PROFILE
    STORE --> REPORT
```

The networking layer is request-driven: each endpoint conforms to `APIRequest`, while `APIClient` handles URL construction, Clerk bearer tokens, JSON encoding, status validation, and decoding. UI state stays on the main actor and report data is converted into presentation-friendly sections by `InsightReportPayload`.

## Tech stack

| Layer | Technology |
| --- | --- |
| Language | Swift 5 language mode with approachable concurrency and main-actor isolation |
| UI | SwiftUI |
| Visualization | Swift Charts and custom SwiftUI shapes |
| Device integration | CoreBluetooth |
| Authentication | [ClerkKit and ClerkKitUI](https://github.com/clerk/clerk-ios) 1.2.6+ |
| Networking | URLSession, async/await, Codable |
| Persistence | UserDefaults and protected JSON files in Application Support |
| Testing | Swift Testing and XCUITest |

## Project structure

```text
Forma/
├── FormaApp.swift                 # Application entry point and Clerk setup
├── ContentView.swift              # Authentication and profile gate
├── SwiftUIView.swift              # Root tabs and global navigation
├── RecordView.swift               # Guided measurement experience
├── ScaleBLEManager.swift          # BLE discovery and scale communication
├── Profiles.swift                 # Profile list and create/edit flows
├── Metrics/
│   ├── Insights/                  # Summaries, recommendations, and effort
│   ├── Performance/               # FFMI, composition, and recomp visuals
│   ├── Fat/                       # Fat gauges, breakdowns, and trends
│   └── Muscle/                    # Muscle and bone trend cards
├── Networking/
│   ├── APIClient.swift            # Shared authenticated HTTP client
│   ├── Measurements/              # Measurement ingestion requests
│   ├── Profiles/                  # Profile requests and models
│   └── Insights/                  # Report jobs, payloads, polling, and cache
└── Assets.xcassets/               # App icon and body illustrations

FormaTests/                        # Decoder, record-flow, and report tests
FormaUITests/                      # UI and launch tests
```

## Requirements

- macOS with **Xcode 26.5 or newer**
- **iOS/iPadOS 26.5+** deployment target
- A Clerk account accepted by the configured Forma environment
- Network access to the Forma API for profiles, measurement uploads, and reports
- A compatible BLE scale exposing service `FFF0` and notify characteristic `FFF4` for live recordings

The analytics screens can run in Simulator, but live scale capture requires a physical iPhone or iPad with Bluetooth enabled.

## Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/aneeshpatne/Forma_IOS.git
   cd Forma_IOS
   ```

2. Open `Forma.xcodeproj` in Xcode. Swift Package Manager will resolve Clerk automatically.

3. Review the environment values before running:

   - `Forma/ClerkConfig.swift` contains the Clerk publishable key.
   - `Forma/Networking/APIConfig.swift` contains the API base URL.
   - `Forma/Info.plist` contains the Bluetooth usage description and Clerk callback scheme.

4. Select an iOS 26.5+ simulator or connected device, then build and run with **⌘R**.

5. Sign in and create a primary profile. A primary profile is required before entering the main app.

> [!IMPORTANT]
> This repository currently points at a hosted Forma API and a Clerk test environment. Use your own environment values before distributing a fork.

## Running tests

Run the `FormaTests` and `FormaUITests` schemes from Xcode with **⌘U**, or use the command line with an installed simulator:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild test \
  -project Forma.xcodeproj \
  -scheme Forma \
  -destination 'platform=iOS Simulator,name=<your simulator>'
```

The unit suite covers BLE packet decoding, ordered measurement presentation, idle-timer restoration, chart helpers, and report payload/cache round-tripping.

## Roadmap

- Expand supported smart-scale protocols
- Add screenshot and UI regression coverage
- Make backend and Clerk environments configurable per build configuration

## License

Forma is distributed under the [GNU Affero General Public License v3.0](LICENSE). If you modify and distribute the app—or provide a modified version over a network—you must make the corresponding source available under the same license.

---

<div align="center">
  Built with SwiftUI, CoreBluetooth, and a fondness for charts that actually explain something.
</div>
