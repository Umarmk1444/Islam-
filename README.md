<div align="center">

# 📖 Quran Zone: Quran, Audio & Learn

**An interactive, offline-first Islamic companion application engineered for seamless Quran study, synchronized audio playback, and comprehensive Islamic resources.**

[![Google Play](https://img.shields.io/badge/Google_Play-500%2B_Downloads-34A853?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.umer.quranzone)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android&logoColor=white)](https://play.google.com/store/apps/details?id=com.umer.quranzone)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br />

[📲 Download on Google Play](https://play.google.com/store/apps/details?id=com.umer.quranzone) • [🐛 Report Bug](https://github.com/Umarmk1444/Islam-/issues) • [✨ Request Feature](https://github.com/Umarmk1444/Islam-/issues)

</div>

---

## 🌟 Key Features

### 🎙️ Synchronized Recitation & Noorani Qaida
- **Tap-to-Listen Audio Engine:** Word-by-word synchronized highlighting to master pronunciation.
- **Interactive Noorani Qaida:** Systematic phonetics curriculum for beginners with instant audio feedback.
- **Top Reciters:** Offline and streaming audio support for Alafasy, Minshawi, Sudais, Abdulbasit, and more.

### 📚 Offline Tafsir & Arabic Grammar
- **Offline Tafsir Engine:** Verse-by-verse authentic Tafsir stored locally for zero-latency reading without internet.
- **Quranic Irab (Grammar):** In-depth syntactic and morphological breakdown for students of the language.

### 📑 Custom In-App PDF Reader
- Optimized document rendering engine with horizontal page flips and continuous vertical scroll.
- Distraction-free interface featuring Eye-Care Themes: **Crisp Day**, **Inverted Night**, and **Warm Sepia**.
- Instant in-document search and persistent reading session memory.

### 🌍 Multilingual Localization (i18n)
Full support for authentic translations and localizations:
- **English**
- **Amharic (አማርኛ)**
- **Afaan Oromoo**

### 🧭 Real-Time Daily Utilities
- **Accurate GPS Prayer Calculation:** Automated prayer times, countdown widgets, and auto-silent mode during Salah.
- **Live Haramain Streaming:** 24/7 video broadcasts from Makkah & Madinah alongside 175+ Islamic radio stations.
- **Digital Tasbih & Azkar:** Haptic vibration feedback counter integrated with *Hisn Al-Muslim* supplications.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** Flutter / Dart
- **Architecture:** Clean Architecture / MVVM
- **Local Storage:** SQLite & SharedPreferences (Offline-First)
- **Audio Processing:** Just_Audio / Audio Service with background controls
- **Background Tasks:** WorkManager for Adhan scheduling and silent mode triggers
- **Sensors & Location:** Geolocator & Compass APIs for Qibla and Salah calculation

---

## 🚀 Getting Started

To run and build this project locally, ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Android Studio / VS Code
- Android SDK (API Level 21+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Umarmk1444/Islam-.git](https://github.com/Umarmk1444/Islam-.git)
   cd Islam-
