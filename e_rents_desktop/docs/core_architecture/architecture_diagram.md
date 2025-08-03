# eRents Desktop Application Architecture Diagram

## Overview

This document provides a textual representation of the eRents desktop application architecture diagram, showing the relationships between all major components and layers of the system.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Presentation Layer                            │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Screens       │  │    Widgets      │  │        Themes               │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │ │
│  │ │ListScreen   │ │  │ │CRUD Templates│ │  │ │Material 3 Design System │ │ │
│  │ │FormScreen   │ │  │ │Common Widgets│ │  │ │Color Palette            │ │ │
│  │ │DetailScreen │ │  │ │Custom Widgets│ │  │ │Text Styles              │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ │Widget Themes            │ │ │
│  │                 │  │                 │  │ │Gradients                │ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ └─────────────────────────┘ │ │
│  │ │Feature      │ │  │ │Desktop      │ │  │                             │ │
│  │ │Screens      │ │  │ │DataTable    │ │  │                             │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │                             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Business Logic Layer                             │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Providers     │  │   Services      │  │        Utilities            │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │ │
│  │ │BaseProvider │ │  │ │ApiService   │ │  │ │AppDateUtils             │ │ │
│  │ │(Mixin+Cache)│ │  │ │ImageService │ │  │ │kCurrencyFormat          │ │ │
│  │ └─────────────┘ │  │ │LookupService│ │  │ │Logger                   │ │ │
│  │                 │  │ │SecureStorage│ │  │ │Constants                │ │ │
│  │ ┌─────────────┐ │  │ │UserPrefs    │ │  │ └─────────────────────────┘ │ │
│  │ │Feature      │ │  │ └─────────────┘ │  │                             │ │
│  │ │Providers    │ │  │                 │  │                             │ │
│  │ └─────────────┘ │  │                 │  │                             │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │                             │ │
│  │ │Global State │ │  │ │Extensions   │ │  │                             │ │
│  │ │Providers    │ │  │ │             │ │  │                             │ │
│  │ │(Navigation, │ │  │ │             │ │  │                             │ │
│  │ │Preferences, │ │  │ │             │ │  │                             │ │
│  │ │Error)       │ │  │ │             │ │  │                             │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │                             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Data Layer                                    │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │    Models       │  │   Routing       │  │        Configuration        │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │ │
│  │ │Property     │ │  │ │GoRouter     │ │  │ │Environment (.env)       │ │ │
│  │ │User         │ │  │ │AppRouter    │ │  │ │Dependency Injection     │ │ │
│  │ │Address      │ │  │ │             │ │  │ │                         │ │ │
│  │ │Booking      │ │  │ │             │ │  │ │                         │ │ │
│  │ │LookupData   │ │  │ │             │ │  │ │                         │ │ │
│  │ │Enums        │ │  │ │             │ │  │ │                         │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────────────────┘ │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │                             │ │
│  │ │JSON         │ │  │ │Guards       │ │  │                             │ │
│  │ │Parsing      │ │  │ │Redirects    │ │  │                             │ │
│  │ │Validation   │ │  │ │Providers    │ │  │                             │ │
│  │ └─────────────┘ │  │ │Injection    │ │  │                             │ │
│  └─────────────────┘  │ └─────────────┘ │  │                             │ │
│                       └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           External Systems                                 │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │   Backend API   │  │   Storage       │  │        Services             │ │
│  │                 │  │                 │  │                             │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │ │
│  │ │.NET Core    │ │  │ │Secure       │ │  │ │Authentication           │ │ │
│  │ │REST API     │ │  │ │Storage      │ │  │ │                         │ │ │
│  │ │SignalR      │ │  │ │             │ │  │ │                         │ │ │
│  │ └─────────────┘ │  │ │             │ │  │ │                         │ │ │
│  │                 │  │ └─────────────┘ │  │ └─────────────────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Relationships

### 1. Presentation Layer Dependencies

```
Screens ────────────┐
                    ├──► Providers ◄──┐
Widgets ────────────┘                 │
                                      │
Themes ───────────────────────────────┘
```

### 2. Business Logic Layer Dependencies

```
Providers ───► Services ───┐
                           ├──► Models
Utilities ─────────────────┘

Providers ───► Extensions

Global Providers ───► Feature Providers
```

### 3. Data Flow

```
User Action
    │
    ▼
Screen/Widget
    │
    ▼
Provider (State Management)
    │
    ▼
Service (API/Data Operations)
    │
    ▼
Model (Data Parsing/Validation)
    │
    ▼
External API/Storage
    │
    ▼
Response Processing
    │
    ▼
Provider State Update
    │
    ▼
UI Re-render
```

## Key Integration Points

### 1. Dependency Injection Flow

```
main.dart
    │
    ▼
MultiProvider Registration
    │
    ▼
Service Creation (with dependencies)
    │
    ▼
Provider Creation (with service dependencies)
    │
    ▼
AppWithRouter (Routing with provider access)
```

### 2. Routing Integration

```
GoRouter Configuration
    │
    ▼
Shell Layout (AppShell)
    │
    ▼
Route Guards (Authentication)
    │
    ▼
Provider Injection per Route
    │
    ▼
Screen Rendering
```

