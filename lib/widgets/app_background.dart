import 'package:flutter/material.dart';

import '../app/assets.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          SooktaAssets.background,
          fit: BoxFit.cover,
        ),
        child,
      ],
    );
  }
}
