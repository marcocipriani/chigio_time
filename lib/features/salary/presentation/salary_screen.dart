import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_header.dart';
import '../../profile/data/profile_repository.dart';
import '../data/salary_repository.dart';
import '../domain/salary_payment.dart';

// ── Type → colour map (mirrors prototype) ────────────────────────────────────
const _amber = Color(0xFFF59E0B);
const _violet = Color(0xFF8B5CF6);

Color _typeColor(SalaryPaymentType t) => switch (t) {
  SalaryPaymentType.ordinaria => AppColors.blue400,
  SalaryPaymentType.straordinaria => _amber,
  SalaryPaymentType.buoniPasto => AppColors.green500,
  SalaryPaymentType.altro => _violet,
};

final _euroFmt = NumberFormat('#,##0', 'it_IT');
String _euro(num v) => '${_euroFmt.format(v.round())} €';

/// Default payday (PCM emette il 23). Configurabile in Profilo › Notifiche.
const int kDefaultPaydayDay = 23;

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payments =
        ref.watch(salaryPaymentsStreamProvider).asData?.value ??
        const <SalaryPayment>[];
    final profile = ref.watch(userProfileStreamProvider).asData?.value;

    final paydayDay = (profile?['paydayDay'] as int?) ?? kDefaultPaydayDay;
    final notifyOn = profile?['notifyPayday'] as bool? ?? false;

    final stats = _SalaryStats.from(payments, paydayDay);
    final navClearance = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const GlassHeader(chigioPage: ChigioPage.other),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, navClearance + 90),
                  children: [
                    _NextCreditCard(
                      stats: stats,
                      notifyOn: notifyOn,
                      onToggleNotify: (v) => ref
                          .read(profileRepositoryProvider)
                          .updateProfileFields({'notifyPayday': v}),
                    ),
                    const SizedBox(height: 14),
                    _StatsRow(stats: stats),
                    const SizedBox(height: 18),
                    _SectionLabel(
                      label: AppStrings.salaryPaymentsReceived,
                      onAdd: () => _openEditSheet(context, ref, null),
                    ),
                    const SizedBox(height: 8),
                    const _Legend(),
                    const SizedBox(height: 10),
                    if (payments.isEmpty)
                      _EmptyState(isDark: isDark)
                    else
                      ..._buildGroupedList(context, ref, payments),
                  ],
                ),
                Positioned(
                  right: 4,
                  bottom: navClearance + 16,
                  child: _AddFab(onTap: () => _openEditSheet(context, ref, null)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<SalaryPayment> payments,
  ) {
    final widgets = <Widget>[];
    String? lastMonth;
    for (final p in payments) {
      if (p.monthId != lastMonth) {
        lastMonth = p.monthId;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              '${AppStrings.months[p.date.month - 1].toUpperCase()} ${p.date.year}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppColors.neutral600,
              ),
            ),
          ),
        );
      }
      widgets.add(
        _PaymentRow(
          payment: p,
          onTap: () => _openEditSheet(context, ref, p),
        ),
      );
    }
    return widgets;
  }

  void _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    SalaryPayment? existing,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalaryEditSheet(existing: existing, ref: ref),
    );
  }
}

// ── Derived stats ────────────────────────────────────────────────────────────

class _SalaryStats {
  final DateTime nextPayday;
  final int daysToPayday;
  final double? estimatedNet; // null when no ordinary history
  final double yearNet;
  final int yearCount;

  const _SalaryStats({
    required this.nextPayday,
    required this.daysToPayday,
    required this.estimatedNet,
    required this.yearNet,
    required this.yearCount,
  });

  factory _SalaryStats.from(List<SalaryPayment> payments, int paydayDay) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Next payday >= today.
    final clampedDay = paydayDay.clamp(1, 28);
    var next = DateTime(today.year, today.month, clampedDay);
    if (next.isBefore(today)) {
      next = DateTime(today.year, today.month + 1, clampedDay);
    }
    final days = next.difference(today).inDays;

