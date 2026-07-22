import '../../../core/constants/app_constants.dart';

class HomeWidgetVisibility {
  final List<String> orderedIds;
  final List<String> visibleIds;

  const HomeWidgetVisibility({
    required this.orderedIds,
    required this.visibleIds,
  });

  bool get showLargeAddCard => visibleIds.isEmpty;
  bool get showCompactEditLink => visibleIds.isNotEmpty;
}

HomeWidgetVisibility resolveHomeWidgetVisibility({
  required List<String> savedOrder,
  required Set<String> hiddenWidgets,
}) {
  final ordered = [
    ...savedOrder.where(AppConstants.homeWidgetIds.contains),
    ...AppConstants.homeWidgetIds.where((id) => !savedOrder.contains(id)),
  ];
  return HomeWidgetVisibility(
    orderedIds: List.unmodifiable(ordered),
    visibleIds: List.unmodifiable(
      ordered.where((id) => !hiddenWidgets.contains(id)),
    ),
  );
}
