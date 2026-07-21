import 'dart:convert' show jsonEncode, utf8;
import 'dart:io';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_repository.dart';
import '../domain/monthly_sau.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_tile.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../app/theme/color_schemes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/pcm_catalog.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/data/pcm_locations_repository.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../../features/authentication/data/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/geofencing_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/pcm_assignment_form.dart';

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
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

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
                  AppTappable(
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
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: SkeletonList(count: 4),
                ),
                error: (e, _) => ErrorRetry(
                  error: e,
                  onRetry: () => ref.invalidate(userProfileStreamProvider),
                ),
                data: (data) {
                  if (data == null) {
                    return Center(
                      child: Text(
                        AppStrings.errorNoData,
                        style: TextStyle(color: textSub),
                      ),
                    );
                  }

                  final name =
                      data['name'] as String? ??
                      AppStrings.defaultUserNameProfile;
                  final administration =
                      data['administration'] as String? ??
                      AppStrings.appOrgShort;
                  final employmentType =
                      data['employmentType'] as String? ?? '—';
                  // Priorità al photoURL del profilo Firestore (modificabile
                  // dall'utente), fallback sull'account Google/Auth.
                  final photoUrl =
                      data['photoURL'] as String? ??
                      FirebaseAuth.instance.currentUser?.photoURL;

                  final now = DateTime.now();

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
                        .fold<int>(0, (acc, e) => acc + e.extraMins);
                    final presenceDays = entries
                        .where(
                          (e) =>
                              !e.isLeave && !e.isHoliday && e.netWorkedMins > 0,
                        )
                        .length;
                    return (ym: ym, otMins: otMins, presenceDays: presenceDays);
                  }).toList();

                  final isDesktop = MediaQuery.sizeOf(context).width >= 800;

                  Widget content = ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      const _SectionLabel(AppStrings.sectionPersonalCard),

                      // ── Card personale compatta — immagine sx, info dx ──
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                // Immagine (tap → modifica dati personali)
                                AppTappable(
                                  onTap: () => context.push('/profile/edit'),
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.8,
                                                  ),
                                            width: 2.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: photoUrl != null
                                              ? Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      Image.asset(
                                                        'assets/images/avatar-default.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                )
                                              : Image.asset(
                                                  'assets/images/avatar-default.png',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.blue600,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF10102A)
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info a destra (tap → modifica dati personali)
                                Expanded(
                                  child: AppTappable(
                                    onTap: () => context.push('/profile/edit'),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: textMain,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppStrings.employmentAtAdministration(
                                            employmentType,
                                            administration,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: textSub,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _memberSince(
                                            FirebaseAuth.instance.currentUser,
                                          ),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.35,
                                                  )
                                                : AppColors.neutral400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: textSub,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Stato del giorno con scadenza — icona modifica.
                            _StatusDayChip(data: data, isDark: isDark),
                          ],
                        ),
                      ),

                      const _SectionLabel(AppStrings.sectionStatistics),

                      _OtTrendCard(
                        data: last6Data,
                        isDark: isDark,
                        monthsShort: AppStrings.monthsShort,
                      ),

                      const SizedBox(height: 8),
                      AppTappable(
                        onTap: () => context.push('/stats'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            AppStrings.seeAllGraphs,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 11),
                      const _SectionLabel(AppStrings.sectionAppOptions),

                      const SizedBox(height: 11),

                      // ── Impostazioni ──────────────────────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: '🎨',
                              label: AppStrings.theme,
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
                              label: AppStrings.languagePicker,
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
                              label: AppStrings.portaleData,
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
                              icon: '🔔',
                              label: AppStrings.notifications,
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
                              icon: '🕶️',
                              label: AppStrings.privateProfile,
                              isDark: isDark,
                              trailing: Switch.adaptive(
                                value: data['isPrivate'] as bool? ?? false,
                                onChanged: (v) => ref
                                    .read(profileRepositoryProvider)
                                    .updateProfileFields({'isPrivate': v}),
                              ),
                              onTap: null,
                              divider: false,
                            ),
                          ],
                        ),
                      ),

                      // ── Widget e visibilità: sezione dedicata, ogni voce
                      // apre il proprio pannello.
                      const _SectionLabel(AppStrings.widgetsAndVisibility),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: '🏠',
                              label: AppStrings.homeWidgetsVisibility,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () =>
                                  showHomeWidgetsPanel(context, ref, data),
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
                              onTap: () =>
                                  _showNavViewsPanel(context, ref, data),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '✨',
                              label: AppStrings.statHighlightLabel,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () =>
                                  _showStatHighlightPanel(context, ref, data),
                              divider: false,
                            ),
                          ],
                        ),
                      ),

                      const _SectionLabel(AppStrings.sectionFeatures),

                      // ── GPS auto-timbratura (spostata qui, prima di CCNL) ──
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

                      const _SectionLabel(AppStrings.sectionAppInfo),

                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
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
                              icon: '🔒',
                              label: AppStrings.privacy,
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
                              icon: '📦',
                              label: AppStrings.downloadMyData,
                              isDark: isDark,
                              trailing: Icon(
                                Icons.download_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              onTap: () => _downloadMyData(context, ref),
                              divider: true,
                            ),
                            _SettingsRow(
                              icon: '🐢',
                              label: AppStrings.chigio,
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
                        label: AppStrings.logout,
                        variant: GlassBtnVariant.secondary,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.red700,
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final fcm = ref.read(fcmServiceProvider);
                          await signOutAfterFcmCleanup(
                            unregister: () => uid == null
                                ? Future.sync(fcm.deactivate)
                                : fcm.unregister(uid),
                            signOut: ref.read(authRepositoryProvider).signOut,
                          );
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
  return AppStrings.memberSince(created.day, month, created.year);
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
  int? maxLength,
}) async {
  final ctrl = TextEditingController(text: current);
  String? errorText;

  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
                maxLength: maxLength,
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
  bool viaCaps = false,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
        final fields = {fieldKey: v.round()};
        final repo = ref.read(profileRepositoryProvider);
        await (viaCaps
            ? repo.updateCaps(fields)
            : repo.updateProfileFields(fields));
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
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final textMain = isDark
          ? Colors.white.withValues(alpha: 0.9)
          : AppColors.neutral900;
      final textSub = isDark
          ? Colors.white.withValues(alpha: 0.6)
          : AppColors.neutral600;
      return _EditSheet(
        isDark: isDark,
        title: AppStrings.administrationField,
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

Future<void> _editPcmAssignment(
  BuildContext context,
  WidgetRef ref, {
  required String currentStructure,
  required String currentSiteId,
}) async {
  var structureName = currentStructure;
  var siteId = currentSiteId;
  String? errorText;

  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (ctx, sheetRef, _) {
        final catalogAsync = sheetRef.watch(pcmCatalogProvider);
        return catalogAsync.when(
          loading: () => _EditSheet(
            isDark: Theme.of(ctx).brightness == Brightness.dark,
            title: AppStrings.pcmStructure,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _EditSheet(
            isDark: Theme.of(ctx).brightness == Brightness.dark,
            title: AppStrings.pcmStructure,
            child: ErrorRetry(
              error: error,
              onRetry: () => sheetRef.invalidate(pcmCatalogLoadProvider),
            ),
          ),
          data: (catalog) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final sites = pcmSitesFromStructures(catalog.structures);
              PcmSiteOption? selectedSite;
              for (final site in sites) {
                if (site.id == siteId) selectedSite = site;
              }
              final changedStructure =
                  currentStructure.isNotEmpty &&
                  structureName != currentStructure &&
                  selectedSite == null;
              final isDark = Theme.of(ctx).brightness == Brightness.dark;

              return _EditSheet(
                isDark: isDark,
                title: AppStrings.pcmStructure,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PcmAssignmentForm(
                      structures: catalog.structures,
                      structureName: structureName,
                      siteId: siteId,
                      onStructureSelected: (value) {
                        setSheetState(() {
                          if (value != structureName) siteId = '';
                          structureName = value;
                          errorText = null;
                        });
                      },
                      onSiteSelected: (site) {
                        setSheetState(() {
                          siteId = site.id;
                          errorText = null;
                        });
                      },
                    ),
                    if (changedStructure) ...[
                      const SizedBox(height: 10),
                      const Text(
                        AppStrings.pcmSiteRequiredAfterStructureChange,
                        style: TextStyle(
                          color: AppColors.orange700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.red700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SaveButton(
                      enabled: structureName.isNotEmpty && selectedSite != null,
                      onPressed: () async {
                        try {
                          await sheetRef
                              .read(profileRepositoryProvider)
                              .updatePcmAssignment(
                                structureName: structureName,
                                site: selectedSite!,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (error) {
                          setSheetState(
                            () => errorText = AppStrings.errorSave(error),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

/// Preset chips for standard daily hours, employment-type-aware.
/// Preset chips for standard daily hours, employment-type-aware.
Future<void> _editStandardHoursPresets(
  BuildContext context,
  WidgetRef ref,
  String employmentType,
  int currentMins,
) async {
  // Presets: (label, minutes)
  final presets = employmentType == AppStrings.etComando
      ? [(AppStrings.orarioPreset712, 432), (AppStrings.orarioPreset612, 372)]
      : [(AppStrings.orarioPreset736, 456), (AppStrings.orarioPreset640, 400)];

  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
                        child: AppTappable(
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
                                  AppStrings.hoursPerDay,
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
  Map<String, dynamic> Function(int)? extraFields,
  bool viaCaps = false,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _IntHoursSheet(
      title: title,
      initialValue: currentValue,
      min: min,
      max: max,
      onSave: (v) async {
        final fields = <String, dynamic>{fieldKey: v};
        if (extraFields != null) fields.addAll(extraFields(v));
        final repo = ref.read(profileRepositoryProvider);
        await (viaCaps
            ? repo.updateCaps(fields)
            : repo.updateProfileFields(fields));
      },
    ),
  );
}

Future<void> _editGender(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String selected = current;
      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final options = [
            (
              value: 'M',
              label: AppStrings.genderMale,
              color: AppColors.blue600,
            ),
            (
              value: 'F',
              label: AppStrings.genderFemale,
              color: AppColors.green600,
            ),
            (
              value: 'A',
              label: AppStrings.genderOther,
              color: AppColors.orange600,
            ),
          ];
          return _EditSheet(
            isDark: isDark,
            title: AppStrings.genderForChigio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: options.map((o) {
                    final isSelected = selected == o.value;
                    return AppTappable(
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
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileFields({'gender': selected});
                    if (ctx.mounted) Navigator.of(ctx).pop();
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

Future<void> _editEmploymentType(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> data,
) async {
  final current = data['employmentType'] as String? ?? '';
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String selected = current;
      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return _EditSheet(
            isDark: isDark,
            title: AppStrings.employmentType,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [
                        AppStrings.etRuolo,
                        AppStrings.etComando,
                        AppStrings.etAltro,
                      ].map((t) {
                        final isSelected = selected == t;
                        final color = t == AppStrings.etRuolo
                            ? AppColors.blue600
                            : t == AppStrings.etComando
                            ? AppColors.green600
                            : AppColors.neutral600;
                        return AppTappable(
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
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
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
                    if (selected == current) {
                      Navigator.pop(ctx);
                      return;
                    }
                    // New inquadramento = new cap defaults; SLI/SBO and the
                    // weekly-schedule variant carry over (user can adjust).
                    final newCaps = <String, dynamic>{
                      'inquadramento': selected,
                      'standardDailyMins': selected == AppStrings.etRuolo
                          ? 456
                          : selected == AppStrings.etComando
                          ? 432
                          : (data['standardDailyMins'] as int? ?? 456),
                      'mealVoucherThresholdMins': 380,
                      // Art.9 = max dell'inquadramento; 0 per "Altro" (non previsto).
                      'monthlyArt9Hours': selected == AppStrings.etRuolo
                          ? 8
                          : selected == AppStrings.etComando
                          ? 17
                          : 0,
                      'monthlySliHours': data['monthlySliHours'] as int? ?? 0,
                      'monthlySboHours': data['monthlySboHours'] as int? ?? 0,
                      'scheduleVariant':
                          data['scheduleVariant'] as String? ?? 'uniform',
                      'longWorkDays': data['longWorkDays'] ?? <int>[],
                    };
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        title: const Text(AppStrings.inquadramentoChangeTitle),
                        content: Text(
                          AppStrings.inquadramentoChangeBody(current, selected),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            child: const Text(AppStrings.confirm),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await ref
                        .read(profileRepositoryProvider)
                        .changeInquadramento(newCaps);
                    if (ctx.mounted) Navigator.pop(ctx);
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

Future<void> _editScheduleVariant(
  BuildContext context,
  WidgetRef ref,
  String employmentType,
  String currentVariant,
  List<int> currentLongDays,
) async {
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textMain = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppColors.neutral900;
        final textSub = isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.neutral600;
        String variant = currentVariant;
        List<int> longDays = List<int>.from(currentLongDays);

        return StatefulBuilder(
          builder: (ctx2, setState2) => _EditSheet(
            isDark: isDark,
            title: AppStrings.scheduleVariantTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _variantChipProfile(
                      label: AppStrings.scheduleVariantUniform,
                      subtitle: AppStrings.scheduleVariantUniformDesc,
                      selected: variant == 'uniform',
                      color: AppColors.blue600,
                      isDark: isDark,
                      onTap: () => setState2(() {
                        variant = 'uniform';
                        longDays = [];
                      }),
                    ),
                    const SizedBox(width: 10),
                    _variantChipProfile(
                      label: AppStrings.scheduleVariantMixed,
                      subtitle: AppStrings.scheduleVariantMixedDesc,
                      selected: variant == 'mixed',
                      color: AppColors.green600,
                      isDark: isDark,
                      onTap: () => setState2(() {
                        variant = 'mixed';
                        longDays = [];
                      }),
                    ),
                  ],
                ),
                if (variant == 'mixed') ...[
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.longWorkDaysLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.longWorkDaysHint,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final weekday = i + 1;
                      final label = AppStrings.weekdaysShort[i];
                      final selected = longDays.contains(weekday);
                      final disabled = !selected && longDays.length >= 2;
                      return AppTappable(
                        onTap: disabled
                            ? null
                            : () => setState2(() {
                                if (longDays.contains(weekday)) {
                                  longDays.remove(weekday);
                                } else {
                                  longDays.add(weekday);
                                }
                              }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.green600.withValues(alpha: 0.15)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04)),
                            border: Border.all(
                              color: selected
                                  ? AppColors.green600
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.green600
                                    : (disabled
                                          ? (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : AppColors.neutral400)
                                          : textSub),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 8),
                _SaveButton(
                  onPressed: () async {
                    if (variant == 'mixed' && longDays.length != 2) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.longWorkDaysTooFew),
                        ),
                      );
                      return;
                    }
                    // Also update standardDailyMins to match uniform default
                    final fields = <String, dynamic>{
                      'scheduleVariant': variant,
                      'longWorkDays': longDays,
                    };
                    if (variant == 'uniform') {
                      fields['standardDailyMins'] =
                          employmentType == AppStrings.etComando ? 432 : 456;
                    }
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfileFields(fields);
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _variantChipProfile({
  required String label,
  required String subtitle,
  required bool selected,
  required Color color,
  required bool isDark,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: AppTappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? color
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.neutral700),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? color.withValues(alpha: 0.8)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.neutral400),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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

Future<void> _showNotifiche(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) async {
  final result = await showNotificationPreferencesSheet(
    context: context,
    profileData: profileData,
    onSave: (fields) => ref
        .read(profileRepositoryProvider)
        .updateNotificationPreferences(fields),
    onSendTest: () =>
        ref.read(profileRepositoryProvider).sendTestNotification(),
  );
  if (result == NotificationPreferencesResult.testSent && context.mounted) {
    context.push('/notifications');
  }
}

Future<void> _downloadMyData(BuildContext context, WidgetRef ref) async {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.downloadMyDataExporting),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // M3: fetch nel repository (niente Firestore diretto in presentation);
  // M2: include TUTTE le notifiche (il vecchio orderBy su `createdAt`
  // escludeva quelle social) e valori già JSON-encodabili (i Timestamp
  // facevano lanciare jsonEncode).
  final data = await ref.read(profileRepositoryProvider).fetchMyData();
  final profileMap = data.profile;
  final notifList = data.notifications;

  // Build timesheets CSV
  final csvBuf = StringBuffer();
  csvBuf.writeln(
    'data;tipo;entrata;uscita;netto_min;extra_min;sbo_min;sli_min;buono_pasto;nota',
  );
  for (final d in data.timesheets) {
    final row = [
      d['id'],
      d['workType'] ?? '',
      d['startTime'] ?? '',
      d['endTime'] ?? '',
      d['netWorkedMins'] ?? '',
      d['extraMins'] ?? '',
      d['sboMins'] ?? '',
      d['sliMins'] ?? '',
      d['mealVoucher'] == true ? '1' : '0',
      (d['note'] as String? ?? '').replaceAll(';', ','),
    ].join(';');
    csvBuf.writeln(row);
  }

  final exportDate = DateTime.now().toIso8601String().substring(0, 10);

  final files = <XFile>[];

  if (kIsWeb) {
    files.add(
      XFile.fromData(
        utf8.encode(csvBuf.toString()),
        mimeType: 'text/csv',
        name: 'chigio_timesheets_$exportDate.csv',
      ),
    );
    files.add(
      XFile.fromData(
        utf8.encode(jsonEncode(profileMap)),
        mimeType: 'application/json',
        name: 'chigio_profile_$exportDate.json',
      ),
    );
    files.add(
      XFile.fromData(
        utf8.encode(jsonEncode(notifList)),
        mimeType: 'application/json',
        name: 'chigio_notifications_$exportDate.json',
      ),
    );
  } else {
    final tmp = await getTemporaryDirectory();

    final csvFile = File('${tmp.path}/chigio_timesheets_$exportDate.csv');
    await csvFile.writeAsString(csvBuf.toString());
    files.add(XFile(csvFile.path, mimeType: 'text/csv'));

    final profileFile = File('${tmp.path}/chigio_profile_$exportDate.json');
    await profileFile.writeAsString(jsonEncode(profileMap));
    files.add(XFile(profileFile.path, mimeType: 'application/json'));

    final notifFile = File('${tmp.path}/chigio_notifications_$exportDate.json');
    await notifFile.writeAsString(jsonEncode(notifList));
    files.add(XFile(notifFile.path, mimeType: 'application/json'));
  }

  if (files.isEmpty) return;

  await SharePlus.instance.share(
    ShareParams(
      files: files,
      subject: 'Chigio Time — I tuoi dati ($exportDate)',
    ),
  );
}

void _showPrivacy(BuildContext context, bool isDark) {
  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
        title: AppStrings.privacy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrivacyRow(
              icon: '🔒',
              title: AppStrings.dataSafe,
              desc: AppStrings.dataSafeBody,
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '📊',
              title: AppStrings.noDataSharing,
              desc: AppStrings.noDataSharingBody,
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '🗑️',
              title: AppStrings.rightToErasure,
              desc: AppStrings.rightToErasureBody,
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '⚖️',
              title: AppStrings.privacyLegalRefs,
              desc: AppStrings.privacyLegalRefsBody,
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '☁️',
              title: AppStrings.privacyTech,
              desc: AppStrings.privacyTechBody,
              textSub: textSub,
              isDark: dark,
            ),
            const SizedBox(height: 12),
            _PrivacyRow(
              icon: '📥',
              title: AppStrings.privacyRights,
              desc: AppStrings.privacyRightsBody,
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

// ── Widget e visibilità: tre pannelli separati ──────────────────────────────

/// Pannello Widget Home: ordine (drag), visibilità (checkbox) e ★ evidenza.
/// Pubblico: la CTA "Aggiungi widget" della Home lo riusa.
void showHomeWidgetsPanel(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final hidden = Set<String>.from(
    (profileData['hiddenHomeWidgets'] as List?)?.cast<String>() ?? const [],
  );
  final featured = Set<String>.from(
    (profileData['featuredHomeWidgets'] as List?)?.cast<String>() ?? const [],
  );
  final savedOrder =
      (profileData['homeWidgetsOrder'] as List?)?.cast<String>() ?? const [];
  final defaultOrder = _kHomeWidgetOptions.map((o) => o.id).toList();
  final localOrder = [
    ...savedOrder.where(defaultOrder.contains),
    ...defaultOrder.where((id) => !savedOrder.contains(id)),
  ];

  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setLocal) {
        final isDark = Theme.of(ctx2).brightness == Brightness.dark;
        final textMain = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppColors.neutral900;
        final textSub = isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.neutral600;
        final optionMap = {for (final o in _kHomeWidgetOptions) o.id: o};
        final maxH = MediaQuery.sizeOf(ctx2).height * 0.5;

        return _EditSheet(
          isDark: isDark,
          title: AppStrings.homeWidgetsVisibility,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.widgetsCustomizerHint,
                style: TextStyle(fontSize: 11, color: textSub),
              ),
              const SizedBox(height: 10),
              // Scrollabile: la lista dei widget cresce nel tempo.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: localOrder.length,
                  onReorderItem: (oldIdx, newIdx) {
                    setLocal(() {
                      final id = localOrder.removeAt(oldIdx);
                      localOrder.insert(newIdx, id);
                    });
                  },
                  itemBuilder: (_, i) {
                    final id = localOrder[i];
                    final o = optionMap[id];
                    if (o == null) {
                      return const SizedBox.shrink(key: ValueKey('?'));
                    }
                    final isHidden = hidden.contains(o.id);
                    final isFeatured = featured.contains(o.id);
                    return Padding(
                      key: ValueKey(o.id),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                size: 18,
                                color: textSub,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(o.icon, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                o.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isHidden ? textSub : textMain,
                                ),
                              ),
                            ),
                            // ★ evidenza: sfondo blu hero + colori chiari
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: AppStrings.highlightWidget,
                              onPressed: isHidden
                                  ? null
                                  : () => setLocal(() {
                                      if (!featured.add(o.id)) {
                                        featured.remove(o.id);
                                      }
                                    }),
                              icon: Icon(
                                isFeatured
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 20,
                                color: isFeatured && !isHidden
                                    ? AppColors.orange500
                                    : textSub,
                              ),
                            ),
                            Checkbox(
                              value: !isHidden,
                              onChanged: (v) => setLocal(() {
                                if (v == true) {
                                  hidden.remove(o.id);
                                } else {
                                  hidden.add(o.id);
                                }
                              }),
                              activeColor: AppColors.blue600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SaveButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx2);
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfileFields({
                        'hiddenHomeWidgets': hidden.toList(),
                        'homeWidgetsOrder': localOrder,
                        'featuredHomeWidgets': featured.toList(),
                      });
                  if (ctx2.mounted) nav.pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Pannello Schede navbar: switch per vista, almeno una sempre attiva.
void _showNavViewsPanel(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final hiddenNav = Set<String>.from(
    (profileData['hiddenNavViews'] as List?)?.cast<String>() ?? const [],
  );
  const navOptions = [
    (id: 'home', label: AppStrings.navViewHome, icon: '🏠'),
    (id: 'timesheet', label: AppStrings.navViewTimesheet, icon: '🗓️'),
    (id: 'projects', label: AppStrings.navViewProjects, icon: '⏱️'),
    (id: 'social', label: AppStrings.navViewSocial, icon: '👥'),
    (id: 'salary', label: AppStrings.navViewSalary, icon: '💶'),
  ];

  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setLocal) {
        final isDark = Theme.of(ctx2).brightness == Brightness.dark;
        final textMain = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppColors.neutral900;
        final textSub = isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.neutral600;

        return _EditSheet(
          isDark: isDark,
          title: AppStrings.navViewsVisibility,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.navViewsVisibilityHint,
                style: TextStyle(fontSize: 11, color: textSub),
              ),
              const SizedBox(height: 10),
              ...navOptions.map((o) {
                final visible = !hiddenNav.contains(o.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(o.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMain,
                            ),
                          ),
                        ),
                        Switch(
                          value: visible,
                          onChanged: (v) {
                            if (!v &&
                                hiddenNav.length == navOptions.length - 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.navViewsAtLeastOne),
                                ),
                              );
                              return;
                            }
                            setLocal(() {
                              if (v) {
                                hiddenNav.remove(o.id);
                              } else {
                                hiddenNav.add(o.id);
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
                  await ref.read(profileRepositoryProvider).updateProfileFields(
                    {'hiddenNavViews': hiddenNav.toList()},
                  );
                  if (ctx2.mounted) nav.pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Pannello Statistica in evidenza (banner in /stats).
void _showStatHighlightPanel(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  var statHighlight = profileData['highlightWidget'] as String? ?? 'none';
  const statOptions = [
    (id: 'none', label: AppStrings.highlightWidgetNone, icon: '—'),
    (id: 'bankHours', label: AppStrings.highlightBankHours, icon: '🏦'),
    (id: 'overtime', label: AppStrings.highlightOvertime, icon: '⏱️'),
    (id: 'mealCount', label: AppStrings.highlightMealCount, icon: '🍽️'),
  ];

  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setLocal) {
        final isDark = Theme.of(ctx2).brightness == Brightness.dark;
        final textMain = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppColors.neutral900;

        return _EditSheet(
          isDark: isDark,
          title: AppStrings.statHighlightLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statOptions.map((o) {
                  final active = statHighlight == o.id;
                  return ChoiceChip(
                    selected: active,
                    onSelected: (_) => setLocal(() => statHighlight = o.id),
                    label: Text('${o.icon} ${o.label}'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.blue600 : textMain,
                    ),
                    selectedColor: AppColors.blue600.withValues(alpha: 0.12),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    side: BorderSide(
                      color: active
                          ? AppColors.blue600.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _SaveButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx2);
                  await ref.read(profileRepositoryProvider).updateProfileFields(
                    {'highlightWidget': statHighlight},
                  );
                  if (ctx2.mounted) nav.pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

const _kHomeWidgetOptions = [
  (id: 'favorites', label: 'Colleghi preferiti', icon: '⭐'),
  (id: 'maggiorPresenza', label: 'Maggior presenza', icon: '📅'),
  (id: 'counters', label: 'Contatori rapidi', icon: '🔢'),
  (id: 'bancaOre', label: 'Banca ore', icon: '🏦'),
  (id: 'totalizzatori', label: 'Totalizzatori portale', icon: '📊'),
  (id: 'routePlanner', label: 'Spostamenti', icon: '🚇'),
  (id: 'orariTable', label: 'Tabella orari', icon: '🕐'),
  (id: 'pomodoro', label: 'Pomodoro', icon: '🍅'),
  (id: 'salary', label: 'Stipendio', icon: '💶'),
];

/// ID di tutti i widget Home: i nuovi account partono con la sola timbratura
/// (tutti nascosti) + CTA in Home per sceglierli.
List<String> allHomeWidgetIds() =>
    _kHomeWidgetOptions.map((o) => o.id).toList();

void showPortaleEdit(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profile,
) {
  // C1: dati portale da private/portale (fallback legacy dentro il provider);
  // il parametro [profile] resta per compatibilità con i chiamanti.
  final current = Map<String, dynamic>.from(ref.read(portaleRawProvider) ?? {});
  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
                  AppTappable(
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
                  _section(AppStrings.identificativo, isDark: isDark),
                  _field(AppStrings.nominativo, _dipendente, isDark: isDark),
                  _field(
                    AppStrings.matricola,
                    _matricola,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(AppStrings.periodoHint, _periodo, isDark: isDark),
                  _field(
                    AppStrings.dataAggiornamentoHint,
                    _fetchedAt,
                    isDark: isDark,
                  ),

                  _section(AppStrings.ferieGiorni, isDark: isDark),
                  _field(
                    AppStrings.fruitoAnnuo,
                    _ferieFruitoAnnuo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.spettanza,
                    _ferieSpettanza,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.residuoAnnoCorrente,
                    _ferieResAc,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.residuoAnnoPrecedente,
                    _ferieResAp,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),

                  _section(AppStrings.festivitaSoppresseGiorni, isDark: isDark),
                  _field(
                    AppStrings.fruitoAnnuo,
                    _festFruitoAnnuo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.spettanza,
                    _festSpettanza,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.residuo,
                    _festResiduo,
                    type: TextInputType.number,
                    isDark: isDark,
                  ),

                  _section(AppStrings.straordinariHHMM, isDark: isDark),
                  _field(
                    AppStrings.art9Effettuate,
                    _art9Effettuate,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.art9DaRecuperare,
                    _art9DaRecuperare,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.maggiorPresenza,
                    _maggiorPresenza,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.liquidati,
                    _straordLiquidati,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.autorizzati,
                    _straordAutorizzato,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.liquidabili,
                    _straordLiquidabili,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.riposoCompMaturato,
                    _riposoCompMaturato,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.riposoCompResiduo,
                    _riposoCompResiduo,
                    isDark: isDark,
                  ),

                  _section(AppStrings.bancaOreHHMM, isDark: isDark),
                  _field(
                    AppStrings.residuoAnnoCorrente,
                    _bancaOreAc,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.residuoAnnoPrecedente,
                    _bancaOreAp,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.totaleFruibile,
                    _bancaTotale,
                    isDark: isDark,
                  ),

                  _section(AppStrings.permessiHHMM, isDark: isDark),
                  _field(
                    AppStrings.permessoBreveResiduo,
                    _permBreve,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.motiviPersonaliResiduo,
                    _permPersonali,
                    isDark: isDark,
                  ),
                  _field(
                    AppStrings.visitaSpecialisticaResiduo,
                    _visitaSpec,
                    isDark: isDark,
                  ),
                  _field('Ore perse', _orePerse, isDark: isDark),
                  _field(
                    AppStrings.oreNonRecuperate,
                    _oreNonRecuperate,
                    isDark: isDark,
                  ),

                  _section(AppStrings.buoniPastoUpper, isDark: isDark),
                  _field(
                    AppStrings.buoniMensili,
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
    builder: (dctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0b1028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        AppStrings.appName,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        AppStrings.appInfoBody,
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.65)
              : AppColors.neutral700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: const Text(AppStrings.ok),
        ),
      ],
    ),
  );
}

void _showCcnlReader(BuildContext context, bool isDark) {
  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
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
      label: AppStrings.ccnlNew,
      title: AppStrings.ccnlNewLabel,
      subtitle: AppStrings.ccnlNewSigned,
      assetPath: 'docs/ccnl/ccnl-pcm-2019-2021.md',
    ),
    _loadCcnlDoc(
      id: '2016-2018',
      label: AppStrings.ccnlPrevious,
      title: AppStrings.ccnlPreviousLabel,
      subtitle: AppStrings.ccnlPreviousSigned,
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
        title: titleLines.isEmpty
            ? AppStrings.articleFallbackTitle(number)
            : titleLines.join(' '),
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

/// Pulisce la premessa del CCNL per la lettura: rimuove l'indice con i
/// puntini di riempimento, le righe di firma, il blocco indirizzo ARAN e i
/// numeri di pagina; ricompone le righe spezzate in capoversi.
String cleanCcnlPreamble(String raw) {
  final noise = RegExp(
    r'(\.{4,}|firmato|^_+$|^VIA G\.B\.|^TEL \+|^PEC |^C\.F\.|^Indice$)',
    caseSensitive: false,
  );
  final paras = <String>[];
  var cur = '';
  void flush() {
    if (cur.trim().isNotEmpty) paras.add(cur.trim());
    cur = '';
  }

  for (final r in raw.split('\n')) {
    final l = r.trim();
    if (l.isEmpty) {
      flush();
      continue;
    }
    if (RegExp(r'^\d+$').hasMatch(l)) continue; // numero di pagina
    if (l.startsWith('CCNL COMPARTO')) continue;
    if (l.startsWith('>')) continue; // nota di conversione markdown
    if (l.startsWith('#')) continue; // titolo markdown
    if (noise.hasMatch(l)) continue;
    cur = cur.isEmpty ? l : '$cur $l';
  }
  flush();
  return paras.join('\n\n');
}

/// Pulisce il corpo di un articolo CCNL per la lettura: rimuove l'intestazione
/// "Art. N" + titolo (già mostrati), i numeri di pagina e le intestazioni
/// correnti, e ricompone i capoversi (1. / a) ) unendo le righe spezzate.
String formatCcnlBody(String raw) {
  final lines = raw.split('\n');
  final marker = RegExp(r'^(\d+\.|[a-z](-bis|-ter|-quater)?\))\s');
  // Salta intestazione + titolo: parte dal primo capoverso numerato/lettera.
  var start = 0;
  for (var i = 0; i < lines.length; i++) {
    if (marker.hasMatch('${lines[i].trim()} ')) {
      start = i;
      break;
    }
  }
  final paras = <String>[];
  var cur = '';
  void flush() {
    if (cur.trim().isNotEmpty) paras.add(cur.trim());
    cur = '';
  }

  for (final r in lines.skip(start)) {
    final l = r.trim();
    if (l.isEmpty) continue;
    if (RegExp(r'^\d+$').hasMatch(l)) continue; // numero di pagina
    if (l.startsWith('CCNL ') ||
        l.startsWith('TITOLO ') ||
        l.startsWith('Capo ')) {
      continue;
    }
    if (marker.hasMatch('$l ')) {
      flush();
      cur = l;
    } else {
      cur = cur.isEmpty ? l : '$cur $l';
    }
  }
  flush();
  final body = paras.join('\n\n');
  return body.isEmpty ? raw.trim() : body;
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
  final bool enabled;

  const _SaveButton({required this.onPressed, this.enabled = true});

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
        onPressed: _loading || !widget.enabled
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
                    AppStrings.hoursPerMonthLower,
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
    return AppTappable(
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

  // Passo identico alla granularità dello slider (es. 5 min per la soglia BP).
  double get _step =>
      widget.divisions > 0 ? (widget.max - widget.min) / widget.divisions : 1;

  void _nudge(int dir) => setState(() {
    _value = (_value + dir * _step).clamp(widget.min, widget.max);
  });

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
              _StepButton(
                icon: Icons.remove_rounded,
                isDark: isDark,
                enabled: _value > widget.min,
                onTap: () => _nudge(-1),
              ),
              const SizedBox(width: 18),
              Text(
                widget.formatValue(_value),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue600,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 18),
              _StepButton(
                icon: Icons.add_rounded,
                isDark: isDark,
                enabled: _value < widget.max,
                onTap: () => _nudge(1),
              ),
            ],
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

// Bottone +/− dei fogli slider (soglia buono pasto, avvisi, ecc.).
class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.blue600.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? AppColors.blue600
              : (isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.neutral400),
        ),
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isDark;
  final bool divider;
  final VoidCallback? onEdit;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.divider,
    this.onEdit,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
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
              if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
              if (onEdit != null)
                AppTappable(
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
          onTap: onTap == null
              ? null
              : () {
                  Haptics.light(); // tap su voce di profilo
                  onTap!();
                },
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
          tooltip: AppStrings.themeLight,
          active: !isAutoByTime && current == ThemeMode.light,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.light),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '🌙',
          tooltip: AppStrings.themeDark,
          active: !isAutoByTime && current == ThemeMode.dark,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.dark),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '📱',
          tooltip: AppStrings.themeSystem,
          active: !isAutoByTime && current == ThemeMode.system,
          isDark: isDark,
          onTap: () => onSelect(ThemeMode.system),
        ),
        const SizedBox(width: 4),
        _ThemeBtn(
          label: '⏰',
          tooltip: AppStrings.themeAutoByTime,
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
    return AppTappable(
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
    useRootNavigator: true,
    useSafeArea: true,
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
        ? Colors.white.withValues(alpha: 0.6)
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
              AppTappable(
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

// ── Notification preferences sheet ──────────────────────────────────────────

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

    final sheet = _EditSheet(
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
          _SaveButton(enabled: !_isBusy, onPressed: _savePreferences),
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
        ? Colors.white.withValues(alpha: 0.6)
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
                      AppStrings.ccnlPcmTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.ccnlVersionsHint,
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.openCcnl,
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
              _CcnlSmallTag(
                label: AppStrings.ccnlNew,
                value: '2019-2021',
                isDark: isDark,
              ),
              _CcnlSmallTag(
                label: AppStrings.ccnlPrevious,
                value: '2016-2018',
                isDark: isDark,
              ),
              _CcnlSmallTag(
                label: AppStrings.indexLabel,
                value: AppStrings.articlesValue,
                isDark: isDark,
              ),
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
                      AppStrings.readContract,
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
      useRootNavigator: true,
      useSafeArea: true,
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
                                    AppStrings.ccnlPcmTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doc?.subtitle ??
                                        AppStrings.loadingContracts,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: AppStrings.articlesIndex,
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
                                AppStrings.ccnlLoadError,
                                style: TextStyle(color: textSub),
                              ),
                            ),
                          )
                        : doc == null
                        ? Center(
                            child: Text(
                              AppStrings.noContractAvailable,
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
        ? Colors.white.withValues(alpha: 0.6)
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
                  AppStrings.articlesCount(doc.articles.length),
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

    final cleaned = cleanCcnlPreamble(text);
    if (cleaned.isEmpty) return const SizedBox.shrink();

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
        cleaned,
        style: TextStyle(fontSize: 13, height: 1.55, color: textMain),
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
                  AppStrings.articleHeading(article.number),
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
          // Un blocco per capoverso: numero di comma in evidenza, lettere
          // a)/b) indentate — molto più scorrevole del muro di testo.
          ...formatCcnlBody(article.text).split('\n\n').map((p) {
            final comma = RegExp(r'^(\d+)\.\s').firstMatch(p);
            final lettera = RegExp(
              r'^([a-z](?:-bis|-ter|-quater)?\))\s',
            ).firstMatch(p);
            final bodyStyle = TextStyle(
              fontSize: 13,
              height: 1.55,
              color: textBody,
            );
            if (comma != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${comma.group(1)}.  ',
                        style: bodyStyle.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue600,
                        ),
                      ),
                      TextSpan(text: p.substring(comma.end)),
                    ],
                    style: bodyStyle,
                  ),
                ),
              );
            }
            if (lettera != null) {
              return Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 8),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${lettera.group(1)}  ',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: p.substring(lettera.end)),
                    ],
                    style: bodyStyle,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectableText(p, style: bodyStyle),
            );
          }),
        ],
      ),
    );
  }
}

class _CcnlIndexSheet extends StatefulWidget {
  final _CcnlDoc doc;
  final bool isDark;
  final ValueChanged<_CcnlArticle> onSelect;

  const _CcnlIndexSheet({
    required this.doc,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_CcnlIndexSheet> createState() => _CcnlIndexSheetState();
}

class _CcnlIndexSheetState extends State<_CcnlIndexSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final doc = widget.doc;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? doc.articles
        : doc.articles
              .where(
                (a) =>
                    a.title.toLowerCase().contains(q) ||
                    '${a.number}' == q ||
                    'art. ${a.number}'.contains(q),
              )
              .toList();

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
                                AppStrings.articlesIndex,
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
                    const SizedBox(height: 10),
                    // Ricerca articolo per numero o titolo
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: AppStrings.ccnlSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(fontSize: 13, color: textMain),
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
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 52,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (context, i) {
                    final article = filtered[i];
                    // Riga custom (niente ListTile: il Material trasparente
                    // dello sheet renderebbe invisibili tile e splash).
                    return AppTappable(
                      onTap: () => widget.onSelect(article),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Container(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textMain,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: textSub,
                            ),
                          ],
                        ),
                      ),
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
        ? Colors.white.withValues(alpha: 0.6)
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
            label: AppStrings.androidPlatform,
            sublabel: AppStrings.apkVersion(AppStrings.appVersion),
            color: const Color(0xFF34A853),
            onTap: () => _open(_androidUrl),
          ),
          const SizedBox(height: 8),
          _DownloadBtn(
            icon: '',
            label: AppStrings.iosPlatform,
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
    return AppTappable(
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
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
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
            AppStrings.overtimeLast6Months,
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
                        AppStrings.hoursMinutesShort(mins),
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
                            style: TextStyle(fontSize: 11, color: textSub),
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
                AppStrings.overtimeHoursAxis,
                style: TextStyle(fontSize: 11, color: textSub),
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
    final lat = (profileData['officeLat'] as num?)?.toDouble();
    final lng = (profileData['officeLng'] as num?)?.toDouble();
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
                            AppStrings.gpsRadiusValue(radius.toInt()),
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
    final lat = (profileData['officeLat'] as num?)?.toDouble();
    final lng = (profileData['officeLng'] as num?)?.toDouble();
    final radius =
        (profileData['officeRadiusM'] as num?)?.toDouble() ??
        GeofencingService.defaultRadiusM;
    return showModalBottomSheet<void>(
      useRootNavigator: true,
      useSafeArea: true,
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
        ? Colors.white.withValues(alpha: 0.6)
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
    return AppTappable(
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

// ── Profile edit screen (personal details) ───────────────────────────────────

/// Vero se lo stato del giorno è impostato e non scaduto.
bool statusMessageActive(Map<String, dynamic> data) {
  final m = data['statusMessage'] as String? ?? '';
  if (m.isEmpty) return false;
  final until = DateTime.tryParse(data['statusMessageUntil'] as String? ?? '');
  return until == null || DateTime.now().isBefore(until);
}

/// Chip "stato del giorno" nella card personale del Profilo: mostra lo stato
/// attivo (o la CTA) e apre lo sheet di modifica con scadenza.
class _StatusDayChip extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _StatusDayChip({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = statusMessageActive(data);
    final message = data['statusMessage'] as String? ?? '';

    return AppTappable(
      onTap: () => showStatusMessageSheet(context, ref, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.blue600.withValues(alpha: isDark ? 0.18 : 0.10)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.blue600.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                active ? message : AppStrings.statusSetCta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? AppColors.blue600
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.neutral600),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Icona modifica: rende esplicito che lo stato è modificabile.
            Icon(
              Icons.edit_rounded,
              size: 14,
              color: active
                  ? AppColors.blue600
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.neutral400),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet condiviso per lo stato del giorno con scadenza opzionale
/// (1h / 4h / fine giornata / senza scadenza). Salva `statusMessage` +
/// `statusMessageUntil` (ISO, null = nessuna scadenza).
void showStatusMessageSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> profileData,
) {
  final ctrl = TextEditingController(
    text: statusMessageActive(profileData)
        ? (profileData['statusMessage'] as String? ?? '')
        : '',
  );
  // 0 = 1h · 1 = 4h · 2 = fine giornata · 3 = senza scadenza
  var expiry = 3;

  showModalBottomSheet<void>(
    useRootNavigator: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setLocal) {
        final isDark = Theme.of(ctx2).brightness == Brightness.dark;
        final textMain = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppColors.neutral900;
        final textSub = isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppColors.neutral600;
        const options = [
          AppStrings.statusExpiry1h,
          AppStrings.statusExpiry4h,
          AppStrings.statusExpiryEod,
          AppStrings.statusExpiryNone,
        ];

        return _EditSheet(
          isDark: isDark,
          title: AppStrings.statusMessageLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                maxLength: 40,
                style: TextStyle(fontSize: 15, color: textMain),
                decoration: InputDecoration(
                  hintText: AppStrings.statusMessageHint,
                  hintStyle: TextStyle(color: textSub),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.statusExpiryLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSub,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(options.length, (i) {
                  final selected = expiry == i;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setLocal(() => expiry = i),
                    label: Text(options[i]),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.blue600 : textMain,
                    ),
                    selectedColor: AppColors.blue600.withValues(alpha: 0.12),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    side: BorderSide(
                      color: selected
                          ? AppColors.blue600.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              _SaveButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx2);
                  final text = ctrl.text.trim();
                  final now = DateTime.now();
                  final until = switch (expiry) {
                    0 => now.add(const Duration(hours: 1)),
                    1 => now.add(const Duration(hours: 4)),
                    2 => DateTime(now.year, now.month, now.day, 23, 59),
                    _ => null,
                  };
                  await ref
                      .read(profileRepositoryProvider)
                      .updateProfileFields({
                        'statusMessage': text,
                        'statusMessageUntil': text.isEmpty
                            ? null
                            : until?.toIso8601String(),
                      });
                  if (ctx2.mounted) nav.pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Card "Inquadramento e orario" — vive nella schermata Dati personali
/// (/profile/edit) insieme agli altri dati modificabili dell'utente.
class _InquadramentoCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _InquadramentoCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employmentType = data['employmentType'] as String? ?? '—';
    final stdMins = data['standardDailyMins'] as int? ?? 456;
    final mealMins = data['mealVoucherThresholdMins'] as int? ?? 380;
    final art9 = data['monthlyArt9Hours'] as int? ?? 0;
    final sli = data['monthlySliHours'] as int? ?? 0;
    final sbo = data['monthlySboHours'] as int? ?? 0;
    final scheduleVariant = data['scheduleVariant'] as String? ?? 'uniform';
    final rawLongDays = data['longWorkDays'];
    final longWorkDays = rawLongDays is List
        ? List<int>.from(rawLongDays.whereType<int>())
        : <int>[];

    final sauHistory =
        ref.watch(monthlySauHistoryStreamProvider).asData?.value ?? [];
    final now = DateTime.now();
    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonthSau = sauHistory.cast<MonthlySau?>().firstWhere(
      (s) => s?.monthId == currentMonthId,
      orElse: () => null,
    );

    String fmtMins(int m) =>
        '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _InfoRow(
            icon: '📋',
            label: AppStrings.employmentType,
            value: employmentType,
            isDark: isDark,
            divider: true,
            onEdit: () => _editEmploymentType(context, ref, data),
          ),
          // Orario — unico editor: tipo (5-uguali / 3+2) +
          // giorni; ore predeterminate dall'inquadramento.
          _InfoRow(
            icon: '🕐',
            label: AppStrings.orarioLabel,
            value:
                (employmentType == AppStrings.etRuolo ||
                    employmentType == AppStrings.etComando)
                ? (scheduleVariant == 'mixed'
                      ? '${AppStrings.scheduleVariantMixed} · ${longWorkDays.map((d) => AppStrings.weekdaysShort[d - 1]).join(', ')}'
                      : '${AppStrings.scheduleVariantUniform} · ${fmtMins(stdMins)}')
                : fmtMins(stdMins),
            isDark: isDark,
            divider: true,
            onEdit: () {
              if (employmentType == AppStrings.etRuolo ||
                  employmentType == AppStrings.etComando) {
                _editScheduleVariant(
                  context,
                  ref,
                  employmentType,
                  scheduleVariant,
                  longWorkDays,
                );
              } else {
                _editStandardHoursPresets(
                  context,
                  ref,
                  employmentType,
                  stdMins,
                );
              }
            },
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
              viaCaps: true,
              formatValue: (v) {
                final m = v.round();
                return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
              },
            ),
          ),
          // Art.9 — solo toggle ON/OFF: 0 oppure il massimo
          // dell'inquadramento (8 Ruolo / 17 Comando).
          // Nessun valore intermedio (integrità app-wide).
          _InfoRow(
            icon: '📑',
            label: AppStrings.articleNine,
            value: art9 == 0
                ? AppStrings.art9Off
                : AppStrings.hoursPerMonth(art9),
            isDark: isDark,
            divider: true,
            trailing: Switch.adaptive(
              value: art9 > 0,
              onChanged: (on) {
                final def = employmentType == AppStrings.etComando ? 17 : 8;
                ref.read(profileRepositoryProvider).updateCaps({
                  'monthlyArt9Hours': on ? def : 0,
                });
              },
            ),
          ),
          _InfoRow(
            icon: '💳',
            label: AppStrings.sliMonthly,
            value: AppStrings.hoursPerMonth(sli),
            isDark: isDark,
            divider: true,
            onEdit: () => _editIntHours(
              context,
              ref,
              title: AppStrings.sliMonthly,
              currentValue: sli,
              min: 0,
              max: 50,
              fieldKey: 'monthlySliHours',
              viaCaps: true,
              extraFields: (v) => {'monthlyOvertimeHours': v + sbo},
            ),
          ),
          _InfoRow(
            icon: '🏦',
            label: AppStrings.sboMonthly,
            value: AppStrings.hoursPerMonth(sbo),
            isDark: isDark,
            divider: true,
            onEdit: () => _editIntHours(
              context,
              ref,
              title: AppStrings.sboMonthly,
              currentValue: sbo,
              min: 0,
              max: 50,
              fieldKey: 'monthlySboHours',
              viaCaps: true,
              extraFields: (v) => {'monthlyOvertimeHours': sli + v},
            ),
          ),
          _InfoRow(
            icon: '🔢',
            label: AppStrings.sauMonthly,
            value: AppStrings.hoursPerMonth(sli + sbo),
            isDark: isDark,
            divider: true,
            onEdit: null,
          ),
          _SauMonthlyUpdateRow(
            currentMonthSau: currentMonthSau,
            defaultSli: sli,
            defaultSbo: sbo,
            isDark: isDark,
          ),
          // Tetto maggior presenza (auto) = Art.9 + SLI + SBO
          // — sostituisce il vecchio "Tetto straordinari"
          // (duplicato di SAU).
          _InfoRow(
            icon: '📊',
            label: AppStrings.tettoMaggiorPresenza,
            value: AppStrings.hoursPerMonth(art9 + sli + sbo),
            isDark: isDark,
            divider: true,
            onEdit: null,
          ),
          _InfoRow(
            icon: '🕓',
            label: AppStrings.storicoInquadramenti,
            value: '',
            isDark: isDark,
            divider: true,
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StoricoInquadramentiPage(),
              ),
            ),
          ),
          // Sotto lo storico inquadramenti, come richiesto.
          _InfoRow(
            icon: '📈',
            label: AppStrings.sauTrendTitle,
            value: '',
            isDark: isDark,
            divider: false,
            onEdit: () => context.push('/sau'),
          ),
        ],
      ),
    );
  }
}

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  AppTappable(
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
                    AppStrings.personalDetails,
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
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: SkeletonList(count: 4),
                ),
                error: (e, _) => ErrorRetry(
                  error: e,
                  onRetry: () => ref.invalidate(userProfileStreamProvider),
                ),
                data: (data) {
                  if (data == null) {
                    return Center(
                      child: Text(
                        AppStrings.errorNoData,
                        style: TextStyle(color: textSub),
                      ),
                    );
                  }
                  final name =
                      data['name'] as String? ??
                      AppStrings.defaultUserNameProfile;
                  final gender = data['gender'] as String? ?? 'A';
                  final administration =
                      data['administration'] as String? ??
                      AppStrings.appOrgShort;
                  final dipartimento = data['dipartimento'] as String? ?? '';
                  final sede = data['sede'] as String? ?? '';
                  final sedeId = data['sedeId'] as String? ?? '';
                  final piano = data['piano'] as String? ?? '';
                  final stanza = data['stanza'] as String? ?? '';
                  final interno = data['interno'] as String? ?? '';
                  final phone = data['phoneNumber'] as String?;
                  final hireDate = data['hireDate'] as String?;
                  final photoUrl =
                      data['photoURL'] as String? ??
                      FirebaseAuth.instance.currentUser?.photoURL;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      const SizedBox(height: 8),
                      // Foto profilo come prima voce di "Dati personali".
                      Center(
                        child: _PhotoUploadCard(
                          currentPhotoUrl: photoUrl,
                          name: name,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          AppStrings.photoUrlLabel,
                          style: TextStyle(fontSize: 11, color: textSub),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: '👤',
                              label: AppStrings.fullName,
                              value: name,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editTextField(
                                context,
                                ref,
                                title: AppStrings.fullName,
                                current: name,
                                fieldKey: 'name',
                                keyboardType: TextInputType.name,
                                capitalization: TextCapitalization.words,
                                validator: (v) => v.trim().isEmpty
                                    ? AppStrings.fullNameRequired
                                    : null,
                              ),
                            ),
                            _InfoRow(
                              icon: '🧬',
                              label: AppStrings.genderForChigio,
                              value: switch (gender) {
                                'M' => AppStrings.genderMale,
                                'F' => AppStrings.genderFemale,
                                'A' => AppStrings.genderOther,
                                _ => AppStrings.genderOther,
                              },
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editGender(context, ref, gender),
                            ),
                            _InfoRow(
                              icon: '🏛️',
                              label: AppStrings.administration,
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
                              onEdit: () => _editPcmAssignment(
                                context,
                                ref,
                                currentStructure: dipartimento,
                                currentSiteId: sedeId,
                              ),
                            ),
                            _InfoRow(
                              icon: '🏛️',
                              label: AppStrings.sede,
                              value: sede.isEmpty ? '—' : sede,
                              isDark: isDark,
                              divider: true,
                              onEdit: () => _editPcmAssignment(
                                context,
                                ref,
                                currentStructure: dipartimento,
                                currentSiteId: sedeId,
                              ),
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
                              icon: '📅',
                              label: AppStrings.hireDateLabel,
                              value: () {
                                final d = DateTime.tryParse(hireDate ?? '');
                                return d == null
                                    ? '—'
                                    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                              }(),
                              isDark: isDark,
                              divider: false,
                              onEdit: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      DateTime.tryParse(hireDate ?? '') ?? now,
                                  firstDate: DateTime(1980),
                                  // Mai nel futuro.
                                  lastDate: now,
                                  helpText: AppStrings.hireDateLabel
                                      .toUpperCase(),
                                );
                                if (picked == null) return;
                                final id =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                await ref
                                    .read(profileRepositoryProvider)
                                    .updateProfileFields({'hireDate': id});
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),
                      const _SectionLabel(AppStrings.sectionInquadramento),
                      _InquadramentoCard(data: data, isDark: isDark),
                    ],
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

// ── SAU monthly update row ────────────────────────────────────────────────────

class _SauMonthlyUpdateRow extends ConsumerWidget {
  final MonthlySau? currentMonthSau;
  final int defaultSli;
  final int defaultSbo;
  final bool isDark;

  const _SauMonthlyUpdateRow({
    required this.currentMonthSau,
    required this.defaultSli,
    required this.defaultSbo,
    required this.isDark,
  });

  Future<void> _showUpdateDialog(BuildContext context, WidgetRef ref) async {
    int sli = currentMonthSau?.sliHours ?? defaultSli;
    int sbo = currentMonthSau?.sboHours ?? defaultSbo;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('SAU questo mese'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('SLI (ore)')),
                  _IntStepper(
                    value: sli,
                    onChanged: (v) => setState(() => sli = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('SBO (ore)')),
                  _IntStepper(
                    value: sbo,
                    onChanged: (v) => setState(() => sbo = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'SAU = ${sli + sbo}h',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final now = DateTime.now();
                await ref
                    .read(profileRepositoryProvider)
                    .saveMonthlySau(
                      year: now.year,
                      month: now.month,
                      sliHours: sli,
                      sboHours: sbo,
                    );
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthLabel = AppStrings.months[now.month - 1];
    final recorded = currentMonthSau != null;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return InkWell(
      onTap: () => _showUpdateDialog(context, ref),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              recorded
                  ? Icons.check_circle_rounded
                  : Icons.edit_calendar_rounded,
              size: 14,
              color: recorded ? AppColors.green500 : AppColors.blue600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recorded
                    ? 'SAU $monthLabel: SLI ${currentMonthSau!.sliHours}h · SBO ${currentMonthSau!.sboHours}h'
                    : 'Registra SAU per $monthLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: recorded ? subColor : AppColors.blue600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: subColor),
          ],
        ),
      ),
    );
  }
}

// ── Profile photo upload card ─────────────────────────────────────────────────

class _PhotoUploadCard extends ConsumerStatefulWidget {
  final String? currentPhotoUrl;
  final String name;

  const _PhotoUploadCard({required this.currentPhotoUrl, required this.name});

  @override
  ConsumerState<_PhotoUploadCard> createState() => _PhotoUploadCardState();
}

class _PhotoUploadCardState extends ConsumerState<_PhotoUploadCard> {
  bool _uploading = false;
  String? _localUrl;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadProfilePhoto(file);
      if (url != null && mounted) setState(() => _localUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.errorGeneric(e))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = _localUrl ?? widget.currentPhotoUrl;
    return AppTappable(
      onTap: _uploading ? null : _pick,
      child: Stack(
        alignment: Alignment.bottomRight,
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
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: url != null
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _InitialAvatar(name: widget.name),
                    )
                  : _InitialAvatar(name: widget.name),
            ),
          ),
          if (_uploading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue600,
              ),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue600,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Int stepper (used by SAU dialog) ─────────────────────────────────────────

class _IntStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _IntStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_rounded, size: 18),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () => onChanged(value + 1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

// ── Storico inquadramenti (ADR-0009) ──────────────────────────────────────
class StoricoInquadramentiPage extends ConsumerWidget {
  const StoricoInquadramentiPage({super.key});

  static String _fmtMonth(String ym) {
    final p = ym.split('-');
    return p.length == 2 ? '${p[1]}/${p[0]}' : ym;
  }

  static String _fmtH(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periods =
        ref.watch(capPeriodsStreamProvider).asData?.value ?? const [];
    final sorted = [...periods]
      ..sort((a, b) => b.fromMonth.compareTo(a.fromMonth));
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.storicoInquadramenti)),
      body: sorted.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppStrings.storicoEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSub),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = sorted[i];
                final range =
                    '${_fmtMonth(p.fromMonth)} → ${p.toMonth == null ? 'oggi' : _fmtMonth(p.toMonth!)}';
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            range,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSub,
                            ),
                          ),
                          Text(
                            p.inquadramento.isEmpty ? '—' : p.inquadramento,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: p.isOpen ? AppColors.blue600 : textMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'std ${_fmtH(p.standardDailyMins)} · Art.9 ${p.monthlyArt9Hours}h · '
                        'SLI ${p.monthlySliHours}h · SBO ${p.monthlySboHours}h · '
                        'BP ${_fmtH(p.mealVoucherThresholdMins)}',
                        style: TextStyle(fontSize: 12, color: textMain),
                      ),
                      const SizedBox(height: 4),
                      // Storico orario: variante schedule per periodo.
                      Text(
                        '🕐 ${p.scheduleVariant == 'mixed' ? '${AppStrings.scheduleVariantMixed} · ${p.longWorkDays.map((d) => AppStrings.weekdaysShort[d - 1]).join(', ')}' : AppStrings.scheduleVariantUniform}',
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.black.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
