import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Stato d'errore standard: messaggio umano + bottone Riprova.
/// Da usare nei rami `error:` di AsyncValue.when al posto del testo nudo.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppStrings.errorGeneric(error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}

/// Skeleton "ghost card" per gli stati di caricamento: sagoma glass che
/// pulsa. Sostituisce lo spinner centrato (niente layout shift al load).
class SkeletonTile extends StatefulWidget {
  final double height;
  final double radius;

  const SkeletonTile({super.key, this.height = 72, this.radius = 20});

  @override
  State<SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF002878).withValues(alpha: 0.06);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1.0).animate(_pulse),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Colonna di [count] skeleton distanziati — il placeholder tipico di una
/// lista di card in caricamento.
class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  final double gap;

  const SkeletonList({
    super.key,
    this.count = 3,
    this.height = 72,
    this.gap = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: gap),
          SkeletonTile(height: height),
        ],
      ],
    );
  }
}
