<div align="center">

# ✦ NULL ✦
### Pure Dark. Zero Friction. Just Your Thoughts.

An ultra-minimalist, pure dark notes and thinking sanctuary crafted with obsessive precision in Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Storage](https://img.shields.io/badge/Storage-Hive%20Binary-yellow?style=for-the-badge&logo=hive&logoColor=black)](https://pub.dev/packages/hive)
[![License](https://img.shields.io/badge/License-MIT-white?style=for-the-badge)](LICENSE)

[Features](#-key-features) • [Smart Typography](#-smart-words-formatting-engine) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Privacy Policy](PRIVACY_POLICY.md) • [Developer](#-author)

---

</div>

## 🌌 Philosophy & Essence

Most note-taking applications clutter your mind with complex menus, nested folders, syncing spinners, and distracting toolbars. **Null** strips away everything that is not your immediate thought:

- **Uncompromising Pitch-Black Canvas (`#000000`)**: Designed for midnight brain dumps, deep focus, and zero eye fatigue.
- **Immediate Action**: Opens directly to a clean empty draft editor by default—ready for your first keystroke.
- **Fluid Morphing Physics**: A minimalist glowing indicator circle that fluidly transforms into a floating editorial formatting toolbar.
- **100% Offline & Private**: Zero cloud sync, zero telemetry, zero accounts. Every word is saved in sub-millisecond local binary storage.

---

## ✨ Key Features

### 1. 🖋️ Smart Words Formatting Engine
Expressive emotions, Gen Z slang, and aesthetic expressions automatically format into bespoke typography as you type in real time:
- **💖 Love & Affection** (`love`, `dear`, `heart`, `forever`, `adore`, `sweet`, `kiss`, `plea+se`...) $\to$ *`Aloevera` italic script with soft rose blush*.
- **⚡ Intensity & Drama** (`hate`, `rage`, `anger`, `never`, `burn`, `chaos`, `fire`, `cooked`, `crying`, `dying`, `down bad`, `noo+`, `bruh+`...) $\to$ *`BasementGrotesque` w900 stark bold*.
- **💅 Gen Z Slang & Lore** (`fr`, `frfr`, `lowkey`, `highkey`, `ngl`, `tbh`, `nocap`, `cap`, `delulu`, `rizz`, `aura`, `slay`, `valid`, `period`, `iykyk`, `idk`, `rn`, `omg+`...) $\to$ *`Coolvetica` w600 with soft violet glow*.
- **💰 Wealth & Ambition** (`money`, `cash`, `wealth`, `rich`, `gold`, `empire`, `success`, `dollar`, `crypto`, `bag`...) $\to$ *`Futura` w600 with soft amber gold highlight*.
- **✨ Eras & Manifestation** (`era`, `main character`, `manifest`, `manifesting`, `healing`, `vibe`, `vibes`, `glow up`, `obsessed`, `so real`, `literally`, `yess+`...) $\to$ *`Beatrice` italic bold*.
- **🐞 Miraculous & Fandom Lore** (`marinette`, `adrien`, `cat noir`, `tikki`, `plagg`, `iyamatwm`, `spots on`, `claws out`, `miraculous`, `kwami`...) $\to$ *Parisian Ladybug Rose / Cat Noir Neon Lime accents*.
- **🌌 Void & 3AM Solitude** (`dark`, `light`, `void`, `null`, `infinite`, `peace`, `breathe`, `sleep`, `dream`, `silence`, `3am`, `midnight`, `whyy+`...) $\to$ *`Agitha` italic with soft sky highlight*.

### 2. 🪄 Non-Destructive Selection Toolbar
- High-performance text interval slicing for word-level and selection-level formatting.
- Instant access to **Highlighting**, **Bold**, **Italic**, **Underline**, **Typeface Swapping**, and **Font Size Adjustments**.
- Manual selections always take 100% priority over smart defaults.

### 3. 🌀 Integrated Editorial Overscroll Reveals
- When overscrolling past the oldest note, an editorial vertical spine ($270^\circ$ rotated bold typography) reveals context-aware witty messages (`"aha no more stuff here"`, `"break the flow here bruhh"`).

### 4. ⚙️ Dark-Glass Settings & Preferences
- **Open to New Note vs Resume Note**: Choose whether to start fresh on launch or resume right where you left off.
- **Smart Words Styling Toggle**: Seamlessly toggle automatic smart word formatting ON or OFF.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── controllers/      # NullRichTextController (Interval slicing text builder)
│   ├── fonts/            # Custom typefaces (SF Pro, Beatrice, Aloevera, Coolvetica, etc.)
│   ├── models/           # Note, QuoteItem, SpanStyle models
│   ├── services/         # NotesService (Hive binary database & reactive state)
│   └── typography/       # SmartWordsEngine (Regex token matching & styling)
├── screens/
│   ├── editor/           # EditorScreen, EditorState
│   └── settings/         # SettingsScreen & Glass preference tiles
├── widgets/              # NullBottomDock, NullGlowingRing, NullSelectionContextMenu
└── main.dart             # NullUniversalShell, Lifecycle observer & routing
```

- **Framework**: Flutter 3.x (Dart 3.x)
- **Database**: Pure Dart [Hive](https://pub.dev/packages/hive) NoSQL Binary Storage
- **Typography Engine**: Bespoke multi-span controller running at 120fps with zero layout jank

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.24.0 or higher)
- Android Studio / VS Code / Xcode

### Installation
```bash
# Clone the repository
git clone https://github.com/GauravGadhari/null-notes.git
cd null-notes

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Launch on your device or emulator
flutter run
```

---

## 🔒 Privacy & Security

Null is built with privacy at its core:
- **Zero Data Collection**: No personal information, note text, or device telemetry is ever collected.
- **100% Offline**: Operates completely disconnected from the internet.
- Read the full [Privacy Policy](PRIVACY_POLICY.md).

---

## 👤 Author

**Gaurav Gadhari**
*Visionary Developer, AI Architect & Next-Gen Software Pioneer*

- **Website**: [gaurav-gadhari.vercel.app](https://gaurav-gadhari.vercel.app)
- **GitHub**: [@GauravGadhari](https://github.com/GauravGadhari)
- **LinkedIn**: [Gaurav Gadhari](https://www.linkedin.com/in/gaurav-gadhari-579558275/)
- **Twitter / X**: [@AGauravHere](https://x.com/AGauravHere)
- **Instagram**: [@a_gaurav_here](https://www.instagram.com/a_gaurav_here/)
- **YouTube**: [@codewithgaurav37](https://www.youtube.com/@codewithgaurav37)
- **Email**: [gauravgadhari39@gmail.com](mailto:gauravgadhari39@gmail.com)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
