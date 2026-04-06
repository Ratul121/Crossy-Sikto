# Crossy Road TV 🐔

A vibrant, endless arcade game inspired by the classic "Crossy Road," specifically engineered for a premium experience on **Android TV** and **Google TV**. Built with **Flutter**, it features smooth animations, procedurally generated worlds, and intuitive D-pad controls.

<div align="center">
  <video src="https://github.com/Ratul121/Crossy-Sikto/raw/main/assets/video/Crossy%20Sikto.mp4" width="720" controls autoplay loop muted>
    Your browser does not support the video tag.
  </video>
</div>

## 🌟 Features

- **📺 TV Optimized**: Full D-pad support and landscape-first UI designed for the big screen.
- **🛣️ Endless Adventure**: Procedural world generation ensures no two runs are the same.
- **🌊 Dynamic Hazards**: Navigate through busy roads, treacherous rivers with floating logs, and grassy safe zones.
- **🎵 Immersive Audio**: Retro sound effects and background music that adapt to your gameplay.
- **📈 Score Tracking**: Real-time HUD showing your current score and all-time high score.
- **✨ Polished Aesthetics**: Smooth camera panning, character "squish" animations, and particle effects.

## 🚀 Getting Started

### Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (Stable channel recommended)
- **Android SDK** with Command Line Tools
- An **Android TV** device or **Android TV Emulator** with ADB enabled.

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd tv
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Launch the app**:
   - Ensure your TV/Emulator is connected via `adb connect <ip-address>`.
   - Run the application:
     ```bash
     flutter run
     ```

## 🎮 Controls

The game is designed to be played with a standard TV Remote or Gamepad:

| Action | Remote / Keyboard |
| :--- | :--- |
| **Move Up** | D-Pad Up / Arrow Up |
| **Move Down** | D-Pad Down / Arrow Down |
| **Move Left** | D-Pad Left / Arrow Left |
| **Move Right** | D-Pad Right / Arrow Right |
| **Select / Jump** | Center / Enter / Space |
| **Back / Menu** | Back Button / Escape |

## 📁 Project Structure

- **`lib/game/`**: The core game engine, including player logic (`player.dart`), world generation (`lane.dart`), and main loop (`crossy_game.dart`).
- **`lib/ui/`**: All UI components including the HUD, Menu, Settings, and Game Over screens.
- **`assets/`**:
  - `img/`: Pixel art sprites and game icons.
  - `audio/`: All sound effects (SFX) and background music (BGM).

## 🛠️ Built With

- **Flutter**: For the cross-platform UI and rendering.
- **Audioplayers**: For high-performance audio management.

---
*Developed as a high-quality TV gaming demonstration.*
