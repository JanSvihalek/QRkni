import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoScanBrackets extends StatelessWidget {
  final double size;
  final Color color;

  const LogoScanBrackets({
    super.key,
    this.size = 96,
    this.color = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScanBracketsPainter(color)),
    );
  }
}

class _ScanBracketsPainter extends CustomPainter {
  final Color color;
  _ScanBracketsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.085;
    final corner = s * 0.32;
    final r = s * 0.14;
    final c = s * 0.5;
    final m = s * 0.085;
    final gap = m * 1.35;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Top-left bracket
    final tl = Path()
      ..moveTo(stroke / 2, r + corner)
      ..lineTo(stroke / 2, r + stroke / 2)
      ..arcToPoint(
        Offset(r + stroke / 2, stroke / 2),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(corner + stroke / 2, stroke / 2);

    // Top-right bracket
    final tr = Path()
      ..moveTo(s - corner - stroke / 2, stroke / 2)
      ..lineTo(s - r - stroke / 2, stroke / 2)
      ..arcToPoint(
        Offset(s - stroke / 2, r + stroke / 2),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(s - stroke / 2, corner + stroke / 2);

    // Bottom-left bracket
    final bl = Path()
      ..moveTo(stroke / 2, s - corner - stroke / 2)
      ..lineTo(stroke / 2, s - r - stroke / 2)
      ..arcToPoint(
        Offset(r + stroke / 2, s - stroke / 2),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(corner + stroke / 2, s - stroke / 2);

    // Bottom-right bracket
    final br = Path()
      ..moveTo(s - corner - stroke / 2, s - stroke / 2)
      ..lineTo(s - r - stroke / 2, s - stroke / 2)
      ..arcToPoint(
        Offset(s - stroke / 2, s - r - stroke / 2),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(s - stroke / 2, s - corner - stroke / 2);

    canvas.drawPath(tl, strokePaint);
    canvas.drawPath(tr, strokePaint);
    canvas.drawPath(bl, strokePaint);
    canvas.drawPath(br, strokePaint);

    // Central 3×3 cluster (8 modules, no center)
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const positions = <List<int>>[
      [-1, -1], [0, -1], [1, -1],
      [-1, 0], [1, 0],
      [-1, 1], [0, 1], [1, 1],
    ];
    for (final p in positions) {
      final dx = p[0].toDouble();
      final dy = p[1].toDouble();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(c + dx * gap - m / 2, c + dy * gap - m / 2, m, m),
        Radius.circular(m * 0.22),
      );
      canvas.drawRRect(rect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanBracketsPainter old) => old.color != color;
}

/// App icon — primary color rounded square with white logo inside.
class LogoAppIcon extends StatelessWidget {
  final double size;
  const LogoAppIcon({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: LogoScanBrackets(
          size: size * 0.62,
          color: Colors.white,
        ),
      ),
    );
  }
}
