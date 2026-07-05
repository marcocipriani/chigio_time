import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../core/constants/pcm_locations.dart';
import '../../../core/data/pcm_locations_repository.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/home_widget_header.dart';

enum _RouteMode {
  walk(AppStrings.travelOnFoot, Icons.directions_walk_rounded),
  bike(AppStrings.travelByBike, Icons.directions_bike_rounded),
  ride(AppStrings.travelByCarShuttle, Icons.directions_car_rounded);

  final String label;
  final IconData icon;

  const _RouteMode(this.label, this.icon);
}

class PcmRoutePlannerCard extends ConsumerStatefulWidget {
  const PcmRoutePlannerCard({super.key});

  @override
  ConsumerState<PcmRoutePlannerCard> createState() =>
      _PcmRoutePlannerCardState();
}

class _PcmRoutePlannerCardState extends ConsumerState<PcmRoutePlannerCard> {
  String? _fromId;
  String? _toId;
  _RouteMode _mode = _RouteMode.walk;

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(pcmSiteLocationsProvider);

    return sitesAsync.when(
      data: (sites) {
        if (sites.length < 2) return const SizedBox.shrink();
        final sorted = [...sites]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final from = _findSite(sorted, _fromId) ?? sorted.first;
        final to =
            _findSite(sorted, _toId) ??
            sorted.firstWhere(
              (site) => site.id != from.id,
              orElse: () => sorted.last,
            );
        final estimate = _estimateRoute(from, to, _mode);

        return _RouteCardShell(
          from: from,
          to: to,
          sites: sorted,
          mode: _mode,
          estimate: estimate,
          onFromChanged: (id) => setState(() => _fromId = id),
          onToChanged: (id) => setState(() => _toId = id),
          onSwap: () => setState(() {
            final fromId = from.id;
            _fromId = to.id;
            _toId = fromId;
          }),
          onModeChanged: (mode) => setState(() => _mode = mode),
        );
      },
      loading: () => const _RouteLoadingCard(),
      error: (_, _) {
        final fallback = pcmSitesFromOffices(activePcmOfficeSeeds());
        if (fallback.length < 2) return const SizedBox.shrink();
        final from = _findSite(fallback, _fromId) ?? fallback.first;
        final to =
            _findSite(fallback, _toId) ??
            fallback.firstWhere(
              (site) => site.id != from.id,
              orElse: () => fallback.last,
            );
        return _RouteCardShell(
          from: from,
          to: to,
          sites: fallback,
          mode: _mode,
          estimate: _estimateRoute(from, to, _mode),
          onFromChanged: (id) => setState(() => _fromId = id),
          onToChanged: (id) => setState(() => _toId = id),
          onSwap: () => setState(() {
            final fromId = from.id;
            _fromId = to.id;
            _toId = fromId;
          }),
          onModeChanged: (mode) => setState(() => _mode = mode),
        );
      },
    );
  }

  PcmSiteOption? _findSite(List<PcmSiteOption> sites, String? id) {
    if (id == null) return null;
    for (final site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }
}

class _RouteCardShell extends StatelessWidget {
  final PcmSiteOption from;
  final PcmSiteOption to;
  final List<PcmSiteOption> sites;
  final _RouteMode mode;
  final _RouteEstimate estimate;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final VoidCallback onSwap;
  final ValueChanged<_RouteMode> onModeChanged;

  const _RouteCardShell({
    required this.from,
    required this.to,
    required this.sites,
    required this.mode,
    required this.estimate,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : AppColors.neutral600;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeWidgetHeader(
            pose: ChigioQuotes.okCammina,
            title: AppStrings.pcmRoutes,
            subtitle: AppStrings.quickRouteEstimate,
            trailing: IconButton.filledTonal(
              tooltip: AppStrings.reverseRoute,
              onPressed: onSwap,
              icon: const Icon(Icons.swap_vert_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          _SiteDropdown(
            label: AppStrings.routeFrom,
            value: from.id,
            sites: sites,
            onChanged: onFromChanged,
          ),
          const SizedBox(height: 10),
          _SiteDropdown(
            label: AppStrings.routeTo,
            value: to.id,
            sites: sites,
            onChanged: onToChanged,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _RouteMode.values
                .map((item) {
                  final selected = item == mode;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => onModeChanged(item),
                    avatar: Icon(
                      item.icon,
                      size: 16,
                      color: selected ? Colors.white : AppColors.blue600,
                    ),
                    label: Text(item.label),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : textMain,
                    ),
                    selectedColor: AppColors.blue600,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.55),
                    side: BorderSide(
                      color: selected
                          ? AppColors.blue600
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06)),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.46),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.70),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMinutes(estimate.minutes),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: estimate.isLongRange
                              ? AppColors.orange600
                              : AppColors.blue600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${estimate.distanceKm.toStringAsFixed(estimate.distanceKm < 10 ? 1 : 0)} km stimati',
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                      if (estimate.institutionalMins != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 11,
                              color: AppColors.green600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${estimate.institutionalMins} min istituzionali',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openMaps(from, to, mode),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text(AppStrings.mapsLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue600,
                    side: BorderSide(
                      color: AppColors.blue600.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estimate.isLongRange
                ? AppStrings.outsideRomeEstimateNote
                : AppStrings.localDistanceEstimateNote,
            style: TextStyle(fontSize: 10, height: 1.35, color: textSub),
          ),
        ],
      ),
    );
  }
}

