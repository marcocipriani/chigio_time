import 'package:chigio_time/features/dashboard/widgets/home_loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('matches the first Home viewport with one shared pulse', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeLoadingSkeleton())),
    );

    expect(find.byKey(const Key('home-skeleton-hero')), findsOneWidget);
    expect(find.byKey(const Key('home-skeleton-intro')), findsOneWidget);
    expect(find.byKey(const Key('home-skeleton-card')), findsNWidgets(2));
    final pulse = find.descendant(
      of: find.byType(HomeLoadingSkeleton),
      matching: find.byType(FadeTransition),
    );
    expect(pulse, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reduced motion keeps the skeleton static', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: HomeLoadingSkeleton()),
        ),
      ),
    );
    final pulse = find.descendant(
      of: find.byType(HomeLoadingSkeleton),
      matching: find.byType(FadeTransition),
    );
    final fade = tester.widget<FadeTransition>(pulse);
    final before = fade.opacity.value;
    await tester.pump(const Duration(seconds: 2));
    expect(fade.opacity.value, before);
  });
}
