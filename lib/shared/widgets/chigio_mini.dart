import 'package:flutter/material.dart';

/// Micro-Chigio decorativo per gli header dei widget Home: un tocco di
/// mascotte in ogni card (posa diversa per widget).
class ChigioMini extends StatelessWidget {
  final String pose;
  final double size;

  const ChigioMini(this.pose, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      pose,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Text('🐢', style: TextStyle(fontSize: size * 0.8)),
    );
  }
}
