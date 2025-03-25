import 'package:flutter/material.dart';

class UniversalRulerPainter extends CustomPainter {
  final bool isHorizontal;

  UniversalRulerPainter({required this.isHorizontal});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
      
    double step = 10;
    double longMarkInterval = 50;
    double shortMarkHeight = 10;
    double longMarkHeight = 20;

    if (isHorizontal) {
      for (double i = 0; i <= size.width; i += step) {
        double lineHeight =
            (i % longMarkInterval == 0) ? longMarkHeight : shortMarkHeight;
        canvas.drawLine(
          Offset(i, size.height - lineHeight),
          Offset(i, size.height),
          paint,
        );
      }
    } else {
      for (double i = 0; i <= size.height; i += step) {
        double lineWidth =
            (i % longMarkInterval == 0) ? longMarkHeight : shortMarkHeight;
        canvas.drawLine(
          Offset(size.width - lineWidth, i),
          Offset(size.width, i),
          paint,
        );
      }
    }
  }


  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

