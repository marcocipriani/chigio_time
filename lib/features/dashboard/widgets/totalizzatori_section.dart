import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/totalizzatori.dart';
import '../domain/custom_counter.dart';
import '../presentation/custom_counters_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/profile/data/profile_repository.dart';
import '../../../features/timesheet/data/timesheet_repository.dart'
    show monthlyTimesheetsProvider;
import '../../../features/timesheet/domain/absence_consumption.dart';

String _hm(int mins) {
  final h = mins ~/ 60;
  final m = mins % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// ── Alert banner ───────────────────────────────────────────────────────────

class TotAlertBanner extends StatelessWidget {
  final List<TotAlert> alerts;
  const TotAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: AppColors.orange500,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.alerts,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.orange500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: alerts.map((a) => _AlertChip(a, isDark: isDark)).toList(),
          ),
        ],
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  final TotAlert alert;
  final bool isDark;
  const _AlertChip(this.alert, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isRed = alert.level == TotAlertLevel.red;
    final fg = isRed ? AppColors.red700 : AppColors.orange600;
    final bg = isRed
        ? (isDark ? AppColors.red700.withValues(alpha: 0.18) : AppColors.red50)
        : (isDark
              ? AppColors.orange600.withValues(alpha: 0.18)
              : AppColors.orange50);
    final border = isRed ? AppColors.red300 : AppColors.orange300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRed ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banca ore hero tile ────────────────────────────────────────────────────

class BancaOreTile extends ConsumerWidget {
  final Totalizzatori data;
  const BancaOreTile({super.key, required this.data});

  static String _hmFmt(int mins) {
    if (mins == 0) return '0:00';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  void _openEdit(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final acCtrl = TextEditingController(text: _hmFmt(data.bancaOreAcResiduo));
    final apCtrl = TextEditingController(text: _hmFmt(data.bancaOreApResiduo));

    int parseHm(String s) {
      final parts = s.trim().split(':');
      if (parts.length != 2) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final textMain = isDark
              ? Colors.white.withValues(alpha: 0.9)
              : AppColors.neutral900;
          final textSub = isDark
              ? Colors.white.withValues(alpha: 0.4)
              : AppColors.neutral600;

          Widget field(String label, TextEditingController ctrl) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSub,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: '00:00',
                    hintStyle: TextStyle(color: textSub),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    suffixText: AppStrings.timePlaceholder,
                    suffixStyle: TextStyle(fontSize: 11, color: textSub),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          );

          final acMins = parseHm(acCtrl.text);
          final apMins = parseHm(apCtrl.text);
          final tot = acMins + apMins;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F1028).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    AppStrings.bankHoursUpper,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hm(tot),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green600,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  field(AppStrings.acYearResidualLabel, acCtrl),
                  const SizedBox(height: 12),
                  field(AppStrings.apYearResidualLabel, apCtrl),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final ac = parseHm(acCtrl.text);
                      final ap = parseHm(apCtrl.text);
                      final total = ac + ap;
                      String toHmStr(int m) =>
                          '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
                      final portale = ref
                          .read(userProfileStreamProvider)
                          .asData
                          ?.value;
                      final raw = portale?['portaleJson'];
                      final map = raw is Map
                          ? Map<String, dynamic>.from(raw)
                          : <String, dynamic>{};
                      map['banca_ore_ac_residuo'] = toHmStr(ac);
                      map['banca_ore_ap_residuo'] = toHmStr(ap);
                      map['totale_banca_ore_fruibile'] = toHmStr(total);
                      await ref
                          .read(profileRepositoryProvider)
                          .savePortaleData(map);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          AppStrings.save,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _hm(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGreen = data.bancaOreIsGreenBadge;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral400;

    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final stdMins = profileData?['standardDailyMins'] as int? ?? 456;
    final alertHours = profileData?['bancaOreAlertHours'] as int? ?? 0;

    // Live delta from current month's timesheet entries.
    final now = DateTime.now();
    final monthly = ref.watch(
      monthlyTimesheetsProvider((year: now.year, month: now.month)),
    );
    final entries = monthly.asData?.value ?? [];
    final monthSboMins = entries.fold(0, (s, e) => s + e.sboMins);
    final monthBoeUsedMins = entries.fold(0, (s, e) => s + e.bancaOreMins);

    // AP-first deduction: available = portale base - BOE used this month.
    // SBO accumulated this month not yet reflected in portale adds to AC estimate.
    final apEff =
        (data.bancaOreApResiduo -
        monthBoeUsedMins.clamp(0, data.bancaOreApResiduo));
    final acEff =
        data.bancaOreAcResiduo +
        monthSboMins -
        (monthBoeUsedMins - data.bancaOreApResiduo).clamp(0, monthBoeUsedMins);
    final fruibile = (apEff + acEff).clamp(0, 9999);

    final hasDelta = monthSboMins > 0 || monthBoeUsedMins > 0;

    final alertMins = alertHours * 60;
    final showAlert = alertMins > 0 && fruibile >= alertMins;
    final daysCovered = stdMins > 0 ? fruibile ~/ stdMins : 0;
    final remMins = stdMins > 0 ? fruibile % stdMins : 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.green600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.bankHoursUpper,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.green600,
                ),
              ),
              const Spacer(),
              if (isGreen)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    AppStrings.available,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => _openEdit(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.green600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppColors.green600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _hm(fruibile),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.green600,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          // AP (anno precedente) first, then AC (anno corrente) — deduction order.
          Row(
            children: [
              _BancaChip(
                label: AppStrings.apShort,
                value: _hm(apEff),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _BancaChip(
                label: AppStrings.acShort,
                value: _hm(acEff.clamp(0, 9999)),
                isDark: isDark,
              ),
              Expanded(
                child: Text(
                  AppStrings.prevPlusCurrentYear,
                  style: TextStyle(fontSize: 9, color: textSub),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          // Giorni coperti + alert soglia
          if (fruibile > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green600.withValues(
                      alpha: isDark ? 0.14 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysCovered > 0
                        ? '$daysCovered ${AppStrings.giorni} + ${_hm(remMins)}'
                        : _hm(remMins),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.coverableWorkDays,
                  style: TextStyle(fontSize: 9, color: textSub),
                ),
                if (showAlert) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: AppColors.orange600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          AppStrings.bancaOreAlert,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Live delta row — shown only when this month has SBO/BOE data.
          if (hasDelta) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (monthSboMins > 0)
                  _DeltaChip(
                    label: AppStrings.sboDelta(_hm(monthSboMins)),
                    color: AppColors.green600,
                    isDark: isDark,
                  ),
                if (monthSboMins > 0 && monthBoeUsedMins > 0)
                  const SizedBox(width: 6),
                if (monthBoeUsedMins > 0)
                  _DeltaChip(
                    label: AppStrings.boeUsedDelta(_hm(monthBoeUsedMins)),
                    color: AppColors.orange600,
                    isDark: isDark,
                  ),
                Expanded(
                  child: Text(
                    AppStrings.thisMonth,
                    style: TextStyle(fontSize: 9, color: textSub),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BancaChip extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _BancaChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green600.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green600.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.green600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _DeltaChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

// ── Totalizzatori full-detail section ─────────────────────────────────────

class TotalizzatoriSection extends StatelessWidget {
  final Totalizzatori data;
  final AbsenceConsumption? consumption;
  final VoidCallback? onEdit;
  final Future<void> Function(Map<String, dynamic>)? onChipEdit;
  const TotalizzatoriSection({
    super.key,
    required this.data,
    this.consumption,
    this.onEdit,
    this.onChipEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = data;
    final c = consumption;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 13,
                color: AppColors.blue600,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.totalizatori,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppColors.neutral400,
                ),
              ),
              if (d.periodo != null) ...[
                const SizedBox(width: 6),
                Text(
                  AppStrings.periodBullet(d.periodo!),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.neutral400,
                  ),
                ),
              ],
              const Spacer(),
              if (d.fetchedAt != null && d.fetchedAt!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppStrings.updatedAt(d.fetchedAt!),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : AppColors.neutral400,
                    ),
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppColors.neutral400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // FERIE
          _CategorySection(
            label: AppStrings.ferieUpper,
            color: AppColors.blue600,
            isDark: isDark,
            onChipEdit: onChipEdit,
            chips: [
              _Chip(
                AppStrings.usedAnnually,
                '${d.ferieFruitoAnnuo.round()} gg',
                total: '${d.ferieSpettanza.round()} gg',
                jsonKey: 'ferie_fruito_annuo',
                jsonKeyTotal: 'ferie_spettanza',
              ),
              _Chip(
                AppStrings.residualAc,
                '${d.ferieResiduoAnnoCorrente.round()} gg',
                total: '${d.ferieSpettanza.round()} gg',
                jsonKey: 'ferie_residuo_anno_corrente',
                jsonKeyTotal: 'ferie_spettanza',
              ),
              _Chip(
                AppStrings.residualAp,
                '${d.ferieResiduoAnnoPrecedente.round()} gg',
                level: d.ferieResiduoAnnoPrecedente > 0
                    ? TotAlertLevel.amber
                    : TotAlertLevel.info,
                jsonKey: 'ferie_residuo_anno_precedente',
              ),
              _Chip(
                AppStrings.residualTotal,
                '${d.ferieResidueTotali.round()} gg',
                level: d.ferieResidueTotali > 30
                    ? TotAlertLevel.red
                    : TotAlertLevel.info,
                jsonKey: 'ferie_residue_totali',
              ),
            ],
          ),
          _divider(isDark),

          // FESTIVITÀ SOPPRESSE
          _CategorySection(
            label: AppStrings.suppressedHolidays,
            color: AppColors.blue500,
            isDark: isDark,
            onChipEdit: onChipEdit,
            chips: [
              _Chip(
                AppStrings.usedAnnually,
                '${d.festSoppFruitoAnnuo.round()} gg',
                total: '${d.festSoppSpettanza.round()} gg',
                jsonKey: 'fest_sopp_fruito_annuo',
                jsonKeyTotal: 'fest_sopp_spettanza',
              ),
              _Chip(
                AppStrings.residuo,
                '${d.festSoppResiduo.round()} gg',
                total: '${d.festSoppSpettanza.round()} gg',
                jsonKey: 'fest_sopp_residuo',
                jsonKeyTotal: 'fest_sopp_spettanza',
              ),
            ],
          ),
          _divider(isDark),

          // STRAORDINARI
          _CategorySection(
            label: AppStrings.overtimePlural,
            color: AppColors.orange500,
            isDark: isDark,
            onChipEdit: onChipEdit,
            chips: [
              _Chip(
                AppStrings.art9Effettuate,
                _hm(d.protrazioniArt9Effettuate),
                total: _hm(
                  d.protrazioniArt9Effettuate + d.protrazioniArt9DaRecuperare,
                ),
                jsonKey: 'protrazioni_art9_effettuate',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.art9DaRecup,
                _hm(d.protrazioniArt9DaRecuperare),
                jsonKey: 'protrazioni_art9_da_recuperare',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.maggiorPresenza,
                _hm(d.maggiorPresenza),
                level: d.maggiorPresenza > 8 * 60
                    ? TotAlertLevel.amber
                    : TotAlertLevel.info,
                jsonKey: 'maggior_presenza',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.liquidati,
                _hm(d.straordinariLiquidati),
                total: _hm(d.straordinarioAutorizzato),
                jsonKey: 'straordinari_liquidati',
                jsonKeyTotal: 'straordinario_autorizzato',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.liquidabili,
                _hm(d.straordinariLiquidabili),
                total: _hm(d.straordinarioAutorizzato),
                level:
                    (d.straordinarioAutorizzato - d.straordinariLiquidabili) > 0
                    ? TotAlertLevel.amber
                    : TotAlertLevel.info,
                jsonKey: 'straordinari_liquidabili',
                jsonKeyTotal: 'straordinario_autorizzato',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.riposoCompMat,
                _hm(d.riposoCompMaturato),
                jsonKey: 'riposo_comp_maturato',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.riposoCompRes,
                _hm(d.riposoCompResiduo),
                jsonKey: 'riposo_comp_residuo',
                isMinutes: true,
              ),
            ],
          ),
          _divider(isDark),

          // PERMESSI
          _CategorySection(
            label: AppStrings.permessiUpper,
            color: AppColors.blue400,
            isDark: isDark,
            onChipEdit: onChipEdit,
            chips: [
              _Chip(
                AppStrings.deficitLabel,
                _hm(d.orePerse),
                jsonKey: 'ore_perse',
                isMinutes: true,
              ),
              _Chip(
                AppStrings.permessoBreveShort,
                _hm(d.permessoBreveResiduo),
                level: d.permessoBreveIsGreenBadge
                    ? TotAlertLevel.info
                    : TotAlertLevel.info,
                badge: d.permessoBreveIsGreenBadge ? '✓' : null,
                jsonKey: 'permesso_breve_residuo',
                isMinutes: true,
                appConsumed: c == null
                    ? null
                    : AppStrings.appConsumedOf(
                        _hm(c.shortLeaveMins),
                        _hm(AbsencePlafonds.shortLeaveYearlyMins),
                        c.year,
                      ),
                appConsumedAlert: c?.shortLeaveOverPlafond ?? false,
              ),
              _Chip(
                AppStrings.motiviPersonaliShort,
                _hm(d.permMotiviPersonaliResiduo),
                jsonKey: 'perm_motivi_personali_residuo',
                isMinutes: true,
                appConsumed: c == null
                    ? null
                    : AppStrings.appConsumedOf(
                        _hm(c.personalFamilyHourlyMins),
                        _hm(AbsencePlafonds.personalFamilyHourlyYearlyMins),
                        c.year,
                      ),
                appConsumedAlert: c?.personalFamilyHourlyOverPlafond ?? false,
              ),
              _Chip(
                AppStrings.visitaSpecialistShort,
                _hm(d.visitaSpecialisticaResiduo),
                jsonKey: 'visita_specialistica_residuo',
                isMinutes: true,
                appConsumed: c == null
                    ? null
                    : AppStrings.appConsumedSpecialistOf(
                        _hm(c.specialistVisitMins),
                        _hm(AbsencePlafonds.specialistVisitYearlyMins),
                        c.specialistVisitWithDocs,
                        c.specialistVisitCount,
                        c.year,
                      ),
                appConsumedAlert: c?.specialistVisitOverPlafond ?? false,
              ),
            ],
          ),

          // MALATTIA — periodi multi-giorno tracciati in app (P1)
          if (c != null && c.sicknessPeriods.isNotEmpty) ...[
            _divider(isDark),
            _CategorySection(
              label: AppStrings.sicknessPeriodsLabel(c.year),
              color: AppColors.orange600,
              isDark: isDark,
              chips: [
                _Chip(AppStrings.periodsLabel, '${c.sicknessPeriods.length}'),
                _Chip(AppStrings.totalDaysLabel, '${c.sicknessDaysTotal} gg'),
                for (final p in c.sicknessPeriods)
                  _Chip(
                    p.startDateId == p.endDateId
                        ? p.startDateId
                        : '${p.startDateId} → ${p.endDateId}',
                    '${p.days} gg',
                  ),
              ],
            ),
          ],
          _divider(isDark),

          // DEBITI
          _CategorySection(
            label: AppStrings.debitsUpper,
            color: AppColors.red700,
            isDark: isDark,
            onChipEdit: onChipEdit,
            chips: [
              _Chip(
                AppStrings.oreNonRecuperate,
                _hm(d.oreNonRecuperate),
                level: d.oreNonRecuperate > 0
                    ? TotAlertLevel.red
                    : TotAlertLevel.info,
                jsonKey: 'ore_non_recuperate',
                isMinutes: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.06),
    ),
  );
}

class _Chip {
  final String label;
  final String value;
  final String? total;
  final TotAlertLevel level;
  final String? badge;
  final String? jsonKey;
  final String? jsonKeyTotal;
  final bool isMinutes;

  /// Confronto col consumo personale tracciato in app (P1 — vedi
  /// docs/ccnl/permessi-assenze-congedi.md "Integrazione con totalizzatori").
  final String? appConsumed;
  final bool appConsumedAlert;
  const _Chip(
    this.label,
    this.value, {
    this.total,
    this.level = TotAlertLevel.info,
    this.badge,
    this.jsonKey,
    this.jsonKeyTotal,
    this.isMinutes = false,
    this.appConsumed,
    this.appConsumedAlert = false,
  });
}

class _CategorySection extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final List<_Chip> chips;
  final Future<void> Function(Map<String, dynamic>)? onChipEdit;

  const _CategorySection({
    required this.label,
    required this.color,
    required this.isDark,
    required this.chips,
    this.onChipEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppColors.neutral400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: chips
              .map(
                (c) => _MetricChip(c, isDark: isDark, onChipEdit: onChipEdit),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final _Chip chip;
  final bool isDark;
  final Future<void> Function(Map<String, dynamic>)? onChipEdit;
  const _MetricChip(this.chip, {required this.isDark, this.onChipEdit});

  String _stripGg(String v) => v.replaceAll(' gg', '').trim();

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color valueColor;

    switch (chip.level) {
      case TotAlertLevel.red:
        borderColor = AppColors.red300.withValues(alpha: 0.6);
        bgColor = isDark
            ? AppColors.red700.withValues(alpha: 0.15)
            : AppColors.red50;
        valueColor = AppColors.red700;
      case TotAlertLevel.amber:
        borderColor = AppColors.orange300.withValues(alpha: 0.6);
        bgColor = isDark
            ? AppColors.orange600.withValues(alpha: 0.15)
            : AppColors.orange50;
        valueColor = AppColors.orange600;
      case TotAlertLevel.info:
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08);
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03);
        valueColor = isDark
            ? Colors.white.withValues(alpha: 0.85)
            : AppColors.neutral900;
    }

    final canEdit = onChipEdit != null && chip.jsonKey != null;

    Widget chipWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chip.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.38)
                      : AppColors.neutral400,
                  letterSpacing: 0.2,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_rounded,
                  size: 9,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.neutral400.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chip.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (chip.total != null) ...[
                Text(
                  ' / ',
                  style: TextStyle(
                    fontSize: 11,
                    color: valueColor.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  chip.total!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
              if (chip.badge != null) ...[
                const SizedBox(width: 4),
                Text(
                  chip.badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green500,
                  ),
                ),
              ],
            ],
          ),
          if (chip.appConsumed != null) ...[
            const SizedBox(height: 2),
            Text(
              chip.appConsumed!,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: chip.appConsumedAlert
                    ? AppColors.orange600
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.32)
                          : AppColors.neutral400),
              ),
            ),
          ],
        ],
      ),
    );

    if (!canEdit) return chipWidget;

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _QuickChipEditSheet(
          isDark: isDark,
          title: chip.label,
          initialValue: chip.isMinutes ? chip.value : _stripGg(chip.value),
          initialTotal: chip.total != null
              ? (chip.isMinutes ? chip.total! : _stripGg(chip.total!))
              : null,
          hasTotal: chip.jsonKeyTotal != null,
          isMinutes: chip.isMinutes,
          onSave: (val, tot) async {
            final updates = <String, dynamic>{};
            updates[chip.jsonKey!] = chip.isMinutes
                ? val
                : num.tryParse(val) ?? 0;
            if (chip.jsonKeyTotal != null && tot != null) {
              updates[chip.jsonKeyTotal!] = chip.isMinutes
                  ? tot
                  : num.tryParse(tot) ?? 0;
            }
            await onChipEdit!(updates);
          },
        ),
      ),
      child: chipWidget,
    );
  }
}

