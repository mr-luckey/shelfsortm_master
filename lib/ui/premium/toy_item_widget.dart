import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/item.dart';
import '../widgets/emoji_assets.dart';
import 'toy_item_type.dart';

/// Premium toy product — transparent PNG with soft contact shadow.
class ToyItemWidget extends StatefulWidget {
  final ToyType type;
  final double size;
  final bool lifting;
  final bool dimmed;
  final bool animateIn;
  final bool floating;
  final int popDelayMs;
  final VoidCallback? onTap;

  /// When set, renders Fluent emoji art for this game type instead of a toy PNG.
  final String? emojiType;

  const ToyItemWidget({
    super.key,
    required this.type,
    this.size = 28,
    this.lifting = false,
    this.dimmed = false,
    this.animateIn = false,
    this.floating = false,
    this.popDelayMs = 0,
    this.onTap,
    this.emojiType,
  });

  factory ToyItemWidget.fromType({
    Key? key,
    required ToyType type,
    double size = 28,
    bool lifting = false,
    bool dimmed = false,
    bool animateIn = false,
    bool floating = false,
    int popDelayMs = 0,
    VoidCallback? onTap,
  }) =>
      ToyItemWidget(
        key: key,
        type: type,
        size: size,
        lifting: lifting,
        dimmed: dimmed,
        animateIn: animateIn,
        floating: floating,
        popDelayMs: popDelayMs,
        onTap: onTap,
      );

  factory ToyItemWidget.fromItem({
    Key? key,
    required GameItem item,
    double size = 28,
    bool lifting = false,
    bool dimmed = false,
    VoidCallback? onTap,
  }) =>
      ToyItemWidget(
        key: key,
        type: ToyType.values.first,
        emojiType: item.type,
        size: size,
        lifting: lifting,
        dimmed: dimmed || !item.isInteractable,
        onTap: onTap,
      );

  @override
  State<ToyItemWidget> createState() => _ToyItemWidgetState();
}

class _ToyItemWidgetState extends State<ToyItemWidget> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final asset = widget.emojiType != null
        ? EmojiAssets.pathFor(widget.emojiType!)
        : widget.type.assetPath;

    Widget body = GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: widget.lifting ? 1.1 : _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 0,
                left: s * 0.12,
                right: s * 0.12,
                child: Container(
                  height: s * 0.08,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: s * 0.1,
                        spreadRadius: 0.2,
                        offset: Offset(0, s * 0.02),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: s * 0.02,
                right: s * 0.02,
                bottom: s * 0.01,
                top: s * 0.02,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, error, stack) => Text(
                    widget.type.emoji,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s * 0.82,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.dimmed) {
      body = Opacity(opacity: 0.35, child: body);
    }

    if (widget.floating) {
      body = body
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -2.5, duration: 1400.ms, curve: Curves.easeInOut);
    }

    if (widget.animateIn) {
      body = body
          .animate(delay: Duration(milliseconds: widget.popDelayMs))
          .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: 200.ms,
            curve: Curves.elasticOut,
          );
    }

    return body;
  }
}
