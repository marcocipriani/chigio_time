/// Sheet delle preferenze notifiche: promemoria di uscita, non disturbare,
/// riepilogo settimanale, alert straordinario e giorno di paga.
///
/// Estratto da `profile_screen.dart` (2026-07-25). Il modulo non conosce
/// Riverpod né il router: riceve i dati del profilo e due callback
/// (`onSave`, `onSendTest`), così resta testabile senza Firebase — vedi
/// `test/widget/notification_preferences_sheet_test.dart`.
library;

import 'package:flutter/material.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_tappable.dart';
import 'settings_sheet.dart';

enum NotificationPreferencesResult { testSent }

Future<NotificationPreferencesResult?> showNotificationPreferencesSheet({
  required BuildContext context,
  required Map<String, dynamic> profileData,
  required Future<void> Function(Map<String, dynamic>) onSave,
  required Future<void> Function() onSendTest,
}) {
  return showModalBottomSheet<NotificationPreferencesResult>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NotificationSheet(
      isDark: Theme.of(ctx).brightness == Brightness.dark,
      exitNotifMins: profileData['exitNotifMins'] as int? ?? 15,
      doNotDisturb: profileData['doNotDisturb'] as bool? ?? false,
      silenceFrom: profileData['silenceFrom'] as int? ?? 22,
      silenceTo: profileData['silenceTo'] as int? ?? 8,
      morningColleagues:
          profileData['notifyMorningColleagues'] as bool? ?? false,
      morningColleaguesHour: profileData['morningColleaguesHour'] as int? ?? 9,
      weeklyRecap: profileData['notifyWeeklyRecap'] as bool? ?? false,
      weeklyRecapDay: profileData['weeklyRecapDay'] as int? ?? 5,
      weeklyRecapHour: profileData['weeklyRecapHour'] as int? ?? 18,
      otAlertHours: profileData['monthlyOtAlertHours'] as int? ?? 0,
      payday: profileData['notifyPayday'] as bool? ?? false,
      paydayDay: profileData['paydayDay'] as int? ?? 23,
      onSave: onSave,
      onSendTest: onSendTest,
    ),
  );
}

class _NotificationSheet extends StatefulWidget {
  final bool isDark;
  final int exitNotifMins;
  final bool doNotDisturb;
  final int silenceFrom;
  final int silenceTo;
  final bool morningColleagues;
  final int morningColleaguesHour;
  final bool weeklyRecap;
  final int weeklyRecapDay;
  final int weeklyRecapHour;
  final int otAlertHours;
  final bool payday;
  final int paydayDay;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function() onSendTest;

  const _NotificationSheet({
    required this.isDark,
    required this.exitNotifMins,
    required this.doNotDisturb,
    required this.silenceFrom,
    required this.silenceTo,
    required this.morningColleagues,
    required this.morningColleaguesHour,
    required this.weeklyRecap,
    required this.weeklyRecapDay,
    required this.weeklyRecapHour,
    required this.otAlertHours,
    required this.payday,
    required this.paydayDay,
    required this.onSave,
    required this.onSendTest,
  });

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  late int _exitNotifMins;
  late bool _doNotDisturb;
  late int _silenceFrom;
  late int _silenceTo;
  late bool _morningColleagues;
  late int _morningColleaguesHour;
  late bool _weeklyRecap;
  late int _weeklyRecapDay;
  late int _weeklyRecapHour;
  late int _otAlertHours;
  late bool _payday;
  late int _paydayDay;
  bool _sendingTest = false;
  bool _savingPreferences = false;
  String? _inlineError;
  double _idleDragDistance = 0;

  bool get _isBusy => _sendingTest || _savingPreferences;

