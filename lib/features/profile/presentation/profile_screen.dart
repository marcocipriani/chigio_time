import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import '../data/profile_repository.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../app/theme/color_schemes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pcm_locations.dart';
import '../../../core/data/pcm_locations_repository.dart';
import '../../../shared/widgets/monthly_summary_card.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../../features/authentication/data/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/geofencing_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    String fmtMins(int m) =>
        '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

    // AppBackground is already provided by app.dart — no gradient here.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(
                                    0xFF10102A,
                                  ).withValues(alpha: 0.58)
                                : Colors.white.withValues(alpha: 0.56),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.neutral700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.navProfile,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(AppStrings.errorGeneric(e))),
                data: (data) {
                  if (data == null) {
                    return Center(
                      child: Text(
                        AppStrings.errorNoData,
                        style: TextStyle(color: textSub),
                      ),
                    );
                  }

                  final name = data['name'] as String? ?? 'Utente';
                  final administration =
                      data['administration'] as String? ?? 'PCM';
                  final employmentType =
                      data['employmentType'] as String? ?? '—';
                  final stdMins = data['standardDailyMins'] as int? ?? 456;
                  final rawSchedule = data['weeklyScheduleMins'];
                  final weeklyScheduleMins = rawSchedule is Map
                      ? {
                          for (final e in rawSchedule.entries)
                            int.tryParse(e.key.toString()) ?? 0:
                                (e.value as num).toInt(),
                        }
                      : <int, int>{};
                  final hasCustomSchedule =
                      weeklyScheduleMins.isNotEmpty &&
                      weeklyScheduleMins.values.any((v) => v != stdMins);
                  final mealMins =
                      data['mealVoucherThresholdMins'] as int? ?? 380;
                  final gender = data['gender'] as String? ?? 'N';
                  final dipartimento = data['dipartimento'] as String? ?? '';
                  final interno = data['interno'] as String? ?? '';
                  final sede = data['sede'] as String? ?? '';
                  final piano = data['piano'] as String? ?? '';
                  final stanza = data['stanza'] as String? ?? '';
                  final art9 = data['monthlyArt9Hours'] as int? ?? 0;
                  final sli = data['monthlySliHours'] as int? ?? 0;
                  final sbo = data['monthlySboHours'] as int? ?? 0;
                  final overtime = data['monthlyOvertimeHours'] as int? ?? 0;
                  final phone = data['phoneNumber'] as String?;
                  final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

                  final now = DateTime.now();
                  final monthlyEntries =
                      ref
                          .watch(
                            monthlyTimesheetsProvider((
                              year: now.year,
                              month: now.month,
                            )),
                          )
                          .asData
                          ?.value ??
                      [];

                  final workedEntries = monthlyEntries
                      .where(
                        (e) =>
                            e.netWorkedMins > 0 && !e.isLeave && !e.isHoliday,
                      )
                      .toList();
                  final maxMins = workedEntries.isEmpty
                      ? 0
                      : workedEntries
                            .map((e) => e.netWorkedMins)
                            .reduce((a, b) => a > b ? a : b);
                  final latestEnd = workedEntries.isEmpty
                      ? null
                      : workedEntries
                            .map((e) => e.endTime)
                            .reduce((a, b) => a.isAfter(b) ? a : b);
                  final earliestEnd = workedEntries.isEmpty
                      ? null
                      : workedEntries
                            .map((e) => e.endTime)
                            .reduce((a, b) => a.isBefore(b) ? a : b);
                  final swDays = monthlyEntries.where((e) => e.isRemote).length;

                  // Last 6 months OT for bar chart
                  final last6 = List.generate(6, (i) {
                    final d = DateTime(now.year, now.month - i, 1);
                    return (year: d.year, month: d.month);
                  }).reversed.toList();

                  final last6Data = last6.map((ym) {
                    final entries =
                        ref
                            .watch(
                              monthlyTimesheetsProvider((
                                year: ym.year,
                                month: ym.month,
                              )),
                            )
                            .asData
                            ?.value ??
                        [];
                    final otMins = entries
                        .where((e) => e.extraMins > 0)
                        .fold<int>(0, (sum, e) => sum + e.extraMins);
                    final presenceDays = entries
                        .where(
                          (e) =>
                              !e.isLeave && !e.isHoliday && e.netWorkedMins > 0,
                        )
                        .length;
                    return (ym: ym, otMins: otMins, presenceDays: presenceDays);
                  }).toList();

                  String p2(int n) => n.toString().padLeft(2, '0');
                  String fmtEnd(DateTime? dt) =>
                      dt == null ? '—' : '${p2(dt.hour)}:${p2(dt.minute)}';
                  String fmtMax(int m) => m == 0
                      ? '—'
                      : '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

                  final isDesktop = MediaQuery.sizeOf(context).width >= 800;

                  Widget content = ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      // ── Avatar card ────────────────────────────
                      GlassCard(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.8),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blue600.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: photoUrl != null
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _InitialAvatar(name: name),
                                      )
                                    : _InitialAvatar(name: name),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$employmentType · $administration',
                              style: TextStyle(fontSize: 12, color: textSub),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _memberSince(FirebaseAuth.instance.currentUser),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : AppColors.neutral400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  label: AppStrings.dayRecord,
                                  value: fmtMax(maxMins),
                                  isDark: isDark,
                                ),
                                _StatItem(
                                  label: AppStrings.lateExit,
                                  value: fmtEnd(latestEnd),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  label: AppStrings.quickExit,
                                  value: fmtEnd(earliestEnd),
                                  isDark: isDark,
                                ),
                                _StatItem(
                                  label: AppStrings.wtRemoteShort,
                                  value: swDays == 0 ? '—' : '$swDays gg 🏠',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            InkWell(
                              onTap: () => context.push('/stats'),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.bar_chart_rounded,
                                      size: 15,
                                      color: AppColors.blue600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.statsLink,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blue600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      _OtTrendCard(
                        data: last6Data,
                        isDark: isDark,
                        monthsShort: AppStrings.monthsShort,
                      ),

                      const SizedBox(height: 11),

                      // ── Dati profilo (tutti editabili) ─────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: '👤',
                              label: 'Nome completo',
                              value: name,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editTextField(
                                context,
                                ref,
                                title: 'Nome completo',
                                current: name,
                                fieldKey: 'name',
                                keyboardType: TextInputType.name,
                                capitalization: TextCapitalization.words,
                                validator: (v) => v.trim().isEmpty
                                    ? 'Il nome non può essere vuoto'
                                    : null,
                              ),
                            ),
                            _InfoRow(
                              icon: '🧬',
                              label: 'Genere (per Chigio)',
                              value: switch (gender) {
                                'M' => '♂ Maschile',
                                'F' => '♀ Femminile',
                                'A' => '∅ Altrə',
                                _ => '⚥ Neutro',
                              },
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editGender(context, ref, gender),
                            ),
                            _InfoRow(
                              icon: '🏛️',
                              label: 'Ente',
                              value: administration,
                              isDark: isDark,
                              divider: true,
                              onEdit: () =>
                                  _editEnteList(context, ref, administration),
                            ),
                            _InfoRow(
                              icon: '🏢',
                              label: AppStrings.dipartimento,
                              value: dipartimento.isEmpty ? '—' : dipartimento,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editPcmStructureList(
                                context,
                                ref,
                                dipartimento,
                              ),
                            ),
                            _InfoRow(
                              icon: '🏛️',
                              label: AppStrings.sede,
                              value: sede.isEmpty ? '—' : sede,
                              isDark: isDark,
                              divider: true,
                              onEdit: () =>
                                  _editPcmSiteList(context, ref, sede),
                            ),
                            _InfoRow(
                              icon: '🔢',
                              label: AppStrings.piano,
                              value: piano.isEmpty ? '—' : piano,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editTextField(
                                context,
                                ref,
                                title: AppStrings.piano,
                                current: piano,
                                fieldKey: 'piano',
                                keyboardType: TextInputType.text,
                                capitalization: TextCapitalization.words,
                              ),
                            ),
                            _InfoRow(
                              icon: '🚪',
                              label: AppStrings.stanzaUfficio,
                              value: stanza.isEmpty ? '—' : stanza,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editTextField(
                                context,
                                ref,
                                title: AppStrings.stanzaUfficio,
                                current: stanza,
                                fieldKey: 'stanza',
                                keyboardType: TextInputType.text,
                                capitalization: TextCapitalization.words,
                              ),
                            ),
                            _InfoRow(
                              icon: '☎️',
                              label: AppStrings.interno,
                              value: interno.isEmpty ? '—' : interno,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editTextField(
                                context,
                                ref,
                                title: AppStrings.interno,
                                current: interno,
                                fieldKey: 'interno',
                                keyboardType: TextInputType.number,
                                capitalization: TextCapitalization.none,
                              ),
                            ),
                            _PhoneRow(
                              phone: phone,
                              isDark: isDark,
                              onEdit: () =>
                                  _editPhone(context, ref, phone ?? ''),
                            ),
                            _InfoRow(
                              icon: '📋',
                              label: AppStrings.employmentType,
                              value: employmentType,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editEmploymentType(
                                context,
                                ref,
                                employmentType,
                              ),
                            ),
                            _InfoRow(
                              icon: '🕐',
                              label: AppStrings.standardHours,
                              value: fmtMins(stdMins),
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editStandardHoursPresets(
                                context,
                                ref,
                                employmentType,
                                stdMins,
                              ),
                            ),
                            _InfoRow(
                              icon: '📅',
                              label: 'Orario settimanale',
                              value: hasCustomSchedule
                                  ? _weeklyScheduleSummary(
                                      weeklyScheduleMins,
                                      stdMins,
                                    )
                                  : 'Uniforme',
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editWeeklySchedule(
                                context,
                                ref,
                                stdMins,
                                weeklyScheduleMins,
                              ),
                            ),
                            _InfoRow(
                              icon: '🍽️',
                              label: AppStrings.mealThreshold,
                              value: fmtMins(mealMins),
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editSlider(
                                context,
                                ref,
                                title: AppStrings.mealThreshold,
                                icon: '🍽️',
                                currentValue: mealMins.toDouble(),
                                min: 240,
                                max: 480,
                                divisions: 48,
                                fieldKey: 'mealVoucherThresholdMins',
                                formatValue: (v) {
                                  final m = v.round();
                                  return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
                                },
                              ),
                            ),
                            _InfoRow(
                              icon: '📑',
                              label: AppStrings.articleNine,
                              value: '$art9 h/mese',
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editIntHours(
                                context,
                                ref,
                                title: '${AppStrings.articleNine} mensile',
                                currentValue: art9,
                                min: 0,
                                max: 50,
                                fieldKey: 'monthlyArt9Hours',
                              ),
                            ),
                            _InfoRow(
                              icon: '💳',
                              label: 'SLI mensile',
                              value: '$sli h/mese',
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editIntHours(
                                context,
                                ref,
                                title: 'SLI mensile',
                                currentValue: sli,
                                min: 0,
                                max: 50,
                                fieldKey: 'monthlySliHours',
                              ),
                            ),
                            _InfoRow(
                              icon: '🏦',
                              label: 'SBO mensile',
                              value: '$sbo h/mese',
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editIntHours(
                                context,
                                ref,
                                title: 'SBO mensile',
                                currentValue: sbo,
                                min: 0,
                                max: 50,
                                fieldKey: 'monthlySboHours',
                              ),
                            ),
                            _InfoRow(
                              icon: '⚠️',
                              label: AppStrings.overtimeCap,
                              value: '$overtime h/mese',
                              isDark: isDark,
                              divider: false,
                              onEdit: () => _editIntHours(
                                context,
                                ref,
                                title: '${AppStrings.overtimeCap} mensile',
                                currentValue: overtime,
                                min: 0,
                                max: 80,
                                fieldKey: 'monthlyOvertimeHours',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 11),

                      // ── GPS auto-timbratura ───────────────────
                      _GpsSettingsCard(
                        isDark: isDark,
                        profileData: data,
                        ref: ref,
                        textSub: textSub,
                      ),

                      const SizedBox(height: 11),

                      _CcnlProfileCard(
                        isDark: isDark,
                        onOpen: () => _showCcnlReader(context, isDark),
                      ),

                      const SizedBox(height: 11),

                      // ── Impostazioni ──────────────────────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: '🎨',
                              label: 'Tema',
                              isDark: isDark,
                              trailing: _ThemePicker(
                                current: ref.watch(themeModeProvider),
                                isAutoByTime: ref
                                    .watch(themeModeProvider.notifier)
                                    .isAutoByTime,
                                onSelect: (m) => ref
                                    .read(themeModeProvider.notifier)
                                    .setTheme(m),
                                onAutoByTime: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setAutoByTime(),
                                isDark: isDark,
                              ),
                              onTap: null,
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🌐',
                              label: 'Lingua / Language',
                              isDark: isDark,
                              trailing: _LocalePicker(
                                current: ref.watch(localeProvider).languageCode,
                                isDark: isDark,
                                onSelect: (code) => ref
                                    .read(localeProvider.notifier)
                                    .setLocale(code),
                              ),
                              onTap: null,
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🏦',
                              label: 'Dati portale PA',
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => showPortaleEdit(context, ref, data),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '📊',
                              label: AppStrings.widgetCounters,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () =>
                                  showCountersCustomizer(context, ref, data),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '✨',
                              label: AppStrings.highlightWidget,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _showHighlightWidgetPicker(
                                context,
                                ref,
                                data,
                              ),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🧭',
                              label: AppStrings.navViewsVisibility,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _showNavViewsVisibilityPicker(
                                context,
                                ref,
                                data,
                              ),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🔔',
                              label: 'Notifiche',
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _showNotifiche(context, ref, data),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🔒',
                              label: 'Privacy',
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _showPrivacy(context, isDark),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: 'ℹ️',
                              label: AppStrings.appInfo,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _showAppInfo(context, isDark),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🐢',
                              label: 'Chigio',
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => context.push('/chigio'),
                              divider: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 11),

                      // ── Logout ────────────────────────────────
                      GlassBtn(
                        label: 'Esci dall\'account',
                        variant: GlassBtnVariant.secondary,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.red700,
                        ),
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          AppStrings.appVersion,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _DownloadBanner(isDark: isDark),
                      const SizedBox(height: 28),
                    ],
                  );

                  if (!isDesktop) return content;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit helpers ────────────────────────────────────────────────────────

