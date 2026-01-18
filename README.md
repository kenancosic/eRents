# eRents

**Seminarski rad - Razvoj softvera II (RSII)**  
**Student:** Kenan Ćosić | **Indeks:** IB160228

Platforma za upravljanje iznajmljivanjem nekretnina - povezuje stanodavce i stanare putem desktop (Windows) i mobilne (Android) aplikacije.

---

## Pokretanje projekta

### 1. Backend (Docker)

```bash
cd eRents
docker-compose up -d --build
```

**Servisi:**
- API (Swagger): http://localhost:5000/swagger
- RabbitMQ: http://localhost:15672 (guest/guest)

### 2. Desktop aplikacija (Windows)

```bash
cd e_rents_desktop
flutter pub get
flutter run -d windows
```

### 3. Mobilna aplikacija (Android)

```bash
cd e_rents_mobile
flutter pub get
flutter run
```

---

## Test kredencijali

**Desktop (Stanodavac):**
```
Username: landlord
Email: erentsbusiness@gmail.com
Password: Password123!
```

**Mobile (Stanar):**
```
Username: tenant
Email: erentsbusinesstenant@gmail.com
Password: Password123!
```

> **Napomena:** Za testiranje koristite username ili email za prijavu.

---

## Build release verzija

**Mobile APK:**
```bash
.\build-mobile.bat
# Output: e_rents_mobile/build/app/outputs/flutter-apk/app-release.apk
```

**Desktop EXE:**
```bash
.\build-desktop.bat
# Output: e_rents_desktop/build/windows/x64/runner/Release/
```

---

## Android Emulator napomena

Kroz Android emulator koristi se `10.0.2.2` umjesto `localhost` za pristup API-ju.
Konfiguracija: `e_rents_mobile/lib/.env`

---

## Tehnologije

- **Backend:** .NET 8 Web API, SQL Server, RabbitMQ, SignalR
- **Frontend:** Flutter (Desktop + Mobile)
- **ML:** ML.NET (sistem preporuka - Matrix Factorization)
