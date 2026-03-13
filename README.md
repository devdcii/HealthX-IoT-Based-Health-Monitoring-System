# HealthX
### IoT-Based Health Monitoring System

> Real-time vital sign tracking for healthcare workers and patients — powered by Flutter and a PHP/MySQL backend.

---

## Overview

HealthX is a cross-platform mobile application paired with a PHP REST API backend that enables healthcare professionals to monitor and record patient vital signs in real time. The system collects heart rate, SpO2, temperature, blood pressure, weight, height, and BMI — and stores everything securely for historical review.

---

## Features

- **Dual-role authentication** — separate dashboards for Health Workers and Regular Users
- **Real-time monitoring** — live sensor data with automatic refresh
- **Patient management** — add, view, and manage patient records and reading history
- **Offline support** — local data persistence via Hive (syncs when back online)
- **Health readings** — save, update, and delete measurement records
- **BMI calculation** — automatically computed from weight and height inputs
- **Profile management** — editable user profiles with session persistence

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter 3.x (Dart) |
| Local Storage | Hive 2.x |
| Backend API | PHP 7.4+ |
| Database | MySQL 5.7+ |
| Web Server | Apache / Nginx |
| Data Format | JSON / REST |

---

## Hardware

### Components

| Component | Model | Purpose |
|---|---|---|
| Microcontroller | ESP32 | WiFi-enabled main controller |
| Heart Rate & SpO2 | MAX30102 | Measures heart rate and blood oxygen |
| Temperature | MLX90614 | Non-contact body temperature sensor |
| Blood Pressure | Pressure Sensor | Systolic / diastolic measurement |
| Weight | HX711 + Load Cell | Weight measurement with tare/calibration |
| Height | TOF400C-VL53L1X | Ultrasonic distance sensor for height |

### ESP32 HTTP API

Base URL: `http://YOUR_ESP32_IP`

| Endpoint | Method | Returns |
|---|---|---|
| `/health` | GET | All sensor data (composite) |
| `/status` | GET | Device status |
| `/weight` | GET | Current weight reading |
| `/height` | GET | Current height reading |
| `/heartrate` | GET | Heart rate data |
| `/spo2` | GET | Blood oxygen level |
| `/temperature` | GET | Body temperature |
| `/bloodpressure` | GET | Systolic / diastolic values |
| `/tare` | POST | Zero/tare the weight scale |
| `/bp/start` | POST | Trigger blood pressure measurement |
| `/config` | POST | Update weight calibration factor |

### ESP32 Setup

1. Install Arduino IDE with ESP32 board support
2. Connect sensors to the ESP32 according to your pin configuration
3. Upload the firmware to the ESP32
4. Set your WiFi credentials in the firmware code
5. Update `esp32Url` in `lib/api_config.dart` with the ESP32's IP address
6. Verify sensor readings via the serial monitor
7. Test that all HTTP endpoints are accessible

### Connection Monitoring

The app runs an `Esp32ConnectionService` singleton in the background that pings the `/health` endpoint every 3 seconds. All screens reactively update a connection status indicator so health workers always know whether the device is online.

---

## Project Structure

```
project/
├── assets/
│   ├── images/              # App images and logo
│   └── icon/                # App icon
│
└── lib/
    ├── models/
    │   └── health_reading.dart        # Health reading model + Hive adapter
    │
    ├── api_config.dart                # API endpoint configuration
    ├── api_service.dart               # HTTP service layer
    ├── esp32_connection_service.dart  # Device connection monitor
    │
    ├── main.dart
    ├── onboarding.dart
    ├── login.dart
    ├── signup.dart
    │
    ├── healthworker_dashboard.dart
    ├── user_dashboard.dart
    ├── monitor_screen.dart
    ├── parameter_measurement_screen.dart
    ├── patient_monitoring_screen.dart
    ├── patients_screen.dart
    ├── settings_screen.dart
    └── user_settings_screen.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio or VS Code with Flutter extensions
- PHP 7.4+ and MySQL 5.7+
- Apache or Nginx web server
- ESP32 development board with sensors (see Hardware section)

### Installation

**1. Clone and install dependencies**
```bash
git clone https://github.com/your-username/healthx.git
cd healthx
flutter pub get
```

**2. Generate Hive adapters**
```bash
flutter packages pub run build_runner build
```

**3. Configure API endpoints**

Open `lib/api_config.dart` and update the URLs:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP/healthx/api';
static const String esp32Url = 'http://YOUR_ESP32_IP';
```

**4. Set up the backend**

- Create a MySQL database named `healthx`
- Import the database schema (users, patients, readings tables)
- Place the PHP API files in your web server directory (e.g., `/var/www/html/healthx/api`)
- Update the database credentials in your PHP config files

**5. Run the app**
```bash
flutter run
```

---

## Backend API Reference

Base URL: `http://YOUR_SERVER_IP/healthx/api`

| Endpoint | Method | Description |
|---|---|---|
| `/auth.php` | POST | Login / Register |
| `/get_patients.php` | GET | List all patients |
| `/get_readings.php` | GET | Fetch readings by user email |
| `/save_reading.php` | POST | Save a new reading |
| `/update_reading.php` | POST | Update an existing reading |
| `/delete_reading.php` | POST | Delete a reading |
| `/delete_patient.php` | POST | Remove a patient |
| `/update_profile.php` | POST | Update user profile |

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  http: ^0.13.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.0
  build_runner: ^2.3.3
```

---

## Color Palette

| Token | Hex | Usage |
|---|---|---|
| Primary | `#1848A0` | Buttons, headers |
| Success | `#10B981` | Confirmations |
| Error | `#EF4444` | Alerts, errors |
| Background | `#F8FAFC` | App background |
| Text Dark | `#1E293B` | Primary text |
| Text Light | `#64748B` | Secondary text |

---

## Roadmap

- [ ] Data visualization with charts
- [ ] Health alerts and push notifications
- [ ] PDF / CSV export
- [ ] Dark mode
- [ ] Biometric authentication
- [ ] OAuth 2.0 + data encryption
- [ ] WebSocket real-time updates
- [ ] AI-powered health insights
