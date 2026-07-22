import 'package:flutter/material.dart';

class HomeMobileScrollView extends StatelessWidget {
  final List<Widget> leadingChildren;
  final int widgetCount;
  final IndexedWidgetBuilder widgetBuilder;
  final Widget? footer;

  const HomeMobileScrollView({
    super.key,
    required this.leadingChildren,
    required this.widgetCount,
    required this.widgetBuilder,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('dashboard-home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList.list(
            children: [
              for (final child in leadingChildren)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: child,
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: widgetCount,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: widgetBuilder(context, index),
            ),
          ),
        ),
        if (footer != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(child: footer),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}
