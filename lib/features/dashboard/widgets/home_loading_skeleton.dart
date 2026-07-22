import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton_tile.dart';

class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: SkeletonPulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SkeletonTile(
                key: Key('home-skeleton-hero'),
                height: 300,
                radius: 32,
              ),
              SizedBox(height: 11),
              SkeletonTile(
                key: Key('home-skeleton-intro'),
                height: 84,
                radius: 22,
              ),
              SizedBox(height: 11),
              SizedBox(
                child: SkeletonTile(
                  key: Key('home-skeleton-card'),
                  height: 156,
                  radius: 28,
                ),
              ),
              SizedBox(height: 11),
              SizedBox(
                child: SkeletonTile(
                  key: Key('home-skeleton-card'),
                  height: 124,
                  radius: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
