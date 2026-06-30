import 'package:flutter/material.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/color_schemes.dart';

/// Accessible, cross-platform tap target — the canonical replacement for a
/// bare [GestureDetector] on interactive cards, chips, FABs and icon buttons.
///
/// Why it exists (true-parity + WCAG AA):
/// - **Semantics**: announces as a button (`enabled`/`disabled`) and exposes
///   [semanticLabel] for icon-only controls VoiceOver/TalkBack would otherwise
///   read as nothing. For controls with visible text, leave [semanticLabel]
///   null and the child's text is announced.
/// - **Keyboard** (desktop/web): focusable in tab order; Enter/Space fire
///   [onTap] via [ActivateIntent].
/// - **Pointer** (desktop/web): shows the click cursor on hover.
/// - **Touch**: subtle press scale, collapsed to instant under reduced motion.
class AppTappable extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  /// Spoken label. Required for icon-only controls; omit when the child
  /// already renders descriptive text.
  final String? semanticLabel;

  final double pressedScale;

  /// Corner radius for the keyboard focus ring (match the child's shape).
  final BorderRadius borderRadius;

  final HitTestBehavior behavior;

  const AppTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.semanticLabel,
    this.pressedScale = 0.96,
    this.borderRadius = BorderRadius.zero,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AppTappable> createState() => _AppTappableState();
}

class _AppTappableState extends State<AppTappable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool v) {
    if (mounted && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    Widget child = AnimatedScale(
      scale: _pressed && enabled ? widget.pressedScale : 1.0,
      duration: context.motion(110),
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (_focused) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(color: AppColors.blue400, width: 2),
        ),
        child: child,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : MouseCursor.defer,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          behavior: widget.behavior,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: child,
        ),
      ),
    );
  }
}
