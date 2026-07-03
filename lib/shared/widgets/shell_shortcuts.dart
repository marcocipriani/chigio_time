import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// F4 — scorciatoie da tastiera (desktop/web). Su mobile non c'è tastiera
/// fisica, quindi i binding restano inerti.
///
/// L'ordine di annidamento è vitale: [CallbackShortcuts] deve stare SOPRA il
/// [Focus] con autofocus, perché i KeyEvent risalgono dal nodo focalizzato
/// verso gli antenati. Con l'ordine invertito (Focus fuori, shortcuts dentro)
/// le scorciatoie ricevono eventi solo quando il focus è già dentro il
/// contenuto — da qui il vecchio bug "a volte non rispondono".
class ShellShortcuts extends StatelessWidget {
  final ValueChanged<int> onSwitchBranch;
  final VoidCallback onShowHelp;
  final Widget child;

  const ShellShortcuts({
    super.key,
    required this.onSwitchBranch,
    required this.onShowHelp,
    required this.child,
  });

  /// True quando l'utente sta scrivendo in un campo di testo: le scorciatoie
  /// a tasto singolo vanno ignorate (digitare "1" in un importo non deve
  /// cambiare scheda).
  static bool get isTyping {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  VoidCallback _guarded(VoidCallback action) => () {
    if (!isTyping) action();
  };

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1): _guarded(
          () => onSwitchBranch(0),
        ),
        const SingleActivator(LogicalKeyboardKey.digit2): _guarded(
          () => onSwitchBranch(1),
        ),
        const SingleActivator(LogicalKeyboardKey.digit3): _guarded(
          () => onSwitchBranch(2),
        ),
        const SingleActivator(LogicalKeyboardKey.digit4): _guarded(
          () => onSwitchBranch(3),
        ),
        const SingleActivator(LogicalKeyboardKey.digit5): _guarded(
          () => onSwitchBranch(4),
        ),
        // Cartellino (timbra)
        const SingleActivator(LogicalKeyboardKey.keyT): _guarded(
          () => onSwitchBranch(1),
        ),
        // Oggi / Home
        const SingleActivator(LogicalKeyboardKey.keyO): _guarded(
          () => onSwitchBranch(0),
        ),
        const SingleActivator(LogicalKeyboardKey.escape): _guarded(
          () => onSwitchBranch(0),
        ),
        const SingleActivator(LogicalKeyboardKey.slash, shift: true): _guarded(
          onShowHelp,
        ),
      },
      // L'autofocus DENTRO le shortcuts garantisce che, anche a focus "vergine"
      // (avvio app, nessun click), gli eventi partano da un discendente e
      // attraversino il nodo di CallbackShortcuts.
      child: Focus(autofocus: true, child: child),
    );
  }
}
