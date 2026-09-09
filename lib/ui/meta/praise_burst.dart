import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating praise burst shown after matches (Nice / Great / Awesome…).
class PraiseBurst extends StatelessWidget {
  final String label;

  const PraiseBurst({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 42.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFE082),
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
              Shadow(color: Color(0xAAFF9800), blurRadius: 18),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 120.ms)
            .scale(
              begin: const Offset(0.55, 0.55),
              end: const Offset(1.12, 1.12),
              duration: 380.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .moveY(begin: 0, end: -36.h, duration: 500.ms, curve: Curves.easeOut)
            .fadeOut(duration: 420.ms),
      ),
    );
  }
}

/// Constrains dialogs/popups to a comfortable phone viewport.
class MetaPopupScope extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? margin;

  const MetaPopupScope({
    super.key,
    required this.child,
    this.maxWidth = 360,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedMargin =
        margin ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h);
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.w.clamp(0, w - resolvedMargin.horizontal),
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Padding(padding: resolvedMargin, child: child),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (ctx) => MetaPopupScope(child: builder(ctx)),
    );
  }
}
