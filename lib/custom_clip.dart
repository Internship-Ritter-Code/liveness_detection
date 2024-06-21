import 'package:flutter/material.dart';

class SquareWithCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double centerX = size.width / 2;
    double centerY = size.height / 3;
    double radius = size.width / 3;

    path.addOval(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
