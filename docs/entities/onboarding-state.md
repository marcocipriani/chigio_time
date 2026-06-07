# Entita': `OnboardingState`

> Stato **transitorio** del flusso di onboarding multi-step. Vive solo
> in memoria durante la compilazione del profilo, viene poi materializzato
> in `UserProfile` su Firestore.

## Definizione

`lib/features/authentication/presentation/onboarding_provider.dart`

```dart
class OnboardingState {
  final int currentStep;
  final String name;
  final String administration;          // default "Presidenza del Consiglio dei Ministri"
  final String employmentType;          // 'Ruolo' | 'Comando' | ''
  final Duration standardDailyHours;    // default 7h 12m
  final Duration mealVoucherThreshold;  // default 6h 00m
  final int monthlyArt9Hours;           // default 0
  final int monthlyOvertimeHours;       // default 0
  final ThemeMode themePreference;      // default ThemeMode.system
  final String dipartimento;
  final String sede;
  final String sedeId;
  final String sedeAddress;
  final double? sedeLat;
  final double? sedeLng;
  final int monthlySliHours;
  final int monthlySboHours;
  final String gender;                  // 'M' | 'F' | 'A' | 'N'
}
```

Esposta tramite `Onboarding extends _$Onboarding` (Notifier code-gen).

## Regole di business codificate

| Trigger | Effetto |
|---|---|
| `setEmploymentType('Ruolo')` | `standardDailyHours = 7h 36m`, `mealVoucherThreshold = 6h 20m`, `monthlyArt9Hours = 8` |
| `setEmploymentType('Comando')` | `standardDailyHours = 7h 12m`, `mealVoucherThreshold = 6h 20m`, `monthlyArt9Hours = 17` |
| `addDailyMinutes(±n)` | clamp 0..1440 |
| `addMealMinutes(±n)` | clamp 0..1440 |
| `addArt9Hours(±n)` | non scende sotto 0 |
| `addOvertimeHours(±n)` | non scende sotto 0 |
| `setOfficeLocation(...)` | imposta dipartimento, sede, indirizzo e coordinate da elenco PCM |
| `setGender(g)` | salva il genere usato per le frasi di Chigio |
| `setMonthlySliHours(hours)` / `setMonthlySboHours(hours)` | aggiorna target personali SLI/SBO |

## Mappatura → `UserProfile` (a fine flow)

Effettuata da `ProfileRepository.saveOnboardingData(state)`:

| Campo onboarding | Campo Firestore |
|---|---|
| `name` | `name` |
| `administration` | `administration` |
| `employmentType` | `employmentType` |
| `standardDailyHours.inMinutes` | `standardDailyMins` |
| `mealVoucherThreshold.inMinutes` | `mealVoucherThresholdMins` |
| `monthlyArt9Hours` | `monthlyArt9Hours` |
| `monthlySliHours` | `monthlySliHours` |
| `monthlySboHours` | `monthlySboHours` |
| `monthlyOvertimeHours` | `monthlyOvertimeHours` |
| `dipartimento` | `dipartimento` |
| `sede` | `sede` |
| `sedeId` | `sedeId` |
| `sedeAddress` | `sedeAddress` |
| `sedeLat` | `sedeLat` |
| `sedeLng` | `sedeLng` |
| `gender` | `gender` |
| `themePreference.toString()` | `themePreference` |
| — | `hasCompletedOnboarding: true` |
| — | `updatedAt: serverTimestamp()` |

## Vincoli

- **Lifecycle:** lo stato vive finche' lo `ProviderScope` esiste; al
  cambio rotta non viene esplicitamente invalidato. Andra' resettato
  alla fine dell'onboarding (oggi non e' fatto: e' inerte perche' la
  schermata viene smontata, ma e' un'osservazione per il futuro).
- **Default amministrazione hard-coded:** *"Presidenza del Consiglio dei
  Ministri"*. Se l'app si aprira' ad altre PA, va parametrizzato.
- **Sedi PCM:** l'onboarding non usa piu' testo libero per la sede quando
  l'elenco e' disponibile; i dati arrivano da `pcmOfficeLocationsProvider`
  con fallback ai seed statici.

_Ultima revisione: 2026-06-07 — aggiunti sede PCM strutturata, genere Chigio e target SLI/SBO._
