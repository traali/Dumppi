# 🏔️ Dumppi: The Ultimate Freeride Forecast

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)
[![Open-Meteo](https://img.shields.io/badge/Weather-Open--Meteo-blue)](https://open-meteo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Dumppi** is a high-performance freeride hunting tool designed for skiers and snowboarders who chase elite conditions across Europe and Norway. It combines high-resolution weather data with an interactive topographic map to visualize exactly where and when the best snow will fall.

## 🚀 Key Features

*   🌍 **Dynamic Viewport Loading**: Automatically generates a high-resolution forecast grid for your active map area. Pan across the Alps and watch the heatmap update in real-time.
*   ❄️ **7-Day Accumulation Heatmap**: Instantly spot "snow holes" with color-coded gradients showing cumulative snowfall.
*   💨 **Directional Wind Overlays**: High-fidelity vector arrows visualize wind speed and direction, critical for understanding lee-side loading and wind-slab risk.
*   🔍 **Resort-Grade Forensics**: Tap any point or resort to see a deep-dive hourly forecast with "Powder Quality" indicators.
*   ⭐ **Secret Stash Management**: Save your favorite resorts or drop custom coordinates for hidden couloirs.
*   🛰️ **Topographic Precision**: Integrated OpenSnowMap piste data and transparent relief shading for true mountain orientation.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev) (Cross-platform).
*   **Weather Engine**: [Open-Meteo API](https://open-meteo.com).
*   **GIS**: [flutter_map](https://github.com/fleaflet/flutter_map) + OSM Topo tiles.

## 🏃 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- A mobile emulator or browser (Chrome/Edge)

### Installation

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/your-username/Dumppi.git
    cd Dumppi
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run -d chrome
    ```

## ☁️ Deployment

Optimized for **Cloudflare Pages**. Build the project with:
```bash
flutter build web --release
```

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---
*Created with ❤️ for the freeride community. Shred safe.*