  static const _exitOptions = [0, 5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _exitNotifMins = widget.exitNotifMins;
    _doNotDisturb = widget.doNotDisturb;
    _silenceFrom = widget.silenceFrom;
    _silenceTo = widget.silenceTo;
    _morningColleagues = widget.morningColleagues;
    _morningColleaguesHour = widget.morningColleaguesHour;
    _weeklyRecap = widget.weeklyRecap;
    _weeklyRecapDay = widget.weeklyRecapDay;
    _weeklyRecapHour = widget.weeklyRecapHour;
    _otAlertHours = widget.otAlertHours;
    _payday = widget.payday;
    _paydayDay = widget.paydayDay;
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _sendingTest = true;
      _inlineError = null;
    });
    try {
      await widget.onSendTest();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingTest = false;
        _inlineError = AppStrings.testNotificationError(error);
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(NotificationPreferencesResult.testSent);
  }

  Future<void> _savePreferences() async {
    setState(() {
      _savingPreferences = true;
      _inlineError = null;
    });
    try {
      await widget.onSave({
        'exitNotifMins': _exitNotifMins,
        'doNotDisturb': _doNotDisturb,
        'silenceFrom': _silenceFrom,
        'silenceTo': _silenceTo,
        'notifyMorningColleagues': _morningColleagues,
        'morningColleaguesHour': _morningColleaguesHour,
        'notifyWeeklyRecap': _weeklyRecap,
        'weeklyRecapDay': _weeklyRecapDay,
        'weeklyRecapHour': _weeklyRecapHour,
        'monthlyOtAlertHours': _otAlertHours,
        'notifyPayday': _payday,
        'paydayDay': _paydayDay,
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingPreferences = false;
        _inlineError = AppStrings.errorSave(error);
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onVerticalDragStart(DragStartDetails _) => _idleDragDistance = 0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isBusy) return;
    _idleDragDistance = (_idleDragDistance + details.delta.dy)
        .clamp(0, double.infinity)
        .toDouble();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        !_isBusy && (_idleDragDistance >= 80 || velocity >= 700);
    _idleDragDistance = 0;
    if (shouldDismiss) Navigator.of(context).pop();
  }

  void _onVerticalDragCancel() => _idleDragDistance = 0;

  String _fmtHour(int h) => '${h.toString().padLeft(2, '0')}:00';

  Future<void> _pickHour(bool isFrom) async {
    final init = TimeOfDay(hour: isFrom ? _silenceFrom : _silenceTo, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      helpText: isFrom ? AppStrings.silenceFrom : AppStrings.silenceTo,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _silenceFrom = picked.hour;
        } else {
          _silenceTo = picked.hour;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final sheet = EditSheet(
      isDark: isDark,
      title: AppStrings.notifications,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Do Not Disturb + time range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔕', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.doNotDisturbLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _doNotDisturb,
                      onChanged: (v) => setState(() => _doNotDisturb = v),
                      activeThumbColor: AppColors.blue600,
                      activeTrackColor: AppColors.blue600.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
                if (_doNotDisturb) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerTile(
                          label: AppStrings.silenceFrom,
                          value: _fmtHour(_silenceFrom),
                          isDark: isDark,
                          onTap: () => _pickHour(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimePickerTile(
                          label: AppStrings.silenceTo,
                          value: _fmtHour(_silenceTo),
                          isDark: isDark,
                          onTap: () => _pickHour(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Exit reminder picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.expectedExitPushNotif,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _exitOptions.map((mins) {
                    final selected = _exitNotifMins == mins;
                    final label = mins == 0
                        ? AppStrings.off
                        : AppStrings.minutesShort(mins);
                    return ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : textSub,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _exitNotifMins = mins),
                      selectedColor: AppColors.blue600,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.7),
                      side: BorderSide(
                        color: selected
                            ? AppColors.blue600
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // S2: morning colleagues notification
          _NotifToggle(
            icon: '👥',
            label: AppStrings.notifyMorningColleagues,
            value: _morningColleagues,
            isDark: isDark,
            onChanged: (v) => setState(() => _morningColleagues = v),
          ),
          if (_morningColleagues) ...[
            const SizedBox(height: 8),
            _TimePickerTile(
              label: AppStrings.notifyMorningHour,
              value: _fmtHour(_morningColleaguesHour),
              isDark: isDark,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _morningColleaguesHour,
                    minute: 0,
                  ),
                );
                if (picked != null) {
                  setState(() => _morningColleaguesHour = picked.hour);
                }
              },
            ),
          ],
          const SizedBox(height: 8),
          // P2: weekly recap notification
          _NotifToggle(
            icon: '📈',
            label: AppStrings.notifyWeeklyRecap,
            value: _weeklyRecap,
            isDark: isDark,
            onChanged: (v) => setState(() => _weeklyRecap = v),
          ),
          if (_weeklyRecap) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: AppStrings.notifyWeeklyDay,
                    value: AppStrings.weekdayShort[_weeklyRecapDay - 1],
                    isDark: isDark,
                    onTap: () async {
                      final day = await showDialog<int>(
                        context: context,
                        builder: (_) => _WeekdayPickerDialog(
                          current: _weeklyRecapDay,
                          isDark: isDark,
                        ),
                      );
                      if (day != null) setState(() => _weeklyRecapDay = day);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimePickerTile(
                    label: AppStrings.notifyWeeklyHour,
                    value: _fmtHour(_weeklyRecapHour),
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _weeklyRecapHour,
                          minute: 0,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _weeklyRecapHour = picked.hour);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Avviso soglia straordinari — notifica quando lo straordinario del
          // mese supera la soglia (0 = disattivato).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.otAlertThreshold,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: textSub,
                  onPressed: _otAlertHours <= 0
                      ? null
                      : () => setState(() => _otAlertHours -= 1),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    _otAlertHours == 0
                        ? AppStrings.art9Off
                        : '${_otAlertHours}h',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: AppColors.blue600,
                  onPressed: _otAlertHours >= 80
                      ? null
                      : () => setState(() => _otAlertHours += 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stipendio in arrivo — promemoria push il giorno dell'accredito.
          _NotifToggle(
            icon: '💶',
            label: AppStrings.notifPayday,
            value: _payday,
            isDark: isDark,
            onChanged: (v) => setState(() => _payday = v),
          ),
          if (_payday) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.notifPaydayDay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: textSub,
                    onPressed: _paydayDay <= 1
                        ? null
                        : () => setState(() => _paydayDay -= 1),
                  ),
                  SizedBox(
                    width: 92,
                    child: Text(
                      AppStrings.notifPaydayDayValue(_paydayDay),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.blue600,
                    onPressed: _paydayDay >= 28
                        ? null
                        : () => setState(() => _paydayDay += 1),
                  ),
                ],
              ),
            ),
          ],
          if (_inlineError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red700.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.red700.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _inlineError!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.red300 : AppColors.red700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _sendTestNotification,
            icon: _sendingTest
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.notifications_active_outlined),
            label: const Text(AppStrings.sendTestNotification),
          ),
          const SizedBox(height: 10),
          SaveButton(enabled: !_isBusy, onPressed: _savePreferences),
        ],
      ),
    );

    return PopScope(
      canPop: !_isBusy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: _onVerticalDragCancel,
        child: IgnorePointer(ignoring: _isBusy, child: sheet),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.blue600,
            activeTrackColor: AppColors.blue600.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
    return AppTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textSub)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayPickerDialog extends StatelessWidget {
  final int current;
  final bool isDark;

  const _WeekdayPickerDialog({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final bg = isDark ? const Color(0xFF131830) : Colors.white;
    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.notifyWeeklyDay,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textMain,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (i) {
              final day = i + 1;
              final label = AppStrings.weekdayShort[i];
              final selected = current == day;
              return ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.blue600 : textMain,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.blue600)
                    : null,
                onTap: () => Navigator.of(context).pop(day),
              );
            }),
          ],
        ),
      ),
    );
  }
}
