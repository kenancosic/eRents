# eRents - Property Rental Management System

**Seminarski rad - Razvoj softvera II (RSII)**  
**Fakultet informacijskih tehnologija**  
**Student:** Kenan Ćosić  
**Akademska godina:** 2024/25

---

eRents is a comprehensive academic project designed to demonstrate a modern, microservice-based architecture for property rental management. It consists of a .NET 8 Web API backend, a RabbitMQ-based microservice for asynchronous processing, and cross-platform Flutter applications for Desktop and Mobile.

## 🏗️ Architecture

The system is built using a Clean Architecture approach with the following components:

- **Backend**: 
  - **eRents.WebApi**: Core REST API built with ASP.NET Core 8.
  - **eRents.RabbitMQMicroservice**: Background worker for handling async tasks (emails, notifications).
  - **SQL Server**: Relational database for persistent storage.
  - **RabbitMQ**: Message broker for service communication.

- **Frontend**:
  - **e_rents_mobile**: Flutter mobile application (Android) for Tenants.
  - **e_rents_desktop**: Flutter desktop application (Windows) for Landlords/Admin.

## 📋 Key Features

- **Property Management**: Full CRUD for rental properties with images, amenities, and pricing
- **Booking System**: Daily and monthly rental bookings with availability management
- **Review System**: Star ratings and text reviews with landlord responses
- **Chat/Messaging**: Real-time communication via SignalR
- **Payment Processing**: Stripe integration (currently disabled) + Manual payment workflow
- **Maintenance Requests**: Issue reporting and tracking for tenants
- **Recommender System**: ML.NET-based property recommendations (see `docs/recommender-dokumentacija.md`)
- **Notifications**: Push and in-app notifications via RabbitMQ

## 🚀 Getting Started with Docker

The easiest way to run the entire backend infrastructure is using Docker Compose.

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

### Running the Backend
1. Open a terminal in the project root directory.
2. Run the following command to build and start services:
   ```bash
   docker-compose up -d --build
   ```
3. Wait for the services to initialize. You can check the status with:
   ```bash
   docker-compose ps
   ```

### Accessing Services
- **Main API (Swagger)**: http://localhost:5000/swagger
- **RabbitMQ Management**: http://localhost:15672 (User: `guest`, Pass: `guest`)
- **SQL Server**: `localhost,1433` (User: `sa`, Pass: `StrongPass123!`)

### Stopping Services
To stop the containers:
```bash
docker-compose down
```

## 🛠️ Manual Development Setup

If you prefer to run services individually for development:

### Backend (.NET)
1. Ensure you have the .NET 8 SDK installed.
2. Navigate to the solution root.
3. Run the API:
   ```bash
   dotnet run --project eRents.WebApi
   ```

### Mobile App (Flutter)
1. Navigate to `e_rents_mobile`.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Desktop App (Flutter)
1. Navigate to `e_rents_desktop`.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run -d windows
   ```

## 🔑 Test Credentials

The database is seeded with test users:

| Role | Email | Password |
|------|-------|----------|
| Landlord | landlord@erent.com | Password123! |
| Tenant | tenant@erent.com | Password123! |

## 📱 Building for Release

### Mobile APK (Android)

```bash
# Option 1: Use the build script
.\build-mobile.bat

# Option 2: Manual build
cd e_rents_mobile
flutter clean
flutter pub get
flutter build apk --release
```
**Output:** `e_rents_mobile/build/app/outputs/flutter-apk/app-release.apk`

### Desktop Executable (Windows)

```bash
# Option 1: Use the build script
.\build-desktop.bat

# Option 2: Manual build
cd e_rents_desktop
flutter clean
flutter pub get
flutter build windows --release
```
**Output:** `e_rents_desktop/build/windows/x64/runner/Release/`

## 🔧 API Configuration

| Platform | Base URL | Config File |
|----------|----------|-------------|
| Android Emulator (AVD) | `http://10.0.2.2:5000/api` | `e_rents_mobile/lib/config.dart` |
| Windows Desktop | `http://localhost:5000/api` | `e_rents_desktop/lib/.env` |

## 🤖 Recommender System

The application includes an ML.NET-based property recommendation system:
- **Algorithm**: Matrix Factorization (Collaborative Filtering)
- **Endpoint**: `GET /api/Properties/me/recommendations`
- **Documentation**: `docs/recommender-dokumentacija.md`

## 📂 Project Structure

```
eRents/
├── docker-compose.yml           # Docker orchestration
├── eRents.sln                   # Visual Studio Solution
├── eRents.Domain/               # Domain entities and EF Core definitions
├── eRents.Features/             # Business logic (Controllers, Services)
├── eRents.Shared/               # Shared DTOs and utilities
├── eRents.WebApi/               # Main API entry point
├── eRents.RabbitMQMicroservice/ # Background worker service
├── e_rents_mobile/              # Flutter Mobile App (Tenants)
├── e_rents_desktop/             # Flutter Desktop App (Landlords)
├── build-mobile.bat             # Mobile build script
└── build-desktop.bat            # Desktop build script
```

## 📚 Additional Documentation

- **Recommender System**: `docs/recommender-dokumentacija.md`
- **Compliance Checklist**: `COMPLIANCE_CHECKLIST.md`
- **Stripe Integration**: `docs/stripe/STRIPE_INTEGRATION_DISABLED.md`
- **Business Logic**: `docs/business_logic.md`

## ⚠️ Notes

- **Payment System**: Stripe is currently disabled. Manual payment workflow is active.
- **SSL**: HTTP is used (no HTTPS) per academic project requirements.
- **Database**: Auto-seeded on first run with sample data.
