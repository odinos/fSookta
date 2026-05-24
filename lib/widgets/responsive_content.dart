import 'package:flutter/material.dart';

class ClampedTextScale extends StatelessWidget {
  const ClampedTextScale({
    required this.child,
    this.minScale = 1,
    this.maxScale = 1.12,
    super.key,
  });

  final Widget child;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return child;

    final scale =
        media.textScaler.scale(1).clamp(minScale, maxScale).toDouble();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}

class FixedTextScale extends StatelessWidget {
  const FixedTextScale({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return child;

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: child,
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.maxWidth = 760,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extraHorizontal =
            ((constraints.maxWidth - maxWidth - padding.horizontal) / 2)
                .clamp(0.0, double.infinity);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            padding.left + extraHorizontal,
            padding.top,
            padding.right + extraHorizontal,
            padding.bottom,
          ),
          children: children,
        );
      },
    );
  }
}
