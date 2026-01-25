# **eRents**
Seminarski rad za predmet Razvoj Softvera II

**Student:** Kenan Ćosić | **Indeks:** IB160228

---

# Upute za pokretanje:

1. Pokrenuti komandu: ```docker-compose up --build``` u terminalu.
2. Pustiti da se izvrti docker compose koji će da nam builda, seeda bazu i pokrene API.
3. Exportovati ```fit-build-2026-01-25.zip``` (ako postoji) ili buildati aplikacije.
4. Nakon exporta imamo dva različita foldera, jedan za desktop **(Release)** drugi za mobile **(flutter-apk) APK**.

## Pokretanje Mobile:
1. Pokrenuti emulator (Android Virtual Device).
2. Prevući APK fajl iz foldera **flutter-apk** u emulator, sačekati da se instalira.
3. Ili instalirati putem: ```adb install app-release.apk```
4. Koristiti aplikaciju.

## Pokretanje Desktop:
1. Pokrenuti ```e_rents_desktop.exe``` fajl iz **Release** foldera.
2. Koristiti aplikaciju.

---

## Kredencijali:

**Stanodavac (Desktop)**\
  Korisničko ime: ```landlord```\
  Email: ```landlord@erent.com```\
  Lozinka: ```Password123!```

**Stanar (Mobile)**\
  Korisničko ime: ```tenant```\
  Email: ```tenant@erent.com```\
  Lozinka: ```Password123!```

---

## Putanja do mjesta u aplikaciji gdje se koristi RECOMMENDER sistem:

1. Ulogovati se na mobilnu aplikaciju kredencijalima: username: „tenant" i password „Password123!";
2. Navigirati se do Početnog ekrana (Home).
3. Skrolati do sekcije **„Preporučeno za vas"** (Recommended for you).
4. Sistem preporuka koristi Matrix Factorization algoritam (ML.NET) baziran na historiji pregleda i ocjena korisnika.

**Dokumentacija:** `docs/recommender-dokumentacija.md`

---

## RabbitMQ

RabbitMQ korišten za:
- Dopisivanje između stanara i stanodavca (chat messaging)
- Slanje e-mail notifikacija za booking potvrde
- Slanje notifikacija za nove recenzije
- Procesiranje refund zahtjeva
- Asinkrono procesiranje dugoročnih operacija

**RabbitMQ Management UI:** http://localhost:15672 (guest/guest)

---

## Stripe Plaćanje

U sklopu seminarskog rada za plaćanje korišten je Stripe. Za testiranje on nam osigurava testne podatke za unos kreditne kartice:

Broj kartice: ```4242 4242 4242 4242```\
CVC: ```Bilo koje 3 cifre```\
Datum isteka: ```Bilo koji u budućnosti```

Plaćanje je omogućeno prilikom kreiranja rezervacije (Daily rental).

---

## SignalR (Real-time)

SignalR korišten za:
- Real-time chat između stanara i stanodavaca
- Live notifikacije u aplikaciji
- Instant update statusa booking-a

---

## Build Release Verzija

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

## Servisi (Docker)

| Servis | Container | Port | Opis |
|--------|-----------|------|------|
| Main API | `erents-api` | 5000 | ASP.NET Core 8 Web API |
| RabbitMQ Microservice | `erents-microservice` | - | Message processor |
| RabbitMQ | `erents-rabbitmq` | 5672, 15672 | Message broker |
| SQL Server | `erents-db` | 1433 | Database |

**API Swagger:** http://localhost:5000/swagger

---

## Android Emulator Napomena

Kroz Android emulator koristi se `10.0.2.2` umjesto `localhost` za pristup API-ju.
Konfiguracija: `e_rents_mobile/lib/.env`

---

## Tehnologije

- **Backend:** .NET 8 Web API, Entity Framework Core, SQL Server
- **Message Broker:** RabbitMQ
- **Real-time:** SignalR
- **Frontend:** Flutter (Desktop Windows + Mobile Android)
- **ML:** ML.NET (sistem preporuka - Matrix Factorization)
- **Payments:** Stripe API
- **Containerization:** Docker, Docker Compose
