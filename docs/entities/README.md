# Modello di dominio (entita')

Questo capitolo raccoglie il **modello concettuale** delle entita' di
`chigio_time` e la loro **mappatura logica → fisica** (Firestore + Drift).

Una scheda per entita' descrive: campi, semantica, regole di validazione,
collocazione nel codice, mappatura sul backend.

## Diagramma ER concettuale

```mermaid
erDiagram
    USER ||--|| USER_PROFILE : "ha 1"
    USER ||--o{ DAILY_TIMESHEET : "produce 0..N"
    USER ||--o{ TIMESHEET_ENTRY : "(legacy) timbrature singole"
    USER_PROFILE ||--|| ONBOARDING_STATE : "alimentato da"
    DAILY_TIMESHEET }o..|| TIMER_STATE : "consolidato da"

    USER {
        string uid PK
        string email
        string displayName
    }
    USER_PROFILE {
        string name
        string administration
        string employmentType
        int standardDailyMins
        int mealVoucherThresholdMins
        int monthlyArt9Hours
        int monthlyOvertimeHours
        int monthlySliHours
        int monthlySboHours
        list summaryItems
        bool summaryShowProgress
        bool notifyClockIn
        bool notifyClockOut
        bool notifyWeekly
        string themePreference
        bool hasCompletedOnboarding
        timestamp updatedAt
    }
    ONBOARDING_STATE {
        int currentStep
        Duration standardDailyHours
        Duration mealVoucherThreshold
        ThemeMode themePreference
    }
    DAILY_TIMESHEET {
        string dateId PK "YYYY-MM-DD"
        DateTime startTime
        DateTime endTime
        int standardPauseMins
        int leavePauseMins "Art.9"
        int lunchPauseMins
        int netWorkedMins
        int extraMins "neg=OP ore perse"
        int sliMins
        int sboMins
        string workType
    }
    TIMESHEET_ENTRY {
        string id PK
        string userId FK
        DateTime startTime
        DateTime endTime
        bool isSmartWorking
    }
    TIMER_STATE {
        WorkState status
        DateTime startTime
        DateTime currentPauseStart
        PauseType currentPauseType
        int totalStandardPauseMins
        int totalLunchPauseMins
    }
```

## Mappatura logico → fisico

| Entita' concettuale | Sorgente in `lib/` | Storage canonico | Storage locale |
|---|---|---|---|
| **User** | `firebase_auth` (provider `firebaseAuthProvider`) | Firebase Auth | — |
| **UserProfile** | `lib/features/profile/data/profile_repository.dart` | Firestore: `users/{uid}` | (futuro) Drift |
| **OnboardingState** | `lib/features/authentication/presentation/onboarding_provider.dart` | in-memory (Riverpod Notifier) | persistito in `UserProfile` a fine flow |
| **DailyTimesheet** | `lib/features/timesheet/domain/daily_timesheet.dart` | Firestore: `users/{uid}/timesheets/{dateId}` | (futuro) Drift |
| **TimesheetEntry** *(legacy)* | `lib/shared/models/timesheet_entry.dart` | Firestore (non usato attivamente) | — |
| **TimerState** | `lib/features/dashboard/presentation/timer_provider.dart` | in-memory | (futuro) salvataggio su Drift per resilienza |

## Schede di dettaglio

- [`user-profile.md`](./user-profile.md)
- [`onboarding-state.md`](./onboarding-state.md)
- [`daily-timesheet.md`](./daily-timesheet.md)
- [`timesheet-entry.md`](./timesheet-entry.md)
- [`timer-state.md`](./timer-state.md)
