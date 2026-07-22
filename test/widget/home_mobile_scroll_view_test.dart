import 'package:chigio_time/features/dashboard/presentation/home_mobile_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setPhone(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }

  testWidgets('does not build a secondary widget far outside the viewport', (
    tester,
  ) async {
    await setPhone(tester);
    final built = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeMobileScrollView(
            leadingChildren: const [SizedBox(height: 300)],
            widgetCount: 20,
            widgetBuilder: (_, index) {
              built.add(index);
              return SizedBox(height: 260, child: Text('widget-$index'));
            },
          ),
        ),
      ),
    );

    expect(built, isNot(contains(19)));
    expect(find.text('widget-19'), findsNothing);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('dashboard-home-scroll')),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
    expect(built.length, greaterThan(3));
  });

  testWidgets('restores scroll offset after the Home scrollable is remounted', (
    tester,
  ) async {
    await setPhone(tester);
    final bucket = PageStorageBucket();

    Widget home() => MaterialApp(
      home: PageStorage(
        bucket: bucket,
        child: Scaffold(
          body: HomeMobileScrollView(
            leadingChildren: const [SizedBox(height: 300)],
            widgetCount: 12,
            widgetBuilder: (_, index) =>
                SizedBox(height: 240, child: Text('widget-$index')),
          ),
        ),
      ),
    );

    await tester.pumpWidget(home());
    await tester.drag(
      find.byKey(const PageStorageKey<String>('dashboard-home-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(before, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(home());
    await tester.pump();
    final after = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(after, closeTo(before, 1));
  });
}
