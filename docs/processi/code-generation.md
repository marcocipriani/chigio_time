# Code generation

Tutto il code-gen passa da **`build_runner`**. I generatori configurati
in `pubspec.yaml` (`dev_dependencies`):

| Generator | Cosa produce |
|---|---|
| `riverpod_generator` | i `*.g.dart` accanto ai file annotati con `@riverpod` |
| `drift_dev` | tabelle e DAO Drift (`app_database.g.dart`) |

> Freezed e json_serializable sono stati RIMOSSI (review 2026-07-05, B1):
> erano dichiarati ma mai usati. I modelli sono classi Dart manuali con
> `toMap`/`fromMap`. Se servissero davvero, ri-aggiungerli con una ADR.

## Comandi

```bash
# One-shot (CI, post-clone, post-pull)
dart run build_runner build --delete-conflicting-outputs

# Watch (sviluppo locale)
dart run build_runner watch --delete-conflicting-outputs
```

> `--delete-conflicting-outputs` accetta la sovrascrittura di file
> generati esistenti che entrerebbero in conflitto. E' la modalita'
> standard di lavoro nel progetto.

## File **da non modificare a mano**

Qualsiasi file con queste estensioni e' generato:

- `*.g.dart` (Riverpod, Drift)

In testa hanno tipicamente un commento di `build_runner`. Se Claude
Code li edita per errore, ri-eseguire `dart run build_runner build
--delete-conflicting-outputs` per rigenerarli.

## Pattern Riverpod consigliato

```dart
// foo_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'foo_repository.g.dart';

@riverpod
FooRepository fooRepository(Ref ref) =>
    FooRepository(ref.watch(httpClientProvider));

@riverpod
Stream<List<Foo>> fooStream(Ref ref) =>
    ref.watch(fooRepositoryProvider).watchAll();

@riverpod
class FooNotifier extends _$FooNotifier {
  @override
  FooState build() => const FooState.initial();

  void load() { /* ... */ }
}
```

Da `foo_repository.dart` `build_runner` produce `foo_repository.g.dart`
con i provider auto-generati (`fooRepositoryProvider`, `fooStreamProvider`,
`fooNotifierProvider`).

## Quando aggiungere un generator nuovo

Apri una **ADR** (vedi
[`../decisioni/0000-template.md`](../decisioni/0000-template.md)) che
spieghi:

- perche' il pattern attuale non basta;
- quale dipendenza si introduce e in `dev_dependencies` o `dependencies`;
- impatto sui tempi di build (`build_runner` puo' diventare lento se i
  generator si moltiplicano).