    // Estimate from last 3 ordinary credits.
    final ordinary = payments
        .where((p) => p.type == SalaryPaymentType.ordinaria && p.netAmount > 0)
        .toList();
    double? estimate;
    if (ordinary.isNotEmpty) {
      final sample = ordinary.take(3).toList();
      estimate =
          sample.fold<double>(0, (a, p) => a + p.netAmount) / sample.length;
    }

    final yearPayments =
        payments.where((p) => p.year == now.year).toList();
    final yearNet = yearPayments.fold<double>(0, (a, p) => a + p.netAmount);

    return _SalaryStats(
      nextPayday: next,
      daysToPayday: days,
      estimatedNet: estimate,
      yearNet: yearNet,
      yearCount: yearPayments.length,
    );
  }
}

// ── Next credit hero card ────────────────────────────────────────────────────

class _NextCreditCard extends StatelessWidget {
  final _SalaryStats stats;
  final bool notifyOn;
  final ValueChanged<bool> onToggleNotify;

  const _NextCreditCard({
    required this.stats,
    required this.notifyOn,
    required this.onToggleNotify,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${AppStrings.weekdaysFull[stats.nextPayday.weekday - 1]} '
        '${stats.nextPayday.day} '
        '${AppStrings.months[stats.nextPayday.month - 1].toLowerCase()} '
        '${stats.nextPayday.year}';

    return GlassCard(
      overrideColor: AppColors.blue600.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'PROSSIMO ACCREDITO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.white70,
                  ),
                ),
              ),
              _NotifyChip(on: notifyOn, onTap: () => onToggleNotify(!notifyOn)),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.estimatedNet != null)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '≈ ${_euro(stats.estimatedNet!)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const TextSpan(
                    text: '  ${AppStrings.salaryNetSuffix}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              '—',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 13.5, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              AppStrings.salaryCountdown(stats.daysToPayday),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stats.estimatedNet != null
                ? AppStrings.salaryEstimateNote
                : AppStrings.salaryNotifyOnDay,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyChip extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _NotifyChip({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: on
              ? AppColors.green500.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: on
                ? AppColors.green500.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            const Text(
              AppStrings.salaryNotifyMe,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final _SalaryStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final avg = stats.yearCount > 0 ? stats.yearNet / stats.yearCount : 0;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: _euro(stats.yearNet),
            label: AppStrings.salaryYearNet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${stats.yearCount}',
            label: AppStrings.salaryPayslips,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: stats.yearCount > 0 ? _euro(avg) : '—',
            label: AppStrings.salaryAvgNet,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassTile(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label + add ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;
  const _SectionLabel({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppColors.neutral600,
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Text(
              '+ ${AppStrings.add}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blue400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;
    Widget item(Color dot, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(AppColors.blue400, AppStrings.salaryTypeOrdinaria),
          item(_amber, AppStrings.salaryTypeStraordinaria),
          item(AppColors.green500, AppStrings.salaryTypeBuoniPasto),
          item(_violet, AppStrings.salaryTypeAltro),
        ],
      ),
    );
  }
}

// ── Payment row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final SalaryPayment payment;
  final VoidCallback onTap;
  const _PaymentRow({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.neutral600;

    final meta = StringBuffer()
      ..write('${payment.date.day} ${AppStrings.monthsShort[payment.date.month - 1].toLowerCase()}');
    if (payment.grossAmount > 0) {
      meta.write(' · ${AppStrings.salaryGrossShort} ${_euro(payment.grossAmount)}');
    }
    if (payment.note != null) meta.write(' · 🗒');

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassTile(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _typeColor(payment.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            payment.type.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                          ),
                        ),
                        if (payment.manual) const _ManualBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _euro(payment.netAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  Text(
                    AppStrings.salaryNetShort,
                    style: TextStyle(fontSize: 10.5, color: textSub),
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

class _ManualBadge extends StatelessWidget {
  const _ManualBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _violet.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _violet.withValues(alpha: 0.4)),
      ),
      child: const Text(
        AppStrings.salaryManualBadge,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: _violet,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('💶', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            AppStrings.salaryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue600, AppColors.green600],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ── Add / edit sheet ─────────────────────────────────────────────────────────

class _SalaryEditSheet extends StatefulWidget {
  final SalaryPayment? existing;
  final WidgetRef ref;
  const _SalaryEditSheet({required this.existing, required this.ref});

  @override
  State<_SalaryEditSheet> createState() => _SalaryEditSheetState();
}

class _SalaryEditSheetState extends State<_SalaryEditSheet> {
  late SalaryPaymentType _type;
  late DateTime _date;
  late final TextEditingController _gross;
  late final TextEditingController _net;
  late final TextEditingController _note;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? SalaryPaymentType.ordinaria;
    _date = e?.date ?? _defaultDate();
    _gross = TextEditingController(
      text: e != null && e.grossAmount > 0 ? _euroFmt.format(e.grossAmount.round()) : '',
    );
    _net = TextEditingController(
      text: e != null && e.netAmount > 0 ? _euroFmt.format(e.netAmount.round()) : '',
    );
    _note = TextEditingController(text: e?.note ?? '');
  }

  DateTime _defaultDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _gross.dispose();
    _net.dispose();
    _note.dispose();
    super.dispose();
  }

  double _parse(String raw) {
    var s = raw.trim().replaceAll('€', '').replaceAll(' ', '');
    if (s.isEmpty) return 0;
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0;
  }

  Future<void> _save() async {
    final net = _parse(_net.text);
    if (net <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.salaryInvalidAmount)),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = widget.ref.read(salaryRepositoryProvider);
    final gross = _parse(_gross.text);
    final note = _note.text.trim();
    try {
      if (widget.existing == null) {
        await repo.addPayment(
          SalaryPayment(
            id: '',
            date: _date,
            type: _type,
            grossAmount: gross,
            netAmount: net,
            note: note.isEmpty ? null : note,
          ),
        );
      } else {
        await repo.updatePayment(
          widget.existing!.copyWith(
            date: _date,
            type: _type,
            grossAmount: gross,
            netAmount: net,
            note: note,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.salarySaved)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    await widget.ref.read(salaryRepositoryProvider).deletePayment(e.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.salaryDeleted)),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr =
        '${_date.day} ${AppStrings.months[_date.month - 1].toLowerCase()} ${_date.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              widget.existing == null
                  ? AppStrings.salaryNewPayment
                  : AppStrings.salaryEditPayment,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.salaryFieldType, isDark),
            const SizedBox(height: 6),
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _FieldLabel(AppStrings.salaryFieldDate, isDark),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: _FakeInput(text: dateStr, isDark: isDark, icon: Icons.event),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(AppStrings.salaryFieldGross, isDark),
                      const SizedBox(height: 6),
                      _AmountField(controller: _gross, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(AppStrings.salaryFieldNet, isDark),
                      const SizedBox(height: 6),
                      _AmountField(controller: _net, isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldLabel(AppStrings.salaryFieldNote, isDark),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              maxLines: 2,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              decoration: _inputDecoration(
                AppStrings.salaryNotePlaceholder,
                isDark,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: _saving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red700,
                    side: BorderSide(
                      color: AppColors.red700.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    AppStrings.delete,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.neutral600,
    ),
  );
}

InputDecoration _inputDecoration(String hint, bool isDark) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.neutral400,
  ),
  filled: true,
  fillColor: isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.6),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.neutral300,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.neutral300,
    ),
  ),
);

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  const _AmountField({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.neutral900,
      ),
      decoration: _inputDecoration('0', isDark),
    );
  }
}

class _FakeInput extends StatelessWidget {
  final String text;
  final bool isDark;
  final IconData icon;
  const _FakeInput({
    required this.text,
    required this.isDark,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.neutral300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
          ),
          Icon(icon, size: 18, color: AppColors.blue400),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final SalaryPaymentType selected;
  final ValueChanged<SalaryPaymentType> onChanged;
  final bool isDark;
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SalaryPaymentType.values.map((t) {
        final active = t == selected;
        return GestureDetector(
          onTap: () => onChanged(t),
          child: Container(
            width: (MediaQuery.sizeOf(context).width - 40 - 8) / 2 - 8,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.blue600.withValues(alpha: 0.35)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active
                    ? AppColors.blue400
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.neutral300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _typeColor(t),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    t.label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
