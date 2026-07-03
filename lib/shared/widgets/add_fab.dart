import 'package:flutter/material.dart';

import '../../app/theme/color_schemes.dart';
import 'app_tappable.dart';

/// FAB "aggiungi" condiviso — stesso layout su tutte le schermate
/// (Stipendio, Progetti, Social, Cartellino). Stile canone: 58×58,
/// angoli 19, gradiente blu→verde.
class AddFab extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticLabel;
  final IconData icon;

  const AddFab({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue600, AppColors.green600],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
