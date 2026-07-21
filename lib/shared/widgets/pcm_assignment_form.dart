import 'package:flutter/material.dart';

import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/pcm_catalog.dart';

class PcmAssignmentForm extends StatelessWidget {
  final List<PcmStructureSite> structures;
  final String structureName;
  final String siteId;
  final ValueChanged<String> onStructureSelected;
  final ValueChanged<PcmSiteOption> onSiteSelected;

  const PcmAssignmentForm({
    super.key,
    required this.structures,
    required this.structureName,
    required this.siteId,
    required this.onStructureSelected,
    required this.onSiteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
    final names = structures.map((entry) => entry.structureName).toList();
    final sites = sortedSitesForStructure(structureName, structures);
    final selectedSiteId = sites.any((site) => site.id == siteId)
        ? siteId
        : null;

    InputDecoration decoration(String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: textSub),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<String>(
          key: ValueKey('pcm-structure-$structureName'),
          initialValue: TextEditingValue(text: structureName),
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return names;
            return names.where((name) => name.toLowerCase().contains(query));
          },
          onSelected: onStructureSelected,
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF10102A) : Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 280,
                  maxWidth: 560,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          option,
                          style: TextStyle(fontSize: 13, color: textMain),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              key: const Key('pcm-structure-field'),
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(fontSize: 14, color: textMain),
              decoration: decoration(
                AppStrings.dipartimento,
                AppStrings.selectDepartment,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          key: const Key('pcm-site-dropdown'),
          initialValue: selectedSiteId,
          isExpanded: true,
          menuMaxHeight: 420,
          itemHeight: 72,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSub),
          dropdownColor: isDark ? const Color(0xFF10102A) : Colors.white,
          decoration: decoration(AppStrings.sede, AppStrings.selectSite),
          selectedItemBuilder: (context) => sites
              .map(
                (site) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    site.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: textMain),
                  ),
                ),
              )
              .toList(growable: false),
          items: sites
              .map(
                (site) => DropdownMenuItem<String>(
                  value: site.id,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (site.isRecommended)
                        const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.blue600,
                            ),
                            SizedBox(width: 3),
                            Text(
                              AppStrings.suggestedSedeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blue600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        site.displayLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            onSiteSelected(sites.firstWhere((site) => site.id == value));
          },
        ),
      ],
    );
  }
}
