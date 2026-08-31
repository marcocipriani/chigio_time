import 'package:flutter/material.dart';

/// Micro-Chigio decorativo per gli header dei widget Home: un tocco di
/// mascotte in ogni card (posa diversa per widget).
class ChigioMini extends StatelessWidget {
  final String pose;
  final double size;

  const ChigioMini(this.pose, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    // cacheWidth: la posa e' 640 px sorgente ma qui vive a 22-30 px. Senza il
    // resize in decodifica ogni mini terrebbe 1,6 MB di bitmap in cache.
    // Solo la larghezza: passando anche cacheHeight, ResizeImage applica la
    // policy "exact" e le pose non quadrate (chigio.webp e' 584x640) verrebbero
    // decodificate schiacciate, con BoxFit.contain ormai impotente.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      pose,
      height: size,
      width: size,
      cacheWidth: pixels,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Text('🐢', style: TextStyle(fontSize: size * 0.8)),
    );
  }
}
