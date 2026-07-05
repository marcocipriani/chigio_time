import 'package:flutter/material.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/home_widget_header.dart';

/// Widget Home "Tabella orari": entrata → uscita std / soglia 9h / 9h30+pranzo.
/// La variante è preselezionata in automatico dall'orario dell'utente per il
/// giorno corrente (`stdMinsForDate`, gestisce anche il misto 3+2); il
/// selettore permette comunque di cambiarla.
class OrariTableCard extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const OrariTableCard({super.key, required this.profileData});

  @override
  State<OrariTableCard> createState() => _OrariTableCardState();
}

class _OrariTableCardState extends State<OrariTableCard> {
  static const _modes = [
    (label: '6:12', shiftMins: 372),
    (label: '6:40', shiftMins: 400),
    (label: '7:36', shiftMins: 456),
  ];
  static const _limit = 21 * 60;

  int? _mode; // null finché non risolto dall'orario utente o toccato

  int get _autoMode {
    final profile = widget.profileData;
    if (profile == null) return _modes.length - 1;
    final std = AppConstants.stdMinsForDate(profile, DateTime.now());
    // Variante più vicina all'orario di oggi (weekend/0 → std pieno).
    var best = _modes.length - 1;
    var bestDelta = 1 << 20;
    for (var i = 0; i < _modes.length; i++) {
      final delta = (_modes[i].shiftMins - (std == 0 ? 456 : std)).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    return best;
  }

  List<(int entry, int stdExit, int? nine, int? nine30)> _rows(int shiftMins) {
    final out = <(int, int, int?, int?)>[];
    for (var e = 7 * 60 + 30; e + shiftMins <= _limit; e += 15) {
      final nine = e + 540;
      final nine30 = e + 570;
      out.add((
        e,
        e + shiftMins,
        nine <= _limit ? nine : null,
        nine30 <= _limit ? nine30 : null,
      ));
    }
    return out;
  }

  static String _t(int mins) =>
      '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
    final mode = _mode ?? _autoMode;
    final rows = _rows(_modes[mode].shiftMins);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeWidgetHeader(
            pose: ChigioQuotes.orologio,
            title: AppStrings.hoursTable,
            subtitle: AppStrings.hoursTableAutoHint(_modes[mode].label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_modes.length, (i) {
                final active = mode == i;
                return Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: AppTappable(
                    onTap: () => setState(() => _mode = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.blue600
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _modes[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : textSub,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Intestazioni colonne
          Row(
            children: [
              _Cell(AppStrings.entrata, textSub, isHeader: true),
              _Cell(
                AppStrings.expectedExitStdHeader,
                AppColors.blue600,
                isHeader: true,
              ),
              _Cell(
                AppStrings.nineHourThresholdHeader,
                AppColors.orange600,
                isHeader: true,
              ),
              _Cell(
                AppStrings.lunchExtraHeader,
                AppColors.green700,
                isHeader: true,
              ),
            ],
          ),
          const Divider(height: 10),

          // Righe (compatte, scrollabili nella card)
          SizedBox(
            height: 236,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final (entry, stdExit, nine, nine30) = rows[i];
                final rowBg = i.isEven
                    ? Colors.transparent
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02));
                return Container(
                  color: rowBg,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      _Cell(_t(entry), textMain, bold: true),
                      _Cell(_t(stdExit), AppColors.blue600),
                      _Cell(
                        nine != null ? _t(nine) : '—',
                        nine != null ? AppColors.orange600 : textSub,
                      ),
                      _Cell(
                        nine30 != null ? _t(nine30) : '—',
                        nine30 != null ? AppColors.green700 : textSub,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final Color color;
  final bool isHeader;
  final bool bold;

  const _Cell(
    this.text,
    this.color, {
    this.isHeader = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 9.5 : 12,
          fontWeight: isHeader || bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