class _SiteDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<PcmSiteOption> sites;
  final ValueChanged<String?> onChanged;

  const _SiteDropdown({
    required this.label,
    required this.value,
    required this.sites,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.48)
        : AppColors.neutral600;

    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      itemHeight: 64,
      dropdownColor: isDark ? const Color(0xFF10102A) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSub),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      selectedItemBuilder: (_) => sites
          .map(
            (site) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                site.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
            ),
          )
          .toList(growable: false),
      items: sites
          .map(
            (site) => DropdownMenuItem<String>(
              value: site.id,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    site.name == site.address ? site.city : site.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _RouteLoadingCard extends StatelessWidget {
  const _RouteLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.pcmRoutes,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.90)
                  : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.blue600,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 10),
          Text(AppStrings.loadingPcmSites, style: TextStyle(color: textSub)),
        ],
      ),
    );
  }
}

class _RouteEstimate {
  final double distanceKm;
  final int minutes;
  final bool isLongRange;
  final int? institutionalMins;

  const _RouteEstimate({
    required this.distanceKm,
    required this.minutes,
    required this.isLongRange,
    this.institutionalMins,
  });
}

_RouteEstimate _estimateRoute(
  PcmSiteOption from,
  PcmSiteOption to,
  _RouteMode mode,
) {
  final directKm = _haversineKm(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );
  final isLongRange = directKm > 40;
  final routeKm = directKm * (isLongRange ? 1.18 : 1.32);

  final (speedKmh, overheadMins, minMins) = switch (mode) {
    _RouteMode.walk => isLongRange ? (4.6, 10, 8) : (4.6, 4, 3),
    _RouteMode.bike => isLongRange ? (15.0, 12, 8) : (13.0, 3, 2),
    _RouteMode.ride => isLongRange ? (78.0, 25, 20) : (18.0, 8, 6),
  };
  final minutes = ((routeKm / speedKmh) * 60 + overheadMins).round();

  return _RouteEstimate(
    distanceKm: routeKm,
    minutes: minutes < minMins ? minMins : minutes,
    isLongRange: isLongRange,
    institutionalMins: _institutionalMins(from.id, to.id),
  );
}

// Official PCM inter-site travel time table (min).
// Zone A = centro storico, Zone B = periferia Roma, Zone C = Ferratella/EUR.
// Values derived from PCM circular on authorized inter-sede travel times.
int? _institutionalMins(String fromId, String toId) {
  if (fromId == toId) return null;
  const outOfRome = {'sna-caserta', 'protezione-civile-vitorchiano'};
  if (outOfRome.contains(fromId) || outOfRome.contains(toId)) return null;
  const ferratella = {
    'casa-italia-ferratella',
    'droga-dipendenze-ferratella',
    'giovani-scu-ferratella',
  };
  const periphery = {
    'politiche-spaziali-molise',
    'sport-sardegna',
    'coesione-sud-sicilia',
    'zes-sicilia',
    'protezione-civile-ulpiano',
    'sna-roma',
  };
  // Everything else = centro (Chigi, Mercede, Stamperia, Vidoni, etc.)
  final fromFerr = ferratella.contains(fromId);
  final toFerr = ferratella.contains(toId);
  final fromPerif = periphery.contains(fromId);
  final toPerif = periphery.contains(toId);
  if (fromFerr && toFerr) return 15;
  if (fromPerif && toPerif) return 20;
  if (!fromFerr && !fromPerif && !toFerr && !toPerif) {
    return 20; // centro↔centro
  }
  if ((fromFerr && toCentro(toFerr, toPerif)) ||
      (toFerr && toCentro(fromFerr, fromPerif))) {
    return 45;
  }
  if ((fromFerr && toPerif) || (toFerr && fromPerif)) {
    return 50;
  }
  if ((fromPerif && toCentro(toFerr, toPerif)) ||
      (toPerif && toCentro(fromFerr, fromPerif))) {
    return 30;
  }
  return 25;
}

bool toCentro(bool isFerr, bool isPerif) => !isFerr && !isPerif;

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final rLat1 = _degToRad(lat1);
  final rLat2 = _degToRad(lat2);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rLat1) *
          math.cos(rLat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;

String _formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '$mins min';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins.toString().padLeft(2, '0')}m';
}

Future<void> _openMaps(
  PcmSiteOption from,
  PcmSiteOption to,
  _RouteMode mode,
) async {
  final travelMode = switch (mode) {
    _RouteMode.walk => 'walking',
    _RouteMode.bike => 'bicycling',
    _RouteMode.ride => 'driving',
  };
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': from.mapsQuery,
    'destination': to.mapsQuery,
    'travelmode': travelMode,
  });
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
