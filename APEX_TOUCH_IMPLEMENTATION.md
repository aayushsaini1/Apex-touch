# Apex Touch - Implementation Proposal & Product Documentation

## 1. Project Overview

**Apex Touch** is a high-performance telemetry dashboard designed for racing simulators (specifically the F1 game series). It bridges the gap between the racing rig and the user's wrist (or mobile device), providing real-time, low-latency data visualization and tactile feedback.

The project is currently implemented as a **watchOS app**, with a planned expansion into a **fully customizable iOS dashboard**.

---

## 2. Core Functional Requirements

### 2.1 Live Telemetry Stream

- **UDP Protocol**: Listens for incoming UDP packets on port `20777`.
- **Packet Support**: Full support for F1 Game telemetry standards (Car Telemetry, Session, Lap Data, Participants, Car Status, and Events).
- **Auto-Detection**: Automatic local IP detection to simplify connection between the racing rig and the device.

### 2.2 Dashboard Visualization

- **Dynamic RPM Meter**: A circular, color-coded gauge (Green → Yellow → Orange → Red → Purple/Flash) representing engine stress and optimal shift points.
- **Gear Indicator**: Prominent display of current gear (1-8, N, R, or "IN PIT").
- **Real-Time Physics**: Display of Speed (KPH), Position (P1-P22), Current Lap, and Tire Compound.
- **Adaptive Visual States**:
  - **Safety Car**: Global yellow UI shift with active alert text.
  - **Pit Lane**: Yellow "IN PIT" override with speed monitoring.
  - **Chequered Flag**: Victory screen with final ranking and header graphics.
  - **DNF**: Darkened "Disabled" state with "DNF" alert.

### 2.3 Tactile Experience (Haptics)

- **Mechanical Gear Shifts**: Silent but intense vibration patterns that simulate the physical impact of a gear change.
  - **Upshift**: Triple-click rapid pulse.
  - **Downshift**: Double-click rapid pulse.
- **Constraint**: Designed to be completely silent (no system chimes) to avoid interference with racing headphones.

### 2.4 Background Persistence

- **Extended Runtime**: Integration with `WKExtendedRuntimeSession` (Watch) and equivalent Background Modes (iOS) to ensure the telemetry stream is not interrupted when the device dims or backgrounded.

---

## 3. Technical Architecture (Current)

### 3.1 Stack

- **Languages**: Swift 6.0
- **Frameworks**: SwiftUI, Combine, Network (NWListener), WatchKit.
- **Font System**: Orbitron (Sci-fi/Racing aesthetic).

### 3.2 Key Components

| Component            | Responsibility                                                            |
| :------------------- | :------------------------------------------------------------------------ |
| `UDPListener`        | Manages the low-level socket connection and handles raw buffer reception. |
| `DataParser`         | Decodes byte-arrays into Swift structs using memory layout mapping.       |
| `TelemetryViewModel` | The "Brain"—coordinates state updates, UDP data, and background sessions. |
| `HapticManager`      | Handles the sequencing of silent tactile pulses.                          |
| `ContentView`        | Responsive UI layout that adapts to different screen sizes and states.    |

---

## 4. iOS Roadmap & Phase 2 Implementation

The iOS implementation will mirror the core logic of the Watch app but leverage the larger screen real estate and advanced GPU capabilities.

### 4.1 Feature Expansion

- **Custom Dashboard Builder**: A drag-and-drop editor where users can reposition metrics (RPM, Speed, Lap Time).
- **Modular Widgets**: Toggleable widgets for:
  - Tire Temperatures (Surface & Inner)
  - Brake Temps
  - ERS Deployment/Harvesting
  - Damage Indicators
- **Visual Profiles**: ability to save and switch between "Minimalist", "Engine Tech", and "Race Master" UI styles.

### 4.2 Technical Adaptations for iOS

- **Haptic Engine**: Upgrade to `UIImpactFeedbackGenerator` or `CoreHaptics` (AHAP patterns) for even more granular vibration control.
- **Connectivity**: Local Network permissions handling for seamless iOS-to-Rig communication.
- **Landscape Optimization**: Dual-view support for phone mounts on racing wheelbases.

---

## 5. Development Guidelines

- **Performance First**: Data processing happens on background threads; UI updates are throttled to avoid overhead.
- **Silent Feedback**: Never use tonal haptics; maintain the "silent but tactile" philosophy.
- **Color Accuracy**: Team colors are mapped exactly to their real-world racing counterparts (Mercedes Teal, Ferrari Red, etc.).
