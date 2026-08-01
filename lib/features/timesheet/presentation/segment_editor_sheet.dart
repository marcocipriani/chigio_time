import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../domain/absence_consumption.dart';
import '../domain/absence_kind.dart';
import '../domain/day_segment.dart';

/// Editor di un singolo segmento della giornata (ADR-0018).
/// Restituisce il segmento costruito, `null` se l'utente annulla.
///
/// [day] fornisce la data su cui appoggiare gli orari scelti: il segmento
/// vive dentro una giornata, non ha una data propria. Qui non c'e' il
/// selettore ore/giornata: la giornata convenzionale e' una proprieta' della
/// giornata intera, non di un suo segmento.
Future<DaySegment?> showSegmentEditor(
  BuildContext context, {
  DaySegment? initial,
  required DateTime day,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<DaySegment>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _SegmentEditorSheet(initial: initial, day: day, isDark: isDark),
  );
}

class _SegmentEditorSheet extends StatefulWidget {
  final DaySegment? initial;
  final DateTime day;
  final bool isDark;

  const _SegmentEditorSheet({
    required this.initial,
    required this.day,
    required this.isDark,
  });

  @override
  State<_SegmentEditorSheet> createState() => _SegmentEditorSheetState();
}

class _SegmentEditorSheetState extends State<_SegmentEditorSheet> {
  static const _types = [
    DaySegment.work,
    DaySegment.leave,
    DaySegment.lunch,
    DaySegment.pause,
    DaySegment.bancaOre,
  ];

  late String _type;
  TimeOfDay? _from;
  TimeOfDay? _to;
  String? _kind;
  late TextEditingController _minsCtrl;
  String? _error;

  bool get _unpositioned => _from == null && _to == null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _type = s?.type ?? DaySegment.work;
    _from = s?.start == null ? null : TimeOfDay.fromDateTime(s!.start!);
    _to = s?.end == null ? null : TimeOfDay.fromDateTime(s!.end!);
    _kind = s?.absenceKind;
    _minsCtrl = TextEditingController(
      text: (s != null && s.start == null && s.mins > 0) ? '${s.mins}' : '',
    );
  }

  @override
  void dispose() {
    _minsCtrl.dispose();
    super.dispose();
  }

  /// Causali compatibili con un segmento orario: quelle a plafond in ore.
  /// La causale gia' impostata resta selezionabile anche se non oraria, per
  /// non perderla riaprendo un segmento importato.
  Map<String, List<String>> get _kindGroups => <String, List<String>>{
    for (final g in AbsenceKind.groups.entries)
      g.key: g.value
          .where((k) => k == _kind || AbsencePlafonds.isHourlyLeave(k))
          .toList(),
  }..removeWhere((_, kinds) => kinds.isEmpty);

  DateTime _on(TimeOfDay t) => DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
    t.hour,
    t.minute,
  );

  Future<void> _pick(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isFrom ? _from : _to) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
      _error = null;
    });
  }

  void _submit() {
    if ((_from == null) != (_to == null)) {
      setState(() => _error = AppStrings.segmentoOrariIncompleti);
      return;
    }
    final mins = int.tryParse(_minsCtrl.text.trim()) ?? 0;
    if (_unpositioned && mins <= 0) {
      setState(() => _error = AppStrings.segmentoDurataMancante);
      return;
    }
    if (!_unpositioned && !_on(_to!).isAfter(_on(_from!))) {
      setState(() => _error = AppStrings.segmentoFinePrimaDiInizio);
      return;
    }
    Navigator.of(context).pop(
      DaySegment(
        type: _type,
        start: _from == null ? null : _on(_from!),
        end: _to == null ? null : _on(_to!),
        mins: _unpositioned ? mins : 0,
        absenceKind: _type == DaySegment.leave ? _kind : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.neutral600;
    final accent = isDark ? AppColors.blue300 : AppColors.blue600;

    final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardH),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + (keyboardH == 0 ? safeBottom : 0),
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F1028).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.initial == null
                    ? AppStrings.nuovoSegmento
                    : AppStrings.modificaSegmento,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                AppStrings.segmentoTipo,
                style: TextStyle(fontSize: 13, color: textSub),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types
                    .map(
                      (t) => _Chip(
                        label: DaySegment.labelFor(t),
                        selected: _type == t,
                        accent: accent,
                        textSub: textSub,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _type = t;
                          if (t != DaySegment.leave) _kind = null;
                        }),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: AppStrings.segmentoDalle,
                      value: _from,
                      accent: accent,
                      textSub: textSub,
                      isDark: isDark,
                      onTap: () => _pick(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeField(
                      label: AppStrings.segmentoAlle,
                      value: _to,
                      accent: accent,
                      textSub: textSub,
                      isDark: isDark,
                      onTap: () => _pick(false),
                    ),
                  ),
                  if (!_unpositioned)
                    AppTappable(
                      onTap: () => setState(() {
                        _from = null;
                        _to = null;
                        _error = null;
                      }),
                      tooltip: AppStrings.segmentoSenzaOrari,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 17,
                          color: textSub,
                        ),
                      ),
                    ),
                ],
              ),

              // La durata vale solo per i segmenti senza orari: il portale li
              // ammette (una pausa dichiarata a minuti, un esonero banca ore).
              if (_unpositioned) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _minsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: textMain),
                  decoration: InputDecoration(
                    labelText: AppStrings.segmentoDurataMin,
                    labelStyle: TextStyle(color: textSub),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],

              if (_type == DaySegment.leave) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.causale,
                  style: TextStyle(fontSize: 13, color: textSub),
                ),
                const SizedBox(height: 8),
                ..._kindGroups.entries.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.key,
                          style: TextStyle(fontSize: 11, color: textSub),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: group.value
                              .map(
                                (k) => _Chip(
                                  label: AbsenceKind.labelFor(k),
                                  selected: _kind == k,
                                  accent: accent,
                                  textSub: textSub,
                                  isDark: isDark,
                                  onTap: () => setState(
                                    () => _kind = _kind == k ? null : k,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.red300 : AppColors.red700,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: textSub,
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: AppColors.blue600,
                      ),
                      child: const Text(AppStrings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color textSub;
  final bool isDark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textSub,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppTappable(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.14)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? accent : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check_rounded, size: 14, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? accent : textSub,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final Color accent;
  final Color textSub;
  final bool isDark;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.accent,
    required this.textSub,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null
        ? '--:--'
        : '${v.hour.toString().padLeft(2, '0')}:'
              '${v.minute.toString().padLeft(2, '0')}';
    return AppTappable(
      onTap: onTap,
      semanticLabel: '$label $text',
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textSub)),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
