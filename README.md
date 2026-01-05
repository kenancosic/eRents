# eRents - Property Rental Management System

eRents is a comprehensive academic project designed to demonstrate a modern, microservice-based architecture for property rental management. It consists of a .NET 8 Web API backend, a RabbitMQ-based microservice for asynchronous processing, and cross-platform Flutter applications for Desktop and Mobile.

## 🏗️ Architecture

The system is built using a Clean Architecture approach with the following components:

- **Backend**: 
  - **eRents.WebApi**: Core REST API built with ASP.NET Core 8.
  - **eRents.RabbitMQMicroservice**: Background worker for handling async tasks (emails, notifications).
  - **SQL Server**: Relational database for persistent storage.
  - **RabbitMQ**: Message broker for service communication.

- **Frontend**:
  - **e_rents_mobile**: Flutter mobile application (Android/iOS) for Tenants.
  - **e_rents_desktop**: Flutter desktop application (Windows) for Landlords/Admin.

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
├── e_rents_mobile/              # Flutter Mobile App
├── e_rents_desktop/             # Flutter Desktop App
└── docs/                        # Detailed documentation
```
