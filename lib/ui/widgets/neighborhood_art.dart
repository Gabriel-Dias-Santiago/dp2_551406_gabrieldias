import 'package:material_ui/material_ui.dart';

/// Ilustração vetorial local: não precisa de imagens ou fontes da internet.
class NeighborhoodArt extends StatelessWidget {
  const NeighborhoodArt({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(double.infinity, 105),
      painter: _NeighborhoodPainter(),
    ),
  );
}

class _NeighborhoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 105);
    final paint = Paint();
    void rect(double x, double y, double w, double h, Color color) {
      paint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    const light = Color(0xFFCEDEC3);
    const mid = Color(0xFF91B99B);
    paint.color = const Color(0xFFDBB878);
    canvas.drawCircle(const Offset(267, 24), 18, paint);
    rect(24, 41, 46, 58, mid);
    rect(84, 21, 52, 78, light);
    rect(148, 48, 42, 51, const Color(0xFFABCDB0));
    rect(204, 34, 40, 65, mid);
    for (final x in [34.0, 52.0, 94.0, 116.0, 158.0, 174.0, 214.0, 230.0]) {
      for (final y in [55.0, 73.0]) {
        rect(x, y, 6, 8, const Color(0xFF326B55));
      }
    }
    rect(94, 32, 8, 10, const Color(0xFF326B55));
    rect(116, 32, 8, 10, const Color(0xFF326B55));
    for (final x in [8.0, 283.0, 308.0]) {
      rect(x - 2, 67, 4, 32, light);
      paint.color = mid;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 59), width: 24, height: 36),
        paint,
      );
    }
    rect(0, 99, 320, 3, light);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
