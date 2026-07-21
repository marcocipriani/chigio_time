import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/pcm_catalog.dart';
import '../../core/data/pcm_locations_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import 'pcm_assignment_form.dart';

bool needsPcmAssignment(Map<String, dynamic>? profile, PcmCatalog catalog) {
  if (profile == null || profile['administration'] != AppStrings.appOrg) {
    return false;
  }
  final structureName = (profile['dipartimento'] as String? ?? '').trim();
  final siteId = (profile['sedeId'] as String? ?? '').trim();
  final siteName = (profile['sede'] as String? ?? '').trim();
  final siteAddress = (profile['sedeAddress'] as String? ?? '').trim();
  final validStructure = catalog.structures.any(
    (entry) => entry.structureName == structureName,
  );
  final validSite = catalog.structures.any((entry) => entry.siteId == siteId);
  final hasSiteMetadata =
      siteName.isNotEmpty &&
      siteAddress.isNotEmpty &&
      profile['sedeLat'] is num &&
      profile['sedeLng'] is num;
  return !validStructure || !validSite || !hasSiteMetadata;
}

class PcmAssignmentGate extends ConsumerWidget {
  final Widget child;

  const PcmAssignmentGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileStreamProvider).asData?.value;
    if (profile == null || profile['administration'] != AppStrings.appOrg) {
      return child;
    }

    final catalogAsync = ref.watch(pcmCatalogProvider);
    return catalogAsync.when(
      loading: () => child,
      error: (error, stackTrace) => _BlockedOverlay(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.pcmCatalogUnavailable),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(pcmCatalogLoadProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
        child: child,
      ),
      data: (catalog) {
        if (!needsPcmAssignment(profile, catalog)) return child;
        return _BlockedOverlay(
          content: _PcmAssignmentGateContent(
            catalog: catalog,
            profile: profile,
            onSave: (structureName, site) => ref
                .read(profileRepositoryProvider)
                .updatePcmAssignment(structureName: structureName, site: site),
          ),
          child: child,
        );
      },
    );
  }
}

class _BlockedOverlay extends StatelessWidget {
  final Widget child;
  final Widget content;

  const _BlockedOverlay({required this.child, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(child: child),
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withValues(alpha: 0.52),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: isDark ? const Color(0xFF10102A) : Colors.white,
                elevation: 16,
                borderRadius: BorderRadius.circular(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PcmAssignmentGateContent extends StatefulWidget {
  final PcmCatalog catalog;
  final Map<String, dynamic> profile;
  final Future<void> Function(String structureName, PcmSiteOption site) onSave;

  const _PcmAssignmentGateContent({
    required this.catalog,
    required this.profile,
    required this.onSave,
  });

  @override
  State<_PcmAssignmentGateContent> createState() =>
      _PcmAssignmentGateContentState();
}

class _PcmAssignmentGateContentState extends State<_PcmAssignmentGateContent> {
  late String _structureName;
  late String _siteId;
  PcmSiteOption? _site;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _structureName = widget.profile['dipartimento'] as String? ?? '';
    _siteId = widget.profile['sedeId'] as String? ?? '';
    final sites = pcmSitesFromStructures(widget.catalog.structures);
    for (final site in sites) {
      if (site.id == _siteId) _site = site;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.apartment_rounded, color: AppColors.blue600, size: 34),
        const SizedBox(height: 12),
        const Text(
          AppStrings.pcmAssignmentRequiredTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          AppStrings.pcmAssignmentRequiredBody,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        PcmAssignmentForm(
          structures: widget.catalog.structures,
          structureName: _structureName,
          siteId: _siteId,
          onStructureSelected: (value) {
            setState(() {
              if (_structureName != value) {
                _siteId = '';
                _site = null;
              }
              _structureName = value;
              _error = null;
            });
          },
          onSiteSelected: (site) {
            setState(() {
              _siteId = site.id;
              _site = site;
              _error = null;
            });
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.red700, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving || _structureName.isEmpty || _site == null
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(AppStrings.saveAndContinue),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_structureName, _site!);
    } catch (error) {
      if (mounted) setState(() => _error = AppStrings.errorSave(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
