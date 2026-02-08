# **eRents**
Seminarski rad za predmet Razvoj Softvera II

**Student:** Kenan Ćosić | **Indeks:** IB160228

---

# Upute za pokretanje:

## 1. Priprema .env fajla
`.env` fajlovi su pohranjeni u password-protected zip arhivama iz sigurnosnih razloga.

**Ekstrakcija .env fajlova:**
1. **Root .env:** Otpakujte `d:\MIS\eRents\.env.zip`
2. **Desktop .env:** Otpakujte `d:\MIS\eRents\e_rents_desktop\lib\.env.zip`
3. **Mobile .env:** Otpakujte `d:\MIS\eRents\e_rents_mobile\lib\.env.zip`


Rezultat: `.env` fajlovi u odgovarajućim folderima sa konfiguracijom baze, RabbitMQ-a, SMTP-a i Stripe-a.

## 2. Pokretanje Backend-a (Docker)
```bash
docker-compose up --build
```
Sačekati da se svi servisi pokrenu, baza seeda i API postane dostupan na http://localhost:5000/swagger.

## 3. Pokretanje Desktop aplikacije:
1. Otpakovati ```fit-build-14-02-2026.zip``` u željeni folder
2. Otvoriti folder: ```fit-build-14-02-2026/Release/```
3. Pokrenuti ```e_rents_desktop.exe```
4. Ulogovati se sa kredencijalima ispod.

## 4. Pokretanje Mobile aplikacije:
1. Pokrenuti Android emulator (AVD) u Android Studio.
2. Otpakovati ```fit-build-14-02-2026.zip``` i pronaći ```app-release.apk```
3. Instalirati APK:
   ```bash
   adb install fit-build-14-02-2026/app-release.apk
   ```
   Ili prevući APK fajl direktno u emulator.
4. Ulogovati se sa kredencijalima ispod.

---

## Kredencijali:

**Stanodavac (Desktop)**\
  Korisničko ime: ```desktop```\
  Email: ```erentsbusiness@gmail.com```\
  Lozinka: ```Password123!```

**Stanar (Mobile)**\
  Korisničko ime: ```mobile```\
  Email: ```erentsbusinesstenant@gmail.com```\
  Lozinka: ```Password123!```

---

## Putanja do mjesta u aplikaciji gdje se koristi RECOMMENDER sistem:

1. Ulogovati se na mobilnu aplikaciju kredencijalima: username: „mobile" i password „Password123!";
2. Navigirati se do Početnog ekrana (Home).
3. Skrolati do sekcije **„Preporučeno za vas"** (Recommended for you).
4. Sistem preporuka koristi Matrix Factorization algoritam (ML.NET) baziran na historiji pregleda i ocjena korisnika.

**Dokumentacija:** `docs/recommender-dokumentacija.docx`

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

## Database Access (Local Testing)

**SQL Server Connection:**\
  Server: ```localhost,1433```\
  Username: ```sa```\
  Password: ```StrongPass123!```\
  Database: ```eRentsDB```

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
