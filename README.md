# 🐔 Crossy Sikto

## 📖 The Story

This started as a random curiosity.

I was watching TV with my cousin and suddenly wondered:
**“Can we actually build TV apps using Flutter?”**

So I tried.

With some help from AI, I built a simple Flutter app template for TV. The biggest difference from mobile?
👉 No touchscreen — everything is controlled using a **D-pad**.

I enabled developer mode on the TV, connected it using:

```bash
adb connect <ip-address>
```

…and boom — the app was running on the TV 🎉

That experiment turned into **Crossy Sikto**.

---

## 🎮 About the Game

**Crossy Sikto** is a vibrant, endless arcade game inspired by *Crossy Road*, built specifically for **Android TV** and **Google TV** using **Flutter**.

It’s designed from the ground up for the big screen, with smooth gameplay, procedural environments, and intuitive remote controls.

---

## 🎥 Gameplay

[![Watch the gameplay demo](https://img.youtube.com/vi/2qonsfFVH-4/0.jpg)](https://youtube.com/shorts/2qonsfFVH-4)

> Click to watch the demo

---

## 🌟 Features

* 📺 **TV-First Experience**
  Designed specifically for TV screens with full D-pad navigation.

* 🛣️ **Endless Gameplay**
  Procedurally generated worlds — every run is unique.

* 🌊 **Dynamic Obstacles**
  Dodge traffic, cross rivers on moving logs, and survive unpredictable terrain.

* 🎵 **Immersive Sound**
  Retro-style sound effects and adaptive background music.

* 📈 **Score System**
  Live score tracking + persistent high score.

* ✨ **Polished Feel**
  Smooth camera movement, squash/stretch animations, and particle effects.

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (stable recommended)
  [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

* Android SDK + Command Line Tools

* Android TV device or emulator (ADB enabled)

---

### Installation

```bash
git clone <repository-url>
cd tv
flutter pub get
```

---

### Run on TV

1. Connect your TV:

```bash
adb connect <ip-address>
```

2. Run the app:

```bash
flutter run
```

---

## 🎮 Controls

Designed for **TV remotes & gamepads**:

| Action        | Input              |
| ------------- | ------------------ |
| Move Up       | D-Pad Up / ↑       |
| Move Down     | D-Pad Down / ↓     |
| Move Left     | D-Pad Left / ←     |
| Move Right    | D-Pad Right / →    |
| Jump / Select | OK / Enter / Space |
| Back / Menu   | Back / ESC         |

---

## 📁 Project Structure

```
lib/
 ├── game/        # Core game logic
 │   ├── player.dart
 │   ├── lane.dart
 │   └── crossy_game.dart
 │
 ├── ui/          # UI screens (HUD, Menu, Game Over)
 │
assets/
 ├── img/         # Sprites & icons
 └── audio/       # Sound effects & music
```

---

## 🛠️ Built With

* **Flutter** — UI & rendering engine
* **audioplayers** — audio system

---

## 💡 Why This Project?

This isn’t just a game — it’s a **proof of concept**:

👉 Flutter can be used to build smooth, production-quality **TV apps & games**
👉 D-pad based UX is a completely different design challenge
👉 Rapid prototyping with AI + Flutter is insanely powerful

---

## ⭐ Future Ideas

* Leaderboard system
* More characters & skins
* Difficulty scaling
* Gamepad vibration support
* Multiplayer mode 👀

---

## 🙌 Final Note

Built as a fun experiment — but turned into something surprisingly polished.

If you found this interesting, give it a ⭐ or try building your own TV app with Flutter 🚀
