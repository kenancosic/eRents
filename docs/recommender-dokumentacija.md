# Sistem Preporuke - Dokumentacija

**Predmet:** Razvoj softvera II  
**Student:** Kenan Ćosić  
**Datum:** Januar 2026

---

## 1. Uvod

Sistem preporuke u eRents aplikaciji koristi **Machine Learning** algoritam za personalizirane preporuke nekretnina korisnicima. Cilj sistema je predvidjeti koje nekretnine bi korisnik mogao preferirati na osnovu historijskih podataka o ocjenama i interakcijama.

---

## 2. Korišteni Algoritam

### Matrix Factorization (Matrična Faktorizacija)

Sistem koristi **Matrix Factorization** algoritam implementiran putem **ML.NET** biblioteke. Ovaj algoritam je jedan od najčešće korištenih pristupa u kolaborativnom filtriranju.

**Princip rada:**
- Kreira se matrica ocjena gdje redovi predstavljaju korisnike, a kolone nekretnine
- Algoritam faktorizira ovu matricu na dvije manje matrice (latentni faktori)
- Na osnovu faktora predviđa ocjene za neviđene kombinacije korisnik-nekretnina

**Konfiguracija:**
```csharp
var options = new MatrixFactorizationTrainer.Options
{
    MatrixColumnIndexColumnName = nameof(UserPropertyRating.UserId),
    MatrixRowIndexColumnName = nameof(UserPropertyRating.PropertyId),
    LabelColumnName = nameof(UserPropertyRating.Rating),
    NumberOfIterations = 100,
    ApproximationRank = 8
};
```

**Parametri:**
- `NumberOfIterations`: 100 iteracija za optimizaciju
- `ApproximationRank`: 8 latentnih faktora za reprezentaciju korisnika i nekretnina

---

## 3. Izvor Podataka

Sistem koristi **eksplicitne povratne informacije** iz recenzija korisnika:

| Izvor | Tip Podataka | Raspon Ocjena |
|-------|--------------|---------------|
| Reviews (Recenzije) | StarRating | 1-5 zvjezdica |

**SQL Upit za podatke:**
```sql
SELECT ReviewerId, PropertyId, StarRating
FROM Reviews
WHERE StarRating IS NOT NULL 
  AND ReviewerId IS NOT NULL 
  AND PropertyId IS NOT NULL
```

---

## 4. API Endpoint

### GET /api/Properties/me/recommendations

**Opis:** Vraća personalizirane preporuke nekretnina za ulogovanog korisnika.

**Autorizacija:** Potrebna (JWT Bearer token)

**Query Parametri:**
| Parametar | Tip | Default | Opis |
|-----------|-----|---------|------|
| count | int | 10 | Broj preporuka za vratiti |

**Response (200 OK):**
```json
[
  {
    "propertyId": 1,
    "propertyName": "Luksuzni stan u centru",
    "propertyDescription": "Moderno opremljen stan...",
    "price": 75.00,
    "currency": "EUR",
    "predictedRating": 4.52
  },
  ...
]
```

---

## 5. Implementacija

### Glavni Fajlovi

| Fajl | Opis |
|------|------|
| `PropertyRecommendationService.cs` | Glavna servisna klasa za ML model |
| `IPropertyRecommendationService.cs` | Interface definicija |
| `PropertyRecommendation.cs` | DTO model za preporuke |
| `PropertiesController.cs` | API endpoint implementacija |

### Klase i Metode

**PropertyRecommendationService:**
- `GetRecommendationsAsync(userId, count)` - Vraća top N preporuka za korisnika
- `GetPredictionAsync(userId, propertyId)` - Predviđa ocjenu za specifičnu kombinaciju
- `TrainModelAsync()` - Trenira ML model sa svim dostupnim podacima

**Model Klase:**
```csharp
public class UserPropertyRating
{
    public int UserId { get; set; }
    public int PropertyId { get; set; }
    public float Rating { get; set; }
}

public class RatingPrediction
{
    public float Score { get; set; }
}
```

---

## 6. Filtriranje Nekretnina

Prije predikcije, sistem filtrira nekretnine po dostupnosti:

1. **Status:** Samo nekretnine sa statusom `Available`
2. **Monthly Rentals:** Isključuje nekretnine sa aktivnim booking-ima
3. **Daily Rentals:** Uključuje sve dostupne (provjera dostupnosti po datumu)

---

## 7. Putanja do Preporuka u Aplikaciji

### Mobilna Aplikacija (Android):

1. Ulogovati se kredencijalima: `tenant` / `Password123!`
2. Navigirati do **Početnog ekrana** (Home tab)
3. Skrolati do sekcije **"Preporučeno za vas"** (Recommended for you)
4. Prikazane nekretnine su sortirane po predviđenoj ocjeni (najviša prva)

### Desktop Aplikacija (Windows):

1. Ulogovati se kao landlord
2. Preporuke se prikazuju na dashboard-u (ako je implementirano)

---

## 8. Dijagram Toka

```
┌─────────────────┐
│   Korisnik      │
│   (Request)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Controller    │
│ /recommendations│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Recommendation  │
│    Service      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐ ┌───────┐
│ Train │ │Predict│
│ Model │ │ Score │
└───────┘ └───────┘
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│   Sort & Top N  │
│   Preporuke     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Response     │
│  (JSON Array)   │
└─────────────────┘
```

---

## 9. Performanse i Optimizacija

### Caching
- Model se trenira jednom i čuva u statičkoj varijabli
- Ponovno treniranje se vrši samo kad je model `null`

### Thread Safety
- Koristi se `lock` objekt za sinkronizaciju pristupa modelu
- Osigurava sigurnost u multi-thread okruženju

### Ograničenja
- Prediction values su ograničene na raspon [-10, 10]
- Infinity/NaN vrijednosti se zamjenjuju sa 0

---

## 10. Tehnologije

| Komponenta | Tehnologija | Verzija |
|------------|-------------|---------|
| ML Framework | ML.NET | Latest |
| Algoritam | Matrix Factorization | - |
| Backend | ASP.NET Core | 8.0 |
| Database | SQL Server | 2022 |
| ORM | Entity Framework Core | 8.0 |

---

## 11. Buduća Poboljšanja

1. **Hybrid Filtering** - Kombinacija kolaborativnog i content-based filtriranja
2. **Real-time Training** - Automatsko re-treniranje pri novim recenzijama
3. **A/B Testing** - Testiranje različitih algoritama i parametara
4. **Cold Start Problem** - Bolje preporuke za nove korisnike

---

## 12. Reference

- [ML.NET Documentation](https://docs.microsoft.com/en-us/dotnet/machine-learning/)
- [Matrix Factorization Paper](https://datajobs.com/data-science-repo/Recommender-Systems-[Netflix].pdf)
- [Collaborative Filtering Techniques](https://en.wikipedia.org/wiki/Collaborative_filtering)

---

**Verzija dokumenta:** 1.0  
**Posljednje ažuriranje:** Januar 2026
