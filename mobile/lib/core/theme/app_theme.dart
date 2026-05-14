// Shared app styling.
// Keeping colors and reusable widgets here makes every screen look consistent.
import 'package:flutter/material.dart';

// AppTheme stores colors, Material theme setup, buttons, and avatars.
class AppTheme {
  // Private constructor prevents creating AppTheme objects.
  AppTheme._();

  // Core brand colors used throughout the Flutter UI.
  static const Color primary = Color(0xFF111827);
  static const Color primaryDark = Color(0xFF030712);
  static const Color secondary = Color(0xFFFFD84D);
  static const Color accent = Color(0xFF22D3EE);

  // Main gradient used on splash screens, auth headers, and primary buttons.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF334155)],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF7CC), Color(0xFFE0F7FA)],
  );

  // Background and surface colors used by screens, cards, and inputs.
  static const Color background = Color(0xFFF7F7F2);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text colors for strong text, secondary text, and hints.
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Status colors used for success, error, warning, and info messages.
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Avatar colors. Each email maps to one color so users stay recognizable.
  static const List<Color> avatarColors = [
    Color(0xFFFFD84D),
    Color(0xFF22D3EE),
    Color(0xFFFF7A7A),
    Color(0xFF8B5CF6),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
  ];

  // Pick a stable avatar color by adding the email character codes.
  static Color avatarColorForEmail(String email) {
    final index =
        email.codeUnits.fold(0, (sum, c) => sum + c) % avatarColors.length;
    return avatarColors[index];
  }

  // Main Material theme used by the whole app.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Reusable full-width gradient button used by login/register/location screens.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // When isLoading is true, replace the label with a spinner.
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null || isLoading
              ? const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF94A3B8)],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable cartoon-style avatar.
// It uses email as the seed, so the same user gets the same color/initial.
class UserAvatar extends StatelessWidget {
  final String email;
  final double radius;
  final Color? color;

  const UserAvatar({
    super.key,
    required this.email,
    this.radius = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Use a passed color, or generate a stable color from the email.
    final bg = color ?? AppTheme.avatarColorForEmail(email);
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CustomPaint(
        painter: _AvatarPainter(color: bg, seed: email),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final Color color;
  final String seed;

  _AvatarPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()..isAntiAlias = true;

    paint.color = color.withValues(alpha: 0.22);
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.36),
      radius * 0.58,
      paint,
    );

    paint.color = const Color(0xFFFFD7B5);
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.05),
      radius * 0.54,
      paint,
    );

    paint.color = AppTheme.textPrimary;
    final hair = Path()
      ..moveTo(center.dx - radius * 0.55, center.dy - radius * 0.1)
      ..quadraticBezierTo(
        center.dx - radius * 0.2,
        center.dy - radius * 0.82,
        center.dx + radius * 0.55,
        center.dy - radius * 0.25,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.25,
        center.dy - radius * 0.55,
        center.dx - radius * 0.55,
        center.dy - radius * 0.1,
      )
      ..close();
    canvas.drawPath(hair, paint);

    paint.color = AppTheme.textPrimary;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.18, center.dy),
      radius * 0.045,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.18, center.dy),
      radius * 0.045,
      paint,
    );

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.12),
        width: radius * 0.38,
        height: radius * 0.26,
      ),
      0.15,
      2.85,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;

    final initial = seed.isNotEmpty ? seed[0].toUpperCase() : '?';
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.48,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + radius * 0.28 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return color != oldDelegate.color || seed != oldDelegate.seed;
  }
}
