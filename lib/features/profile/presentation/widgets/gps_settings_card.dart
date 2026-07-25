/// Card e sheet delle impostazioni GPS per l'auto-timbratura: raggio del
/// geofence, coordinate della sede e cattura della posizione corrente.
///
/// Estratto da `profile_screen.dart` (2026-07-25). Vedi ADR-0004 per la scelta
/// di `geolocator` in foreground.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/geofencing_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../data/profile_repository.dart';
import 'settings_sheet.dart';

class GpsSettingsCard extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic> profileData;
  final WidgetRef ref;
  final Color textSub;

  const GpsSettingsCard({
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

    return EditSheet(
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

          SaveButton(
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