String _memberSince(User? user) {
  final created = user?.metadata.creationTime;
  if (created == null) return '';
  final month = AppStrings.monthsShort[created.month - 1].toLowerCase();
  return 'Timbratonaut 🚀 dal ${created.day} $month ${created.year}';
}

String _weeklyScheduleSummary(Map<int, int> schedule, int defaultMins) {
  String hm(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return min == 0 ? '${h}h' : '${h}h${min}m';
  }

  final parts = <String>[];
  for (int d = 1; d <= 5; d++) {
    final mins = schedule[d] ?? defaultMins;
    parts.add(hm(mins));
  }
  final unique = parts.toSet();
  if (unique.length == 1) return unique.first;
  final names = ['L', 'M', 'M', 'G', 'V'];
  return List.generate(5, (i) => '${names[i]}:${parts[i]}').join(' ');
}

/// Generic single-line text edit bottom sheet.
Future<void> _editTextField(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String current,
  required String fieldKey,
  TextInputType keyboardType = TextInputType.text,
  TextCapitalization capitalization = TextCapitalization.none,
  String? Function(String)? validator,
}) async {
  final ctrl = TextEditingController(text: current);
  String? errorText;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return _EditSheet(
          isDark: isDark,
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: keyboardType,
                textCapitalization: capitalization,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.neutral900,
                ),
                decoration: InputDecoration(
                  errorText: errorText,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  if (errorText != null) setState(() => errorText = null);
                },
              ),
              const SizedBox(height: 16),
              _SaveButton(
                onPressed: () async {
                  final val = ctrl.text;
                  final err = validator?.call(val);
                  if (err != null) {
                    setState(() => errorText = err);
                    return;
                  }
                  await ref.read(profileRepositoryProvider).updateProfileFields(
                    {fieldKey: val.trim()},
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
  ctrl.dispose();
}

/// Slider edit bottom sheet — used for numeric profile fields.
Future<void> _editSlider(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String icon,
  required double currentValue,
  required double min,
  required double max,
  required int divisions,
  required String fieldKey,
  required String Function(double) formatValue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SliderSheet(
      title: title,
      icon: icon,
      initialValue: currentValue,
      min: min,
      max: max,
      divisions: divisions,
      fieldKey: fieldKey,
      formatValue: formatValue,
      onSave: (v) async {
        await ref.read(profileRepositoryProvider).updateProfileFields({
          fieldKey: v.round(),
        });
      },
    ),
  );
}

/// List picker for Ente field — only PCM active for now.
Future<void> _editEnteList(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final textMain = isDark
          ? Colors.white.withValues(alpha: 0.9)
          : AppColors.neutral900;
      final textSub = isDark
          ? Colors.white.withValues(alpha: 0.4)
          : AppColors.neutral400;
      return _EditSheet(
        isDark: isDark,
        title: 'Amministrazione',
        child: SizedBox(
          height: 340,
          child: ListView.builder(
            itemCount: AppStrings.administrations.length,
            itemBuilder: (_, i) {
              final ente = AppStrings.administrations[i];
              final isSelected = ente == current;
              final isEnabled = ente == AppStrings.presidenzaPCM;
              return InkWell(
                onTap: isEnabled
                    ? () async {
                        await ref
                            .read(profileRepositoryProvider)
                            .updateProfileFields({'administration': ente});
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Opacity(
                  opacity: isEnabled ? 1.0 : 0.38,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ente,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? AppColors.blue600 : textMain,
                            ),
                          ),
                        ),
                        if (!isEnabled)
                          Text(
                            AppStrings.comingSoon,
                            style: TextStyle(fontSize: 10, color: textSub),
                          ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.blue600,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> _editPcmStructureList(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (ctx, sheetRef, _) {
        final officesAsync = sheetRef.watch(pcmOfficeLocationsProvider);
        return officesAsync.when(
          data: (offices) => _PcmStructureSheet(
            current: current,
            offices: offices,
            onSelect: (office) async {
              await sheetRef
                  .read(profileRepositoryProvider)
                  .updateProfileFields({
                    'dipartimento': office.structureName,
                    'sede': office.locationName,
                    'sedeId': office.id,
                    'sedeAddress': office.address,
                    'sedeLat': office.latitude,
                    'sedeLng': office.longitude,
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          loading: () => const _PcmPickerLoading(title: 'Struttura PCM'),
          error: (_, _) => _PcmStructureSheet(
            current: current,
            offices: activePcmOfficeSeeds(),
            onSelect: (office) async {
              await ref.read(profileRepositoryProvider).updateProfileFields({
                'dipartimento': office.structureName,
                'sede': office.locationName,
                'sedeId': office.id,
                'sedeAddress': office.address,
                'sedeLat': office.latitude,
                'sedeLng': office.longitude,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        );
      },
    ),
  );
}

Future<void> _editPcmSiteList(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (ctx, sheetRef, _) {
        final sitesAsync = sheetRef.watch(pcmSiteLocationsProvider);
        return sitesAsync.when(
          data: (sites) => _PcmSiteSheet(
            current: current,
            sites: sites,
            onSelect: (site) async {
              await sheetRef
                  .read(profileRepositoryProvider)
                  .updateProfileFields({
                    'sede': site.name,
                    'sedeId': site.id,
                    'sedeAddress': site.address,
                    'sedeLat': site.latitude,
                    'sedeLng': site.longitude,
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          loading: () => const _PcmPickerLoading(title: AppStrings.sede),
          error: (_, _) => _PcmSiteSheet(
            current: current,
            sites: pcmSitesFromOffices(activePcmOfficeSeeds()),
            onSelect: (site) async {
              await ref.read(profileRepositoryProvider).updateProfileFields({
                'sede': site.name,
                'sedeId': site.id,
                'sedeAddress': site.address,
                'sedeLat': site.latitude,
                'sedeLng': site.longitude,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        );
      },
    ),
  );
}

class _PcmStructureSheet extends StatelessWidget {
  final String current;
  final List<PcmOfficeOption> offices;
  final Future<void> Function(PcmOfficeOption office) onSelect;

  const _PcmStructureSheet({
    required this.current,
    required this.offices,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = [...offices]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _EditSheet(
      isDark: isDark,
      title: 'Struttura PCM',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            itemBuilder: (_, i) {
              final office = sorted[i];
              final selected = office.structureName == current;
              return _PcmChoiceRow(
                selected: selected,
                title: office.structureName,
                subtitle: '${office.locationName} - ${office.address}',
                onTap: () => onSelect(office),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PcmSiteSheet extends StatelessWidget {
  final String current;
  final List<PcmSiteOption> sites;
  final Future<void> Function(PcmSiteOption site) onSelect;

  const _PcmSiteSheet({
    required this.current,
    required this.sites,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = [...sites]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _EditSheet(
      isDark: isDark,
      title: AppStrings.sede,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            itemBuilder: (_, i) {
              final site = sorted[i];
              final selected = site.name == current;
              final detail = site.structures.length == 1
                  ? site.structures.first
                  : '${site.structures.length} strutture';
              return _PcmChoiceRow(
                selected: selected,
                title: site.name,
                subtitle: '${site.address} - $detail',
                onTap: () => onSelect(site),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PcmChoiceRow extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PcmChoiceRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : AppColors.neutral600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.blue600.withValues(alpha: 0.14)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04)),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.apartment_rounded,
                size: 17,
                color: selected ? AppColors.blue600 : textSub,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.blue600 : textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PcmPickerLoading extends StatelessWidget {
  final String title;

  const _PcmPickerLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return _EditSheet(
      isDark: isDark,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.blue600,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          Text('Carico le sedi PCM...', style: TextStyle(color: textSub)),
        ],
      ),
    );
  }
}

/// Preset chips for standard daily hours, employment-type-aware.
Future<void> _editStandardHoursPresets(
  BuildContext context,
  WidgetRef ref,
  String employmentType,
  int currentMins,
) async {
  // Presets: (label, minutes)
  final presets = employmentType == 'Comando'
      ? [(AppStrings.orarioPreset712, 432), (AppStrings.orarioPreset612, 372)]
      : [(AppStrings.orarioPreset736, 456), (AppStrings.orarioPreset640, 400)];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      int selected = currentMins;
      return StatefulBuilder(
        builder: (ctx2, setState) {
          return _EditSheet(
            isDark: isDark,
            title: AppStrings.orarioPresetTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (int i = 0; i < presets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selected = presets[i].$2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: selected == presets[i].$2
                                  ? AppColors.blue600.withValues(alpha: 0.12)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected == presets[i].$2
                                    ? AppColors.blue600
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  presets[i].$1,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: selected == presets[i].$2
                                        ? AppColors.blue600
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.7,
                                                )
                                              : AppColors.neutral700),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ore/giorno',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : AppColors.neutral400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _SaveButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx2);
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileFields({'standardDailyMins': selected});
                    if (ctx2.mounted) nav.pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Integer hours editor with +/- buttons and a slider.
Future<void> _editIntHours(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required int currentValue,
  required int min,
  required int max,
  required String fieldKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _IntHoursSheet(
      title: title,
      initialValue: currentValue,
      min: min,
      max: max,
      onSave: (v) async {
        await ref.read(profileRepositoryProvider).updateProfileFields({
          fieldKey: v,
        });
      },
    ),
  );
}

Future<void> _editWeeklySchedule(
  BuildContext context,
  WidgetRef ref,
  int defaultMins,
  Map<int, int> current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final schedule = <int, int>{
          for (int d = 1; d <= 5; d++) d: current[d] ?? defaultMins,
        };
        final dayNames = AppStrings.weekdaysFull.take(5).toList();
        String fmtMins(int m) {
          if (m == 0) return 'Riposo';
          final h = m ~/ 60;
          final min = m % 60;
          return min == 0
              ? '${h}h'
              : '${h}h ${min.toString().padLeft(2, "0")}m';
        }

        return _EditSheet(
          isDark: isDark,
          title: 'Orario settimanale',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int d = 1; d <= 5; d++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        dayNames[d - 1],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.neutral900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.blue600,
                          thumbColor: AppColors.blue600,
                          inactiveTrackColor: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: schedule[d]!.toDouble(),
                          min: 0,
                          max: 600,
                          divisions: 60,
                          onChanged: (v) =>
                              setState(() => schedule[d] = v.round()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 58,
                      child: Text(
                        fmtMins(schedule[d]!),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
              _SaveButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  await ref.read(profileRepositoryProvider).updateProfileFields(
                    {
                      'weeklyScheduleMins': {
                        for (final e in schedule.entries)
                          e.key.toString(): e.value,
                      },
                    },
                  );
                  if (ctx.mounted) nav.pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Chip selector for employment type.
Future<void> _editGender(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String selected = current;
        final options = [
          (value: 'M', label: '♂ Maschile', color: AppColors.blue600),
          (value: 'F', label: '♀ Femminile', color: AppColors.green600),
          (value: 'A', label: '∅ Altrə', color: AppColors.orange600),
          (value: 'N', label: '⚥ Neutro', color: AppColors.neutral600),
        ];
        return _EditSheet(
          isDark: isDark,
          title: 'Genere (per Chigio)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: options.map((o) {
                  final isSelected = selected == o.value;
                  return GestureDetector(
                    onTap: () => setLocalState(() => selected = o.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 96,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? o.color.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? o.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          o.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? o.color
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppColors.neutral600),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SaveButton(
                onPressed: () async {
                  await ref.read(profileRepositoryProvider).updateProfileFields(
                    {'gender': selected},
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _editEmploymentType(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String selected = current;

        return _EditSheet(
          isDark: isDark,
          title: 'Inquadramento',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Ruolo', 'Comando', 'Altro'].map((t) {
                  final isSelected = selected == t;
                  final color = t == 'Ruolo'
                      ? AppColors.blue600
                      : t == 'Comando'
                      ? AppColors.green600
                      : AppColors.neutral600;
                  return GestureDetector(
                    onTap: () => setLocalState(() => selected = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 96,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppColors.neutral600),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SaveButton(
                onPressed: () async {
                  final fields = <String, dynamic>{'employmentType': selected};
                  // Only overwrite contract defaults when type actually changes
                  // — preserves any custom values the user had previously set.
                  if (selected != current) {
                    if (selected == 'Ruolo') {
                      fields['standardDailyMins'] = 456;
                      fields['mealVoucherThresholdMins'] = 380;
                      fields['monthlyArt9Hours'] = 8;
                    } else if (selected == 'Comando') {
                      fields['standardDailyMins'] = 432;
                      fields['mealVoucherThresholdMins'] = 380;
                      fields['monthlyArt9Hours'] = 17;
                    }
                  }
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfileFields(fields);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _showNotifiche(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NotificationSheet(
      isDark: Theme.of(ctx).brightness == Brightness.dark,
      clockIn: profileData['notifyClockIn'] as bool? ?? false,
      clockOut: profileData['notifyClockOut'] as bool? ?? false,
      weekly: profileData['notifyWeekly'] as bool? ?? false,
      exitNotifMins: profileData['exitNotifMins'] as int? ?? 15,
      onSave: (clockIn, clockOut, weekly, exitNotifMins) async {
        await ref.read(profileRepositoryProvider).updateProfileFields({
          'notifyClockIn': clockIn,
          'notifyClockOut': clockOut,
          'notifyWeekly': weekly,
          'exitNotifMins': exitNotifMins,
        });
      },
    ),
  );
}

void _showPrivacy(BuildContext context, bool isDark) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final textSub = dark
          ? Colors.white.withValues(alpha: 0.55)
          : AppColors.neutral600;
      return _EditSheet(
        isDark: dark,
        title: 'Privacy',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrivacyRow(
              icon: '🔒',
              title: 'Dati al sicuro',
              desc:
                  'Tutti i dati vengono salvati su Firebase con autenticazione sicura e cifrata.',
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '📊',
              title: 'Nessuna condivisione',
              desc:
                  'Chigio Time non condivide i tuoi dati con terze parti né li usa per analytics.',
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '🗑️',
              title: 'Diritto alla cancellazione',
              desc:
                  'Puoi richiedere la cancellazione di tutti i tuoi dati contattando il supporto.',
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blue600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  AppStrings.close,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showCountersCustomizer(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final current =
      (profileData['summaryItems'] as List<dynamic>?)?.cast<String>() ??
      MonthlySummaryCard.defaultItems;
  final showProgress = profileData['summaryShowProgress'] as bool? ?? true;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CountersCustomizerSheet(
      isDark: Theme.of(ctx).brightness == Brightness.dark,
      currentItems: List<String>.from(current),
      showProgress: showProgress,
      onSave: (items, showProg) async {
        await ref.read(profileRepositoryProvider).updateProfileFields({
          'summaryItems': items,
          'summaryShowProgress': showProg,
        });
      },
    ),
  );
}

void _showHighlightWidgetPicker(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final current = profileData['highlightWidget'] as String? ?? 'none';
  const options = [
    (id: 'none', label: AppStrings.highlightWidgetNone, icon: '—'),
    (id: 'bankHours', label: AppStrings.highlightBankHours, icon: '🏦'),
    (id: 'overtime', label: AppStrings.highlightOvertime, icon: '⏱️'),
    (id: 'mealCount', label: AppStrings.highlightMealCount, icon: '🍽️'),
  ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String sel = current;
        return StatefulBuilder(
          builder: (ctx2, setInner) {
            return _EditSheet(
              isDark: isDark,
              title: AppStrings.highlightWidget,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...options.map((o) {
                    final active = sel == o.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setInner(() => sel = o.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.blue600.withValues(alpha: 0.10)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? AppColors.blue600.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                o.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  o.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? AppColors.blue600
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.85,
                                                )
                                              : AppColors.neutral900),
                                  ),
                                ),
                              ),
                              if (active)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.blue600,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _SaveButton(
                    onPressed: () async {
                      final nav = Navigator.of(ctx2);
                      await ref
                          .read(profileRepositoryProvider)
                          .updateProfileFields({'highlightWidget': sel});
                      if (ctx2.mounted) nav.pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

void _showNavViewsVisibilityPicker(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final hidden = Set<String>.from(
    (profileData['hiddenNavViews'] as List?)?.cast<String>() ?? const [],
  );
  const options = [
    (id: 'home', label: AppStrings.navViewHome, icon: '🏠'),
    (id: 'timesheet', label: AppStrings.navViewTimesheet, icon: '🗓️'),
    (id: 'social', label: AppStrings.navViewSocial, icon: '👥'),
  ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (ctx2, setInner) {
          return _EditSheet(
            isDark: isDark,
            title: AppStrings.navViewsVisibility,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.navViewsVisibilityHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((o) {
                  final visible = !hidden.contains(o.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(o.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              o.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.neutral900,
                              ),
                            ),
                          ),
                          Switch(
                            value: visible,
                            onChanged: (v) {
                              if (!v && hidden.length == options.length - 1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      AppStrings.navViewsAtLeastOne,
                                    ),
                                  ),
                                );
                                return;
                              }
                              setInner(() {
                                if (v) {
                                  hidden.remove(o.id);
                                } else {
                                  hidden.add(o.id);
                                }
                              });
                            },
                            activeThumbColor: AppColors.blue600,
                            activeTrackColor: AppColors.blue600.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _SaveButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx2);
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileFields({
                          'hiddenNavViews': hidden.toList(),
                        });
                    if (ctx2.mounted) nav.pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void showPortaleEdit(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profile,
) {
  final existing = profile['portaleJson'];
  final current = existing is Map
      ? Map<String, dynamic>.from(existing)
      : <String, dynamic>{};
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PortaleEditSheet(
      current: current,
      onSave: (data) =>
          ref.read(profileRepositoryProvider).savePortaleData(data),
    ),
  );
}

// ── Portale edit sheet ───────────────────────────────────────────────────────

class _PortaleEditSheet extends StatefulWidget {
  final Map<String, dynamic> current;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _PortaleEditSheet({required this.current, required this.onSave});

  @override
  State<_PortaleEditSheet> createState() => _PortaleEditSheetState();
}

class _PortaleEditSheetState extends State<_PortaleEditSheet> {
  bool _saving = false;

  late final _dipendente = TextEditingController(
    text: widget.current['dipendente'] as String? ?? '',
  );
  late final _matricola = TextEditingController(
    text: widget.current['matricola'] as String? ?? '',
  );
  late final _periodo = TextEditingController(
    text: widget.current['periodo'] as String? ?? '',
  );
  late final _fetchedAt = TextEditingController(
    text: widget.current['fetched_at'] as String? ?? '',
  );

  String _str(String key) => widget.current[key] as String? ?? '00:00';
  String _dbl(String key) => (widget.current[key] as num? ?? 0).toString();
  String _int(String key) => (widget.current[key] as int? ?? 0).toString();

  late final _ferieFruitoAnnuo = TextEditingController(
    text: _dbl('ferie_fruito_annuo'),
  );
  late final _ferieSpettanza = TextEditingController(
    text: _dbl('ferie_spettanza'),
  );
  late final _ferieResAc = TextEditingController(
    text: _dbl('ferie_residuo_anno_corrente'),
  );
  late final _ferieResAp = TextEditingController(
    text: _dbl('ferie_residuo_anno_precedente'),
  );
  late final _festFruitoAnnuo = TextEditingController(
    text: _dbl('fest_sopp_fruito_annuo'),
  );
  late final _festSpettanza = TextEditingController(
    text: _dbl('fest_sopp_spettanza'),
  );
  late final _festResiduo = TextEditingController(
    text: _dbl('fest_sopp_residuo'),
  );
  late final _art9Effettuate = TextEditingController(
    text: _str('protrazioni_art9_effettuate'),
  );
  late final _art9DaRecuperare = TextEditingController(
    text: _str('protrazioni_art9_da_recuperare'),
  );
  late final _maggiorPresenza = TextEditingController(
    text: _str('maggior_presenza'),
  );
  late final _straordLiquidati = TextEditingController(
    text: _str('straordinari_liquidati'),
  );
  late final _straordAutorizzato = TextEditingController(
    text: _str('straordinario_autorizzato'),
  );
  late final _straordLiquidabili = TextEditingController(
    text: _str('straordinari_liquidabili'),
  );
  late final _riposoCompMaturato = TextEditingController(
    text: _str('riposo_comp_maturato'),
  );
  late final _riposoCompResiduo = TextEditingController(
    text: _str('riposo_comp_residuo'),
  );
  late final _bancaOreAc = TextEditingController(
    text: _str('banca_ore_ac_residuo'),
  );
  late final _bancaOreAp = TextEditingController(
    text: _str('banca_ore_ap_residuo'),
  );
  late final _bancaTotale = TextEditingController(
    text: _str('totale_banca_ore_fruibile'),
  );
  late final _orePerse = TextEditingController(text: _str('ore_perse'));
  late final _permBreve = TextEditingController(
    text: _str('permesso_breve_residuo'),
  );
  late final _permPersonali = TextEditingController(
    text: _str('perm_motivi_personali_residuo'),
  );
  late final _visitaSpec = TextEditingController(
    text: _str('visita_specialistica_residuo'),
  );
  late final _buoniPasto = TextEditingController(
    text: _int('buoni_pasto_mensili'),
  );
  late final _oreNonRecuperate = TextEditingController(
    text: _str('ore_non_recuperate'),
  );

  @override
  void dispose() {
    for (final c in [
      _dipendente,
      _matricola,
      _periodo,
      _fetchedAt,
      _ferieFruitoAnnuo,
      _ferieSpettanza,
      _ferieResAc,
      _ferieResAp,
      _festFruitoAnnuo,
      _festSpettanza,
      _festResiduo,
      _art9Effettuate,
      _art9DaRecuperare,
      _maggiorPresenza,
      _straordLiquidati,
      _straordAutorizzato,
      _straordLiquidabili,
      _riposoCompMaturato,
      _riposoCompResiduo,
      _bancaOreAc,
      _bancaOreAp,
      _bancaTotale,
      _orePerse,
      _permBreve,
      _permPersonali,
      _visitaSpec,
      _buoniPasto,
      _oreNonRecuperate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'dipendente': _dipendente.text.trim(),
        'matricola': _matricola.text.trim(),
        'periodo': _periodo.text.trim(),
        'fetched_at': _fetchedAt.text.trim(),
        'ferie_fruito_mese': 0,
        'ferie_fruito_annuo': double.tryParse(_ferieFruitoAnnuo.text) ?? 0,
        'ferie_spettanza': double.tryParse(_ferieSpettanza.text) ?? 0,
        'ferie_residuo_anno_corrente': double.tryParse(_ferieResAc.text) ?? 0,
        'ferie_residuo_anno_precedente': double.tryParse(_ferieResAp.text) ?? 0,
        'ferie_residue_totali':
            (double.tryParse(_ferieResAc.text) ?? 0) +
            (double.tryParse(_ferieResAp.text) ?? 0),
        'fest_sopp_fruito_annuo': double.tryParse(_festFruitoAnnuo.text) ?? 0,
        'fest_sopp_spettanza': double.tryParse(_festSpettanza.text) ?? 0,
        'fest_sopp_residuo': double.tryParse(_festResiduo.text) ?? 0,
        'protrazioni_art9_effettuate': _art9Effettuate.text.trim(),
        'protrazioni_art9_da_recuperare': _art9DaRecuperare.text.trim(),
        'maggior_presenza': _maggiorPresenza.text.trim(),
        'straordinari_liquidati': _straordLiquidati.text.trim(),
        'straordinario_autorizzato': _straordAutorizzato.text.trim(),
        'straordinari_liquidabili': _straordLiquidabili.text.trim(),
        'riposo_comp_maturato': _riposoCompMaturato.text.trim(),
        'riposo_comp_residuo': _riposoCompResiduo.text.trim(),
        'banca_ore_ac_residuo': _bancaOreAc.text.trim(),
        'banca_ore_ap_residuo': _bancaOreAp.text.trim(),
        'totale_banca_ore_fruibile': _bancaTotale.text.trim(),
        'ore_perse': _orePerse.text.trim(),
        'permesso_breve_residuo': _permBreve.text.trim(),
        'perm_motivi_personali_residuo': _permPersonali.text.trim(),
        'visita_specialistica_residuo': _visitaSpec.text.trim(),
        'buoni_pasto_mensili': int.tryParse(_buoniPasto.text) ?? 0,
        'ore_non_recuperate': _oreNonRecuperate.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String label, {required bool isDark}) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark
            ? Colors.white.withValues(alpha: 0.4)
            : AppColors.neutral400,
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: type,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.neutral900,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final bg = isDark ? const Color(0xFF0b1028) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title + save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    AppStrings.portaleData,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.save,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _section('IDENTIFICATIVO', isDark: isDark),
                  _field('Nominativo', _dipendente, isDark: isDark),
                  _field(
                    'Matricola',
                    _matricola,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field('Periodo (es. Maggio 2026)', _periodo, isDark: isDark),
                  _field(
                    'Data aggiornamento (DD/MM/YYYY)',
                    _fetchedAt,
                    isDark: isDark,
                  ),

                  _section('FERIE (giorni)', isDark: isDark),
                  _field(
                    'Fruito annuo',
                    _ferieFruitoAnnuo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    'Spettanza',
                    _ferieSpettanza,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    'Residuo anno corrente',
                    _ferieResAc,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    'Residuo anno precedente',
                    _ferieResAp,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),

                  _section('FESTIVITÀ SOPPRESSE (giorni)', isDark: isDark),
                  _field(
                    'Fruito annuo',
                    _festFruitoAnnuo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    'Spettanza',
                    _festSpettanza,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    'Residuo',
                    _festResiduo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),

                  _section('STRAORDINARI (HH:MM)', isDark: isDark),
                  _field('Art.9 effettuate', _art9Effettuate, isDark: isDark),
                  _field(
                    'Art.9 da recuperare',
                    _art9DaRecuperare,
                    isDark: isDark,
                  ),
                  _field('Maggior presenza', _maggiorPresenza, isDark: isDark),
                  _field('Liquidati', _straordLiquidati, isDark: isDark),
                  _field('Autorizzati', _straordAutorizzato, isDark: isDark),
                  _field('Liquidabili', _straordLiquidabili, isDark: isDark),
                  _field(
                    'Riposo comp. maturato',
                    _riposoCompMaturato,
                    isDark: isDark,
                  ),
                  _field(
                    'Riposo comp. residuo',
                    _riposoCompResiduo,
                    isDark: isDark,
                  ),

                  _section('BANCA ORE (HH:MM)', isDark: isDark),
                  _field('Residuo anno corrente', _bancaOreAc, isDark: isDark),
                  _field(
                    'Residuo anno precedente',
                    _bancaOreAp,
                    isDark: isDark,
                  ),
                  _field('Totale fruibile', _bancaTotale, isDark: isDark),

                  _section('PERMESSI (HH:MM)', isDark: isDark),
                  _field('Permesso breve residuo', _permBreve, isDark: isDark),
                  _field(
                    'Motivi personali residuo',
                    _permPersonali,
                    isDark: isDark,
                  ),
                  _field(
                    'Visita specialistica residuo',
                    _visitaSpec,
                    isDark: isDark,
                  ),
                  _field('Ore perse', _orePerse, isDark: isDark),
                  _field(
                    'Ore non recuperate',
                    _oreNonRecuperate,
                    isDark: isDark,
                  ),

                  _section('BUONI PASTO', isDark: isDark),
                  _field(
                    'Buoni mensili',
                    _buoniPasto,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAppInfo(BuildContext context, bool isDark) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0b1028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        AppStrings.appName,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'App di time tracking per dipendenti pubblici '
        '(CCNL settore pubblico).\n\n'
        'Sviluppata da Marco Cipriani.',
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.65)
              : AppColors.neutral700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.ok),
        ),
      ],
    ),
  );
}

void _showCcnlReader(BuildContext context, bool isDark) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _CcnlReaderSheet(isDark: isDark),
    ),
  );
}

Future<List<_CcnlDoc>>? _ccnlDocsFuture;

Future<List<_CcnlDoc>> _loadCcnlDocs() {
  return _ccnlDocsFuture ??= Future.wait([
    _loadCcnlDoc(
      id: '2019-2021',
      label: 'Nuovo',
      title: 'CCNL PCM 2019-2021',
      subtitle: 'Sottoscritto il 28 ottobre 2025',
      assetPath: 'docs/ccnl/ccnl-pcm-2019-2021.md',
    ),
    _loadCcnlDoc(
      id: '2016-2018',
      label: 'Precedente',
      title: 'CCNL PCM 2016-2018',
      subtitle: 'CCNL del 7 ottobre 2022',
      assetPath: 'docs/ccnl/ccnl-pcm-2016-2018.md',
    ),
  ]);
}

Future<_CcnlDoc> _loadCcnlDoc({
  required String id,
  required String label,
  required String title,
  required String subtitle,
  required String assetPath,
}) async {
  final raw = await rootBundle.loadString(assetPath);
  final content = raw.replaceAll('\r\n', '\n');
  return _parseCcnlDoc(
    id: id,
    label: label,
    title: title,
    subtitle: subtitle,
    assetPath: assetPath,
    content: content,
  );
}

_CcnlDoc _parseCcnlDoc({
  required String id,
  required String label,
  required String title,
  required String subtitle,
  required String assetPath,
  required String content,
}) {
  final articleMatches = RegExp(
    r'^Art\.\s+(\d+)\s*$',
    multiLine: true,
  ).allMatches(content).toList();

  final preamble = articleMatches.isEmpty
      ? content.trim()
      : content.substring(0, articleMatches.first.start).trim();
  final articles = <_CcnlArticle>[];

  for (var i = 0; i < articleMatches.length; i++) {
    final match = articleMatches[i];
    final number = int.tryParse(match.group(1) ?? '') ?? 0;
    final end = i + 1 < articleMatches.length
        ? articleMatches[i + 1].start
        : content.length;
    final section = content.substring(match.start, end).trim();
    final lines = section.split('\n');
    final titleLines = <String>[];

    for (final rawLine in lines.skip(1)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\d+\.').hasMatch(line)) break;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (line.startsWith('CCNL ')) continue;
      if (line.startsWith('TITOLO ')) break;
      if (line.startsWith('Capo ')) break;
      titleLines.add(line);
      if (titleLines.length == 3) break;
    }

    articles.add(
      _CcnlArticle(
        number: number,
        title: titleLines.isEmpty ? 'Articolo $number' : titleLines.join(' '),
        text: section,
      ),
    );
  }

  return _CcnlDoc(
    id: id,
    label: label,
    title: title,
    subtitle: subtitle,
    assetPath: assetPath,
    preamble: preamble,
    articles: articles,
  );
}

// ── Reusable sheet wrapper ───────────────────────────────────────────────

class _EditSheet extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _EditSheet({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10102A).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
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
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _SaveButton({required this.onPressed});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onPressed();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                AppStrings.save,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

// ── Int hours sheet widget ───────────────────────────────────────────────

class _IntHoursSheet extends StatefulWidget {
  final String title;
  final int initialValue;
  final int min;
  final int max;
  final Future<void> Function(int) onSave;

  const _IntHoursSheet({
    required this.title,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.onSave,
  });

  @override
  State<_IntHoursSheet> createState() => _IntHoursSheetState();
}

class _IntHoursSheetState extends State<_IntHoursSheet> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _EditSheet(
      isDark: isDark,
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlusMinus(
                icon: Icons.remove_rounded,
                onTap: _value > widget.min
                    ? () => setState(() => _value--)
                    : null,
                isDark: isDark,
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  Text(
                    '$_value',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue600,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    'ore/mese',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : AppColors.neutral600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              _PlusMinus(
                icon: Icons.add_rounded,
                onTap: _value < widget.max
                    ? () => setState(() => _value++)
                    : null,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.blue600,
              thumbColor: AppColors.blue600,
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _value.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
              onChanged: (v) => setState(() => _value = v.round()),
            ),
          ),
          const SizedBox(height: 8),
          _SaveButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await widget.onSave(_value);
              if (mounted) nav.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _PlusMinus extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _PlusMinus({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.blue600.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Icon(
          icon,
          size: 24,
          color: enabled
              ? AppColors.blue600
              : (isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.neutral300),
        ),
      ),
    );
  }
}

// ── Slider sheet widget ──────────────────────────────────────────────────

class _SliderSheet extends StatefulWidget {
  final String title;
  final String icon;
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final String fieldKey;
  final String Function(double) formatValue;
  final Future<void> Function(double) onSave;

  const _SliderSheet({
    required this.title,
    required this.icon,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.fieldKey,
    required this.formatValue,
    required this.onSave,
  });

  @override
  State<_SliderSheet> createState() => _SliderSheetState();
}

class _SliderSheetState extends State<_SliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _EditSheet(
      isDark: isDark,
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              widget.formatValue(_value),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.blue600,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.blue600,
              thumbColor: AppColors.blue600,
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _value,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (v) => setState(() => _value = v),
            ),
          ),
          const SizedBox(height: 8),
          _SaveButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await widget.onSave(_value);
              if (mounted) nav.pop();
            },
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.blue600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.45)
                : AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isDark;
  final bool divider;
  final VoidCallback? onEdit;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.divider,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.neutral600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String icon;
  final String label;
  final Widget trailing;
  final bool isDark;
  final bool divider;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.isDark,
    required this.divider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode current;
  final bool isAutoByTime;
  final void Function(ThemeMode) onSelect;
  final VoidCallback onAutoByTime;
  final bool isDark;

  const _ThemePicker({
    required this.current,
    required this.isAutoByTime,
    required this.onSelect,
    required this.onAutoByTime,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeBtn(
          label: '☀️',
          tooltip: 'Chiaro',
          active: !isAutoByTime && current == ThemeMode.light,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.light),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '🌙',
          tooltip: 'Scuro',
          active: !isAutoByTime && current == ThemeMode.dark,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.dark),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '📱',
          tooltip: 'Sistema',
          active: !isAutoByTime && current == ThemeMode.system,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.system),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '⏰',
          tooltip: 'Auto (18:00)',
          active: isAutoByTime,
          isDark: isDark,
          onTap: onAutoByTime,
        ),
      ],
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeBtn({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active
              ? AppColors.blue600.withValues(alpha: 0.85)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
          border: Border.all(
            color: active
                ? AppColors.blue600
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 14))),
      ),
    );
  }
}

// ── Phone row (existing + edit button) ──────────────────────────────────

Future<void> _editPhone(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  final ctrl = TextEditingController(text: current);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF10102A).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
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
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.phoneNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.neutral900,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.phonePlaceholder,
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.neutral400,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: AppColors.blue600,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SaveButton(
                    onPressed: () async {
                      await ref
                          .read(profileRepositoryProvider)
                          .updatePhoneNumber(ctrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  ctrl.dispose();
}

class _PhoneRow extends StatelessWidget {
  final String? phone;
  final bool isDark;
  final VoidCallback onEdit;

  const _PhoneRow({
    required this.phone,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Text('📱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.phone,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      phone != null && phone!.isNotEmpty ? phone! : '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.neutral600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          indent: 18,
          endIndent: 18,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue600,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Counters customizer sheet ────────────────────────────────────────────────

const _kAllItems = ['art9', 'sli', 'sbo', 'op'];

String _itemLabel(String id) => switch (id) {
  'art9' => 'Art.9 — Estensione orario mensile',
  'sli' => 'SLI — Straord. liquidato',
  'sbo' => 'SBO — Straord. banca ore',
  'op' => 'OP — Ore perse',
  _ => id,
};

Color _itemColor(String id) => switch (id) {
  'art9' => AppColors.blue600,
  'sli' => AppColors.green600,
  'sbo' => AppColors.orange500,
  'op' => AppColors.red700,
  _ => AppColors.neutral600,
};

class _CountersCustomizerSheet extends StatefulWidget {
  final bool isDark;
  final List<String> currentItems;
  final bool showProgress;
  final Future<void> Function(List<String>, bool) onSave;

  const _CountersCustomizerSheet({
    required this.isDark,
    required this.currentItems,
    required this.showProgress,
    required this.onSave,
  });

  @override
  State<_CountersCustomizerSheet> createState() =>
      _CountersCustomizerSheetState();
}

class _CountersCustomizerSheetState extends State<_CountersCustomizerSheet> {
  late Set<String> _selected;
  late bool _showProgress;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.currentItems);
    _showProgress = widget.showProgress;
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

    return _EditSheet(
      isDark: isDark,
      title: 'Widget contatori',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.visibleVoices,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSub,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ..._kAllItems.map((id) {
            final active = _selected.contains(id);
            final color = _itemColor(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() {
                  if (active) {
                    _selected.remove(id);
                  } else {
                    _selected.add(id);
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? color.withValues(alpha: 0.10)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? color.withValues(alpha: 0.35)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _itemLabel(id),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? color : textMain,
                          ),
                        ),
                      ),
                      if (active)
                        Icon(Icons.check_rounded, size: 16, color: color),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mostra barre di avanzamento',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                ),
                Switch(
                  value: _showProgress,
                  onChanged: (v) => setState(() => _showProgress = v),
                  activeThumbColor: AppColors.blue600,
                  activeTrackColor: AppColors.blue600.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _selected = Set<String>.from(
                      MonthlySummaryCard.defaultItems,
                    );
                    _showProgress = true;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral600,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ripristina default',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SaveButton(
                  onPressed: () async {
                    final ordered = _kAllItems
                        .where(_selected.contains)
                        .toList();
                    final nav = Navigator.of(context);
                    await widget.onSave(ordered, _showProgress);
                    if (mounted) nav.pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notification preferences sheet ──────────────────────────────────────────

class _NotificationSheet extends StatefulWidget {
  final bool isDark;
  final bool clockIn;
  final bool clockOut;
  final bool weekly;
  final int exitNotifMins;
  final Future<void> Function(bool, bool, bool, int) onSave;

  const _NotificationSheet({
    required this.isDark,
    required this.clockIn,
    required this.clockOut,
    required this.weekly,
    required this.exitNotifMins,
    required this.onSave,
  });

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  late bool _clockIn;
  late bool _clockOut;
  late bool _weekly;
  late int _exitNotifMins;

  static const _exitOptions = [0, 5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _clockIn = widget.clockIn;
    _clockOut = widget.clockOut;
    _weekly = widget.weekly;
    _exitNotifMins = widget.exitNotifMins;
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

    return _EditSheet(
      isDark: isDark,
      title: 'Notifiche',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotifToggle(
            icon: '🟢',
            label: 'Promemoria timbratura entrata',
            value: _clockIn,
            isDark: isDark,
            onChanged: (v) => setState(() => _clockIn = v),
          ),
          const SizedBox(height: 8),
          _NotifToggle(
            icon: '🔴',
            label: 'Promemoria timbratura uscita',
            value: _clockOut,
            isDark: isDark,
            onChanged: (v) => setState(() => _clockOut = v),
          ),
          const SizedBox(height: 8),
          _NotifToggle(
            icon: '📊',
            label: 'Report settimanale',
            value: _weekly,
            isDark: isDark,
            onChanged: (v) => setState(() => _weekly = v),
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
                        'Notifica push uscita prevista',
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
                    final label = mins == 0 ? 'Off' : '$mins min';
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
          const SizedBox(height: 20),
          _SaveButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await widget.onSave(_clockIn, _clockOut, _weekly, _exitNotifMins);
              if (mounted) nav.pop();
            },
          ),
        ],
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

// ── CCNL reader ──────────────────────────────────────────────────────────────

class _CcnlDoc {
  final String id;
  final String label;
  final String title;
  final String subtitle;
  final String assetPath;
  final String preamble;
  final List<_CcnlArticle> articles;

  const _CcnlDoc({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.preamble,
    required this.articles,
  });
}

class _CcnlArticle {
  final int number;
  final String title;
  final String text;
  final GlobalKey key;

  _CcnlArticle({required this.number, required this.title, required this.text})
    : key = GlobalKey(debugLabel: 'ccnl_art_$number');
}

class _CcnlProfileCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpen;

  const _CcnlProfileCard({required this.isDark, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : AppColors.neutral600;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(
                    alpha: isDark ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blue600.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 21,
                  color: AppColors.blue600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CCNL PCM',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nuovo 2019-2021 e precedente 2016-2018',
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Apri CCNL',
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded, size: 19),
                color: AppColors.blue600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CcnlSmallTag(label: 'Nuovo', value: '2019-2021', isDark: isDark),
              _CcnlSmallTag(
                label: 'Precedente',
                value: '2016-2018',
                isDark: isDark,
              ),
              _CcnlSmallTag(label: 'Indice', value: 'articoli', isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.025),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 17,
                    color: AppColors.blue600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Leggi il contratto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CcnlSmallTag extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _CcnlSmallTag({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.neutral600,
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CcnlReaderSheet extends StatefulWidget {
  final bool isDark;

  const _CcnlReaderSheet({required this.isDark});

  @override
  State<_CcnlReaderSheet> createState() => _CcnlReaderSheetState();
}

class _CcnlReaderSheetState extends State<_CcnlReaderSheet> {
  final _scrollController = ScrollController();
  int _selected = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectDoc(int index) {
    if (_selected == index) return;
    setState(() => _selected = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _openIndex(_CcnlDoc doc) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.74,
        child: _CcnlIndexSheet(
          doc: doc,
          isDark: widget.isDark,
          onSelect: (article) {
            Navigator.pop(context);
            Future<void>.delayed(const Duration(milliseconds: 80), () {
              if (!mounted) return;
              final articleContext = article.key.currentContext;
              if (articleContext == null) return;
              if (!articleContext.mounted) return;
              Scrollable.ensureVisible(
                articleContext,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                alignment: 0.04,
              );
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? const Color(0xFF10102A).withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.98);
    final textMain = widget.isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = widget.isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.neutral600;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: FutureBuilder<List<_CcnlDoc>>(
            future: _loadCcnlDocs(),
            builder: (context, snap) {
              final docs = snap.data;
              final hasDocs = docs != null && docs.isNotEmpty;
              final selectedIndex = hasDocs
                  ? _selected.clamp(0, docs.length - 1)
                  : 0;
              final doc = hasDocs ? docs[selectedIndex] : null;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CCNL PCM',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doc?.subtitle ?? 'Caricamento contratti',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Indice articoli',
                              onPressed: doc == null
                                  ? null
                                  : () => _openIndex(doc),
                              icon: const Icon(
                                Icons.format_list_bulleted_rounded,
                              ),
                              color: AppColors.blue600,
                            ),
                            IconButton(
                              tooltip: AppStrings.close,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              color: textSub,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasDocs)
                          _CcnlDocSwitch(
                            docs: docs,
                            selected: _selected,
                            isDark: widget.isDark,
                            onSelect: _selectDoc,
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: snap.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : snap.hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Impossibile caricare il CCNL.',
                                style: TextStyle(color: textSub),
                              ),
                            ),
                          )
                        : doc == null
                        ? Center(
                            child: Text(
                              'Nessun contratto disponibile.',
                              style: TextStyle(color: textSub),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CcnlDocIntro(doc: doc, isDark: widget.isDark),
                                if (doc.preamble.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _CcnlPreambleBlock(
                                    text: doc.preamble,
                                    isDark: widget.isDark,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                ...doc.articles.map(
                                  (article) => _CcnlArticleBlock(
                                    article: article,
                                    isDark: widget.isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CcnlDocSwitch extends StatelessWidget {
  final List<_CcnlDoc> docs;
  final int selected;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _CcnlDocSwitch({
    required this.docs,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(docs.length, (i) {
        final doc = docs[i];
        final active = i == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == docs.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.blue600
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.035)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? AppColors.blue600
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white.withValues(alpha: 0.78)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.52)
                                  : AppColors.neutral600),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      doc.id,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? Colors.white
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : AppColors.neutral900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CcnlDocIntro extends StatelessWidget {
  final _CcnlDoc doc;
  final bool isDark;

  const _CcnlDocIntro({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.52)
        : AppColors.neutral600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 20,
            color: AppColors.blue600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.articles.length} articoli',
                  style: TextStyle(fontSize: 11, color: textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CcnlPreambleBlock extends StatelessWidget {
  final String text;
  final bool isDark;

  const _CcnlPreambleBlock({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.neutral800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: textMain,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _CcnlArticleBlock extends StatelessWidget {
  final _CcnlArticle article;
  final bool isDark;

  const _CcnlArticleBlock({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.neutral900;
    final textBody = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : AppColors.neutral800;

    return Container(
      key: article.key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue600.withValues(
                    alpha: isDark ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Art. ${article.number}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.blue600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            article.text,
            style: TextStyle(
              fontSize: 12,
              height: 1.46,
              color: textBody,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _CcnlIndexSheet extends StatelessWidget {
  final _CcnlDoc doc;
  final bool isDark;
  final ValueChanged<_CcnlArticle> onSelect;

  const _CcnlIndexSheet({
    required this.doc,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.neutral600;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Indice articoli',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.title,
                                style: TextStyle(fontSize: 12, color: textSub),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.close,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: textSub,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
                  itemCount: doc.articles.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 52,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (context, i) {
                    final article = doc.articles[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      leading: Container(
                        width: 36,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withValues(
                            alpha: isDark ? 0.18 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${article.number}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                      title: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: textSub,
                      ),
                      onTap: () => onSelect(article),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Download banner ──────────────────────────────────────────────────────────

class _DownloadBanner extends StatelessWidget {
  final bool isDark;
  const _DownloadBanner({required this.isDark});

  static const _androidUrl = '${AppStrings.webBaseUrl}/android/install.html';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.downloadApp,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.neutral700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _DownloadBtn(
            icon: '🤖',
            label: 'Android',
            sublabel: 'APK ${AppStrings.appVersion}',
            color: const Color(0xFF34A853),
            onTap: () => _open(_androidUrl),
          ),
          const SizedBox(height: 8),
          _DownloadBtn(
            icon: '',
            label: 'iOS',
            sublabel: AppStrings.comingSoon,
            color: textSub,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _DownloadBtn extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback? onTap;

  const _DownloadBtn({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: isDark ? 0.12 : 0.08)
                : Colors.transparent,
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.35)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? color
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppColors.neutral400),
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── OT trend bar chart card ──────────────────────────────────────────────────

class _OtTrendCard extends StatelessWidget {
  final List<({({int year, int month}) ym, int otMins, int presenceDays})> data;
  final bool isDark;
  final List<String> monthsShort;

  const _OtTrendCard({
    required this.data,
    required this.isDark,
    required this.monthsShort,
  });

  @override
  Widget build(BuildContext context) {
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF9CA3AF);
    final maxOt = data
        .map((d) => d.otMins)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STRAORDINARI — ultimi 6 mesi',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textSub,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxOt / 60.0) + 0.5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final mins = data[groupIndex].otMins;
                      if (mins == 0) return null;
                      return BarTooltipItem(
                        '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final m = data[idx].ym.month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            monthsShort[m - 1],
                            style: TextStyle(fontSize: 9, color: textSub),
                          ),
                        );
                      },
                      reservedSize: 18,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final otH = data[i].otMins / 60.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: otH,
                        gradient: LinearGradient(
                          colors: otH > 0
                              ? [
                                  const Color(0xFFF97316),
                                  const Color(0xFFEA580C),
                                ]
                              : [Colors.transparent, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Straordinario (ore)',
                style: TextStyle(fontSize: 9, color: textSub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Privacy info row ─────────────────────────────────────────────────────────

class _PrivacyRow extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final Color textSub;
  final bool isDark;

  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.textSub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11, color: textSub)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Language picker ──────────────────────────────────────────────────────────

class _LocalePicker extends StatelessWidget {
  final String current;
  final bool isDark;
  final void Function(String) onSelect;

  const _LocalePicker({
    required this.current,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangBtn(
          code: 'it',
          label: '🇮🇹',
          active: current == 'it',
          isDark: isDark,
          onTap: () => onSelect('it'),
        ),
        const SizedBox(width: 4),
        _LangBtn(
          code: 'en',
          label: '🇬🇧',
          active: current == 'en',
          isDark: isDark,
          onTap: () => onSelect('en'),
        ),
      ],
    );
  }
}

// ── GPS settings card ────────────────────────────────────────────────────────

class _GpsSettingsCard extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> profileData;
  final WidgetRef ref;
  final Color textSub;

  const _GpsSettingsCard({
    required this.isDark,
    required this.profileData,
    required this.ref,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final enabled = profileData['gpsAutoClockIn'] as bool? ?? false;
    final lat = profileData['officeLat'] as double?;
    final lng = profileData['officeLng'] as double?;
    final radius =
        (profileData['officeRadiusM'] as num?)?.toDouble() ??
        GeofencingService.defaultRadiusM;

    final coordLabel = lat != null && lng != null
        ? AppStrings.gpsLocationSaved(lat, lng)
        : AppStrings.gpsLocationNotSet;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.gpsAutoClockIn,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      Text(
                        AppStrings.gpsAutoClockInHint,
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) async {
                    if (v && lat == null) {
                      // Must set location first
                      await _showGpsSheet(context);
                    }
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileFields({'gpsAutoClockIn': v});
                  },
                  activeThumbColor: AppColors.blue600,
                  activeTrackColor: AppColors.blue600.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          InkWell(
            onTap: () => _showGpsSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.gpsOfficeLocation,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                        ),
                        Text(
                          coordLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: lat != null ? AppColors.green600 : textMain,
                          ),
                        ),
                        if (lat != null)
                          Text(
                            'Raggio ${radius.toInt()} m',
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGpsSheet(BuildContext context) {
    final lat = profileData['officeLat'] as double?;
    final lng = profileData['officeLng'] as double?;
    final radius =
        (profileData['officeRadiusM'] as num?)?.toDouble() ??
        GeofencingService.defaultRadiusM;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GpsSettingsSheet(
        isDark: isDark,
        currentLat: lat,
        currentLng: lng,
        currentRadius: radius,
        onSave: (lat, lng, r) async {
          await ref.read(profileRepositoryProvider).updateProfileFields({
            'officeLat': lat,
            'officeLng': lng,
            'officeRadiusM': r,
          });
        },
      ),
    );
  }
}

class _GpsSettingsSheet extends StatefulWidget {
  final bool isDark;
  final double? currentLat;
  final double? currentLng;
  final double currentRadius;
  final Future<void> Function(double lat, double lng, double radius) onSave;

  const _GpsSettingsSheet({
    required this.isDark,
    required this.currentLat,
    required this.currentLng,
    required this.currentRadius,
    required this.onSave,
  });

  @override
  State<_GpsSettingsSheet> createState() => _GpsSettingsSheetState();
}

class _GpsSettingsSheetState extends State<_GpsSettingsSheet> {
  bool _loading = false;
  double? _lat;
  double? _lng;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _lat = widget.currentLat;
    _lng = widget.currentLng;
    _radius = widget.currentRadius;
  }

  Future<void> _useCurrentPosition() async {
    setState(() => _loading = true);
    final pos = await GeofencingService.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.gpsPermissionDenied)),
      );
    } else {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
    setState(() => _loading = false);
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

    return _EditSheet(
      isDark: isDark,
      title: AppStrings.gpsOfficeLocation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current coords display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _lat != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.gpsLocationSaved(_lat!, _lng!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppStrings.gpsRadius}: ${_radius.toInt()} m',
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                    ],
                  )
                : Text(
                    AppStrings.gpsLocationNotSet,
                    style: TextStyle(fontSize: 13, color: textSub),
                  ),
          ),
          const SizedBox(height: 14),

          // "Use current position" button
          OutlinedButton.icon(
            onPressed: _loading ? null : _useCurrentPosition,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(AppStrings.gpsSetFromHere),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue600,
              side: const BorderSide(color: AppColors.blue600),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Radius slider
          Text(
            '${AppStrings.gpsRadius}: ${_radius.toInt()} m',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.blue600,
              thumbColor: AppColors.blue600,
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _radius,
              min: 50,
              max: 500,
              divisions: 9,
              label: '${_radius.toInt()} m',
              onChanged: (v) => setState(() => _radius = v),
            ),
          ),
          const SizedBox(height: 16),

          _SaveButton(
            onPressed: () async {
              if (_lat == null || _lng == null) return;
              final nav = Navigator.of(context);
              await widget.onSave(_lat!, _lng!, _radius);
              if (mounted) nav.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String code;
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _LangBtn({
    required this.code,
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active
              ? AppColors.blue600.withValues(alpha: 0.85)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
