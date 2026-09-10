import 'package:flutter/material.dart';

/// Clips two opposite corners at 45°, the angled-panel look used
/// throughout Valorant's UI (agent select, shop, scoreboard...).
class DiagonalCutClipper extends CustomClipper<Path> {
  const DiagonalCutClipper({this.cut = 14});

  final double cut;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant DiagonalCutClipper oldClipper) => oldClipper.cut != cut;
}
