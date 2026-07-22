import 'dart:io';

import 'package:chigio_time/core/constants/app_constants.dart';
import 'package:chigio_time/features/dashboard/presentation/home_widget_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zero additional widgets selects the large CTA only', () {
    final result = resolveHomeWidgetVisibility(
      savedOrder: const [],
      hiddenWidgets: AppConstants.homeWidgetIds.toSet(),
    );
    expect(result.visibleIds, isEmpty);
    expect(result.showLargeAddCard, isTrue);
    expect(result.showCompactEditLink, isFalse);
  });

  test('one additional widget selects the compact link', () {
    final hidden = AppConstants.homeWidgetIds.toSet()..remove('favorites');
    final result = resolveHomeWidgetVisibility(
      savedOrder: const ['favorites'],
      hiddenWidgets: hidden,
    );
    expect(result.visibleIds, ['favorites']);
    expect(result.showLargeAddCard, isFalse);
    expect(result.showCompactEditLink, isTrue);
  });

  test('many widgets preserve saved order and use the compact link', () {
    final hidden = AppConstants.homeWidgetIds.toSet()
      ..removeAll(['salary', 'pomodoro']);
    final result = resolveHomeWidgetVisibility(
      savedOrder: const ['salary', 'pomodoro'],
      hiddenWidgets: hidden,
    );
    expect(result.visibleIds.take(2), ['salary', 'pomodoro']);
    expect(result.showLargeAddCard, isFalse);
    expect(result.showCompactEditLink, isTrue);
  });

  test('onboarding continues to hide every optional Home widget', () {
    final source = File(
      'lib/features/profile/data/profile_repository.dart',
    ).readAsStringSync();
    expect(source, contains("'hiddenHomeWidgets': AppConstants.homeWidgetIds"));
  });
}