// ── Quick edit sheet for individual counter ───────────────────────────────────

class _QuickChipEditSheet extends StatefulWidget {
  final bool isDark;
  final String title;
  final String initialValue;
  final String? initialTotal;
  final bool hasTotal;
  final bool isMinutes;
  final Future<void> Function(String value, String? total) onSave;

  const _QuickChipEditSheet({
    required this.isDark,
    required this.title,
    required this.initialValue,
    this.initialTotal,
    required this.hasTotal,
    required this.isMinutes,
    required this.onSave,
  });

  @override
  State<_QuickChipEditSheet> createState() => _QuickChipEditSheetState();
}

class _QuickChipEditSheetState extends State<_QuickChipEditSheet> {
  late final TextEditingController _valueCtrl;
  late final TextEditingController _totalCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _valueCtrl = TextEditingController(text: widget.initialValue);
    _totalCtrl = TextEditingController(text: widget.initialTotal ?? '');
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    final hint = widget.isMinutes
        ? AppStrings.timePlaceholder
        : AppStrings.decimalHint;
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
              ? const Color(0xFF0F1028).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textMain,
              ),
            ),
            const SizedBox(height: 16),
            _field(AppStrings.currentValue, _valueCtrl, hint, textSub, isDark),
            if (widget.hasTotal) ...[
              const SizedBox(height: 10),
              _field(AppStrings.entitledMax, _totalCtrl, hint, textSub, isDark),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final nav = Navigator.of(context);
                        try {
                          await widget.onSave(
                            _valueCtrl.text.trim(),
                            widget.hasTotal ? _totalCtrl.text.trim() : null,
                          );
                          if (mounted) nav.pop();
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        AppStrings.save,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint,
    Color textSub,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSub,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: widget.isMinutes
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSub),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom counters section ───────────────────────────────────────────────────

class CustomCountersSection extends ConsumerWidget {
  const CustomCountersSection({super.key});

  Future<void> _save(WidgetRef ref, List<CustomCounter> counters) async {
    await ref
        .read(profileRepositoryProvider)
        .saveCustomCounters(counters.map((c) => c.toJson()).toList());
  }

  Future<void> _showAddEdit(
    BuildContext context,
    WidgetRef ref,
    List<CustomCounter> counters, {
    CustomCounter? editing,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<CustomCounter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CounterEditSheet(isDark: isDark, editing: editing),
    );
    if (result == null) return;
    final updated = List<CustomCounter>.from(counters);
    if (editing != null) {
      final idx = updated.indexWhere((c) => c.id == editing.id);
      if (idx != -1) updated[idx] = result;
    } else {
      updated.add(result);
    }
    await _save(ref, updated);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    List<CustomCounter> counters,
    CustomCounter c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.deleteCounterConfirm(c.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.red700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _save(ref, counters.where((x) => x.id != c.id).toList());
    }
  }

  Future<void> _importDefaults(
    BuildContext context,
    WidgetRef ref,
    List<CustomCounter> existing,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.importDefaults),
        content: const Text(AppStrings.importDefaultsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              AppStrings.importDefaults,
              style: TextStyle(color: AppColors.blue600),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final merged = List<CustomCounter>.from(existing);
    for (final def in kPcmDefaultCounters) {
      final counter = CustomCounter.fromJson(Map<String, dynamic>.from(def));
      final idx = merged.indexWhere((c) => c.id == counter.id);
      if (idx == -1) {
        merged.add(counter);
      } else {
        merged[idx] = merged[idx].copyWith(
          label: counter.label,
          unit: counter.unit,
          sortOrder: counter.sortOrder,
        );
      }
    }
    await _save(ref, merged);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.importDefaultsDone)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counters = ref.watch(customCountersProvider);
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : AppColors.neutral400;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 13,
                color: AppColors.blue600,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.customCounters,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textSub,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _importDefaults(context, ref, counters),
                child: Text(
                  AppStrings.importDefaults,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showAddEdit(context, ref, counters),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (counters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppStrings.noCustomCounters,
                style: TextStyle(fontSize: 12, color: textSub, height: 1.5),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counters
                  .map(
                    (c) => _CustomChip(
                      counter: c,
                      isDark: isDark,
                      onEdit: () =>
                          _showAddEdit(context, ref, counters, editing: c),
                      onDelete: () => _delete(context, ref, counters, c),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ── Custom counter chip ───────────────────────────────────────────────────────

class _CustomChip extends StatelessWidget {
  final CustomCounter counter;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomChip({
    required this.counter,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = counter.color;
    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              counter.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: c.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  counter.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c,
                    letterSpacing: -0.5,
                  ),
                ),
                if (counter.unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    counter.unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Counter edit bottom sheet ─────────────────────────────────────────────────

class _CounterEditSheet extends StatefulWidget {
  final bool isDark;
  final CustomCounter? editing;
  const _CounterEditSheet({required this.isDark, this.editing});

  @override
  State<_CounterEditSheet> createState() => _CounterEditSheetState();
}

class _CounterEditSheetState extends State<_CounterEditSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _unitCtrl;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.editing?.label ?? '');
    _valueCtrl = TextEditingController(text: widget.editing?.value ?? '');
    _unitCtrl = TextEditingController(text: widget.editing?.unit ?? '');
    _colorIndex = widget.editing?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    if (label.isEmpty || value.isEmpty) return;
    const uuid = Uuid();
    final counter = CustomCounter(
      id: widget.editing?.id ?? uuid.v4(),
      label: label,
      value: value,
      unit: _unitCtrl.text.trim(),
      colorIndex: _colorIndex,
      sortOrder:
          widget.editing?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
    );
    Navigator.pop(context, counter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    Widget inputField(
      String label,
      TextEditingController ctrl, {
      TextInputType? keyboardType,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSub,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardH),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + (keyboardH == 0 ? safeBottom : 0),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10102A).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.editing == null
                      ? AppStrings.addCounter
                      : AppStrings.edit,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 16),
                inputField(
                  AppStrings.counterLabel,
                  _labelCtrl,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: inputField(
                        AppStrings.counterValue,
                        _valueCtrl,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: inputField(
                        AppStrings.counterUnit,
                        _unitCtrl,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Color picker
                Text(
                  AppStrings.colorLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    CustomCounter.palette.length,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _colorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: CustomCounter.palette[i],
                          shape: BoxShape.circle,
                          border: _colorIndex == i
                              ? Border.all(
                                  color: isDark ? Colors.white : Colors.black,
                                  width: 2.5,
                                )
                              : null,
                          boxShadow: _colorIndex == i
                              ? [
                                  BoxShadow(
                                    color: CustomCounter.palette[i].withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.editing == null
                        ? AppStrings.addCounter
                        : AppStrings.save,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
