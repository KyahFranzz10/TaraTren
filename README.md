# 🚆 Tara Tren
<p align="center">
  <img src="assets/image/Gemini_Generated_Image_wfqe9iwfqe9iwfqe.png" alt="Tara Tren Banner" width="100%">
</p>

> **Your Unified Transit Companion for Metro Manila.**

**TaraTren** is a modern, community-driven mobile application designed to simplify the commuting experience across the Philippines' capital. It consolidates all major rail lines, provides real-time crowd insights, and visualizes the future of Manila's transit expansion.

---

## 🌟 Key Features

### 🛤️ Unified Rail Dashboard
*   **LRT-1, LRT-2, MRT-3, and PNR:** Real-time visibility of all operating lines in one place.
*   **Station Details:** Access accessibility information (Elevators, Escalators), nearby landmarks, and platform side directions (Door opening side).

### 👥 Community-Driven Insights
*   **Live Crowd Density:** Know if a station is "Light," "Moderate," or "Heavy" before you even arrive.
*   **Social Pulse:** Report and view live community status updates directly from fellow commuters.
*   **Peak Hour Intelligence:** Data-driven charts suggesting the best times to travel.

### 💰 Savings & Advocacy
*   **Cost Comparison:** Compare taking the train vs. driving (including fuel and parking).
*   **Environmental Impact:** See your contribution to CO2 reduction by choosing public transit.
*   **Digital Trip Journal:** Keep track of your commutes and overall spending.

### 🗺️ Future Manila Rail Network
*   Explore the road ahead with interactive maps of the **MRT-7**, **Metro Manila Subway (MMS)**, and **North-South Commuter Railway (NSCR)**.

### 🔊 Accessibility & Convenience
*   **Dynamic Island Transit Tracker:** Real-time, system-wide floating overlay (LRT/MRT) inspired by iOS, providing speed, distance-to-next-station, and arrival notifications.
*   **Custom Voice Pack Announcements:** Bilingual (Tagalog/English) announcements with various personalities (Professional, Casual, Conyo).
*   **Walking Transfer Guides:** Step-by-step visual paths for seamless line interchanges.
*   **Speedometer:** Monitor live train speed and pace during your journey.

---

## 🛠️ Technical Stack

-   **Frontend:** [Flutter](https://flutter.dev/) (3.0+)
-   **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Auth, Cloud Functions)
-   **Mapping:** [flutter_map](https://pub.dev/packages/flutter_map) with OpenStreetMap, CartoDB, and ESRI World Imagery.
-   **Offline Caching:** Custom SQL-based storage for map tiles and alerts.
-   **Real-time Logic:** Background location services and reactive streams for crowd data.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A Firebase Project (for real-time features)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YourUsername/TaraTren.git
    cd TaraTren
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Setup Firebase:**
    - Register your app on [Firebase Console](https://console.firebase.google.com/).
    - Download `google-services.json` and place it in `android/app/`.
    - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🤝 Contributing
TaraTren is a community-first project! Whether it's reporting bugs, suggesting features, or helping with the codebase, all contributions are welcome.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).

---

## 🧑‍💻 Developed By
**Jhon Francis Garapan**
*Graduate IT Student | Parañaque City, Philippines*

---

*Safe travels, Metro Manila Commuter!*
