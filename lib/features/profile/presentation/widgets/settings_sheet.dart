/// Chrome condivisa dei bottom sheet di modifica del profilo: contenitore
/// vetro con titolo ([EditSheet]) e bottone di salvataggio con stato di
/// caricamento ([SaveButton]).
///
/// Estratto da `profile_screen.dart` (2026-07-25): serve sia allo screen sia
/// ai moduli estratti (preferenze notifiche), quindi non può restare privato
/// in un file solo.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../../../core/constants/app_strings.dart';

class EditSheet extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const EditSheet({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10102A).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SaveButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final bool enabled;

  const SaveButton({required this.onPressed, this.enabled = true});

  @override
  State<SaveButton> createState() => SaveButtonState();
}

class SaveButtonState extends State<SaveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _loading || !widget.enabled
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onPressed();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                AppStrings.save,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