### 3. Error Handling Flow

```
Error Occurrence
    │
    ▼
Provider Error State
    │
    ▼
AppError Creation
    │
    ▼
AppErrorProvider Global State
    │
    ▼
GlobalErrorDialog Display
```


## Feature Module Structure

```
features/
├── auth/
│   ├── providers/ ───► AuthProvider (extends BaseProvider)
│   ├── screens/ ──────► LoginScreen, RegisterScreen
│   └── widgets/ ──────► AuthForm, AuthCard
│
├── properties/
│   ├── providers/ ───► PropertyProvider, PropertyFormProvider
│   ├── screens/ ──────► PropertyListScreen, PropertyFormScreen
│   ├── widgets/ ──────► PropertyCard, PropertyFilter
│   └── models/ ───────► Property-specific models
│
├── chat/
│   ├── providers/ ───► ChatProvider
│   ├── screens/ ──────► ChatScreen
│   └── widgets/ ──────► MessageBubble, ChatInput
│
└── ... (other features)
```

## Base Provider Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    BaseProvider                             │
│                                                             │
│  ┌─────────────────┐                                    │
│  │BaseProviderMixin│                                    │
│  │                 │                                    │
│  │─ isLoading      │                                    │
│  │─ error          │                                    │
│  │─ hasError       │                                    │
│  │                 │                                    │
│  │─ executeWithState│                                    │
│  │─ ...            │                                    │
│  └─────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 ApiServiceExtensions                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │─ getListAndDecode<T>                                    │ │
│  │─ getAndDecode<T>                                        │ │
│  │─ postAndDecode<T>                                       │ │
│  │─ putAndDecode<T>                                        │ │
│  │─ deleteAndDecode<T>                                     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Error Flow                             │
│                                                             │
│  Service Exception                                          │
│        │                                                    │
│        ▼                                                    │
│  ApiService.handleResponse                                  │
│        │                                                    │
│        ▼                                                    │
│  AppError.fromException                                     │
│        │                                                    │
│        ▼                                                    │
│  Provider.setError                                          │
│        │                                                    │
│        ▼                                                    │
│  AppErrorProvider.addError                                  │
│        │                                                    │
│        ▼                                                    │
│  GlobalErrorDialog.listen                                   │
└─────────────────────────────────────────────────────────────┘
```

## Lookup Data Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  LookupService  │───►│  LookupProvider │───►│   Providers     │
│                 │    │                 │    │                 │
│ fetchLookupData │    │ initializeData  │    │ consumeLookup   │
│ cacheLookupData │    │ cacheManagement │    │                 │
│ syncWithBackend │    │ enumMapping     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backend API   │    │   Cache Layer   │    │   UI Widgets    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Image Management Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  ImageService   │───►│   Providers     │───►│   UI Widgets    │
│                 │    │                 │    │                 │
│ uploadImage     │    │ manageImages    │    │ displayImage    │
│ retrieveImage   │    │ setCoverImage   │    │ imageGallery    │
│ deleteImage     │    │                 │    │                 │
│ generateThumb   │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   File Storage  │    │   Cache Layer   │    │   Image Display │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Security Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SecureStorage   │◄───│   Services      │◄───│   Providers     │
│ Service         │    │                 │    │                 │
│                 │    │ ApiService      │    │ AuthProvider    │
│ storeToken      │    │ addAuthHeader   │    │ login           │
│ retrieveToken   │    │ handleAuthError │    │ logout          │
│ deleteToken     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Token Storage │    │   HTTP Client   │    │   Auth State    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Testing Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Unit Tests    │    │ Integration     │    │   Widget        │
│                 │    │ Tests           │    │ Tests           │
│ Provider Tests  │    │ Service Tests   │    │ UI Tests        │
│ Model Tests     │    │ API Tests       │    │ Screen Tests    │
│ Utility Tests   │    │                 │    │ Widget Tests    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Mock Framework                           │
│                                                             │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │   Mock Services │         │    Test Utilities       │   │
│  │                 │         │                         │   │
│  │ MockApiService  │         │ Test Data Generators    │   │
│  │ MockStorage     │         │ Test Helpers            │   │
│  │                 │         │                         │   │
│  └─────────────────┘         └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Performance Monitoring

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Logging       │    │   Caching       │    │   Loading       │
│                 │    │                 │    │                 │
│ Logger          │    │ Cache Stats     │    │ Loading States  │
│ Performance     │    │ Cache Hits/Miss │    │ Progress Ind.   │
│ Debug Info      │    │ TTL Management  │    │ Skeleton UI     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 Performance Dashboard                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    Metrics                              │ │
│  │                                                         │ │
│  │ ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐  │ │
│  │ │ API Response│  │ Cache       │  │ UI Render        │  │ │
│  │ │ Times       │  │ Performance │  │ Performance      │  │ │
│  │ │             │  │             │  │                  │  │ │
│  │ └─────────────┘  └─────────────┘  └──────────────────┘  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

This architecture diagram documentation provides a comprehensive visual and textual representation of the eRents desktop application structure, showing how all components interact and depend on each other. This serves as a valuable reference for understanding the system's design and for onboarding new developers.
